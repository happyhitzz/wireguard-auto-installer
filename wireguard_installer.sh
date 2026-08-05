#!/bin/bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║          WireGuard Automated Installer & Manager v3.0                    ║
# ║          Production-Grade • Dual-Stack • Multi-Interface                 ║
# ║          https://github.com/happyhitzz/wireguard-auto-installer          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Features:
#   • Full IPv4 + IPv6 dual-stack support
#   • Pre-shared keys (PSK) for post-quantum resistance
#   • Multi-interface support (wg0, wg1, ...)
#   • Collision-free IP allocation with bitmap tracking
#   • Config file locking (flock) for concurrent safety
#   • Comprehensive OS detection (Debian/Ubuntu/Fedora/CentOS/Alma/Rocky/Arch/Alpine/Oracle)
#   • Virtualization detection (blocks OpenVZ/LXC)
#   • Firewall integration (ufw / firewalld / raw iptables)
#   • Non-interactive mode (--auto) for scripted deployments
#   • Client enable/disable without deletion
#   • Client config regeneration (re-key)
#   • Detailed connection status with human-readable output
#   • Automatic backup before destructive operations
#   • Self-update from GitHub
#   • Full uninstall with cleanup
#   • Signal trapping and atomic config writes
#   • Structured logging to /var/log/wireguard-installer.log
#   • wg syncconf for zero-downtime peer changes
#   • MTU detection and optimization
#   • Bandwidth usage tracking per client
#   • Config export (tarball of all client configs)
#   • Strict shellcheck compliance
#
# Usage:
#   sudo ./wireguard_installer.sh [OPTIONS]
#   sudo ./wireguard_installer.sh --auto --port 51820 --client myphone --dns 1.1.1.1
#
# License: MIT
# Author: KyroVPN (happyhitzz)

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONSTANTS & DEFAULTS
# =============================================================================

readonly SCRIPT_VERSION="3.0"
readonly SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh"
readonly LOG_FILE="/var/log/wireguard-installer.log"
readonly LOCK_FILE="/var/lock/wireguard-installer.lock"
readonly PARAMS_FILE="/etc/wireguard/params"
readonly CLIENT_DIR="/etc/wireguard/clients"
readonly BACKUP_DIR="/etc/wireguard/backups"

# Default server settings
DEFAULT_WG_NIC="wg0"
DEFAULT_WG_PORT="51820"
DEFAULT_WG_IPV4="10.66.66.1"
DEFAULT_WG_IPV6="fd42:42:42::1"
DEFAULT_DNS_1="1.1.1.1"
DEFAULT_DNS_2="1.0.0.1"
DEFAULT_ALLOWED_IPS="0.0.0.0/0,::/0"
# shellcheck disable=SC2034
DEFAULT_MTU=""
DEFAULT_KEEPALIVE="25"

# DNS presets
# shellcheck disable=SC2034
declare -A DNS_PRESETS=(
    ["cloudflare"]="1.1.1.1,1.0.0.1"
    ["google"]="8.8.8.8,8.8.4.4"
    ["quad9"]="9.9.9.9,149.112.112.112"
    ["adguard"]="94.140.14.14,94.140.15.15"
    ["adguard-family"]="94.140.14.15,94.140.15.16"
    ["opendns"]="208.67.222.222,208.67.220.220"
    ["nextdns"]="45.90.28.167,45.90.30.167"
)

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
# shellcheck disable=SC2034
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Runtime state
AUTO_MODE=false
AUTO_PORT=""
AUTO_DNS=""
AUTO_CLIENT=""
AUTO_INTERFACE=""
LOCK_FD=""

# =============================================================================
# LOGGING
# =============================================================================

_log() {
    local level="$1"; shift
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf '[%s] [%-5s] %s\n' "$timestamp" "$level" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

log_info()  { _log "INFO"  "$@"; }
log_warn()  { _log "WARN"  "$@"; }
log_error() { _log "ERROR" "$@"; }
log_debug() { _log "DEBUG" "$@"; }

# =============================================================================
# OUTPUT HELPERS
# =============================================================================

msg()     { echo -e "$*"; }
info()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}${BLUE}═══ $* ═══${NC}\n"; }
step()    { echo -e "${CYAN}[→]${NC} $*"; }

die() {
    error "$@"
    log_error "$@"
    exit 1
}

# =============================================================================
# SIGNAL HANDLING & CLEANUP
# =============================================================================

declare -a CLEANUP_FILES=()
CLEANUP_NEEDED=false

cleanup() {
    local exit_code=$?
    if [[ "$CLEANUP_NEEDED" == true ]]; then
        log_warn "Script interrupted (exit code: $exit_code). Cleaning up..."
        warn "Interrupted. Cleaning up temporary files..."
    fi
    for f in "${CLEANUP_FILES[@]}"; do
        [[ -f "$f" ]] && rm -f "$f"
    done
    # Release file lock
    if [[ -n "${LOCK_FD:-}" ]] && [[ -e "$LOCK_FILE" ]]; then
        flock -u "$LOCK_FD" 2>/dev/null || true
    fi
    exit "$exit_code"
}

trap cleanup EXIT
trap 'CLEANUP_NEEDED=true; exit 130' INT
trap 'CLEANUP_NEEDED=true; exit 143' TERM
trap 'CLEANUP_NEEDED=true; exit 129' HUP

# =============================================================================
# LOCKING (flock-based)
# =============================================================================

acquire_lock() {
    mkdir -p "$(dirname "$LOCK_FILE")"
    exec {LOCK_FD}>"$LOCK_FILE"
    if ! flock -n "$LOCK_FD"; then
        die "Another instance is already running. If this is incorrect, remove $LOCK_FILE"
    fi
    log_debug "Lock acquired (PID $$)"
}

release_lock() {
    if [[ -n "${LOCK_FD:-}" ]]; then
        flock -u "$LOCK_FD" 2>/dev/null || true
        LOCK_FD=""
    fi
    log_debug "Lock released"
}

# =============================================================================
# VALIDATION HELPERS
# =============================================================================

is_valid_client_name() {
    local name="$1"
    [[ -n "$name" ]] && [[ ${#name} -le 15 ]] && [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]
}

is_valid_ipv4() {
    local ip="$1"
    if [[ "$ip" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
        local i
        for i in 1 2 3 4; do
            [[ ${BASH_REMATCH[$i]} -le 255 ]] || return 1
        done
        return 0
    fi
    return 1
}

is_valid_ipv6() {
    local ip="$1"
    # Basic IPv6 validation
    [[ "$ip" =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]] || \
    [[ "$ip" =~ ^([0-9a-fA-F]{0,4}:){1,6}:[0-9a-fA-F]{0,4}$ ]] || \
    [[ "$ip" =~ ^::([0-9a-fA-F]{0,4}:){0,5}[0-9a-fA-F]{0,4}$ ]]
}

is_valid_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535))
}

is_valid_interface_name() {
    local name="$1"
    [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] && [[ ${#name} -lt 16 ]]
}

# =============================================================================
# SYSTEM DETECTION
# =============================================================================

check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        die "This script must be run as root. Use: sudo $0"
    fi
}

check_virtualization() {
    local virt=""
    if command -v systemd-detect-virt &>/dev/null; then
        virt=$(systemd-detect-virt 2>/dev/null || echo "none")
    elif command -v virt-what &>/dev/null; then
        virt=$(virt-what 2>/dev/null | head -1 || echo "none")
    fi

    case "$virt" in
        openvz)
            die "OpenVZ virtualization is not supported. WireGuard requires kernel module access."
            ;;
        lxc)
            die "LXC containers are not supported without host kernel module. See: https://www.wireguard.com/install/"
            ;;
    esac
    log_info "Virtualization: ${virt:-none}"
}

detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        # Fallback detection
        if [[ -f /etc/debian_version ]]; then
            OS="debian"
            VERSION_ID=$(cut -d'.' -f1 < /etc/debian_version)
        elif [[ -f /etc/redhat-release ]]; then
            OS="centos"
            VERSION_ID=$(rpm -q --queryformat '%{VERSION}' centos-release 2>/dev/null | cut -d'.' -f1 || echo "8")
        else
            die "Cannot detect OS. /etc/os-release not found."
        fi
    else
        # shellcheck source=/dev/null
        source /etc/os-release
        OS="${ID}"
    fi

    # Normalize OS names
    case "$OS" in
        debian|raspbian) OS="debian" ;;
        ubuntu) OS="ubuntu" ;;
        fedora) OS="fedora" ;;
        centos|almalinux|rocky) OS="centos" ;;
        arch|manjaro) OS="arch" ;;
        alpine) OS="alpine" ;;
        ol|oracle) OS="oracle" ;;
        *)
            die "Unsupported OS: $OS. Supported: Debian, Ubuntu, Fedora, CentOS, AlmaLinux, Rocky, Arch, Alpine, Oracle Linux"
            ;;
    esac

    # Version checks
    case "$OS" in
        debian)
            if [[ "${VERSION_ID:-0}" -lt 10 ]]; then
                die "Debian ${VERSION_ID} is too old. Minimum required: Debian 10 (Buster)"
            fi
            ;;
        ubuntu)
            local year
            year=$(echo "${VERSION_ID:-0}" | cut -d'.' -f1)
            if [[ "$year" -lt 18 ]]; then
                die "Ubuntu ${VERSION_ID} is too old. Minimum required: Ubuntu 18.04"
            fi
            ;;
        fedora)
            if [[ "${VERSION_ID:-0}" -lt 32 ]]; then
                die "Fedora ${VERSION_ID} is too old. Minimum required: Fedora 32"
            fi
            ;;
        centos)
            if [[ "${VERSION_ID:-0}" == 7* ]]; then
                die "CentOS 7 is not supported. Minimum required: CentOS/Alma/Rocky 8"
            fi
            ;;
    esac

    info "Detected OS: ${BOLD}${OS}${NC} (${VERSION_ID:-unknown})"
    log_info "OS: ${OS} ${VERSION_ID:-unknown}"
}

detect_public_ip() {
    local ip=""
    local services=(
        "https://api.ipify.org"
        "https://ifconfig.me"
        "https://icanhazip.com"
        "https://ipinfo.io/ip"
        "https://checkip.amazonaws.com"
    )

    for svc in "${services[@]}"; do
        ip=$(curl -s --max-time 5 "$svc" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$ip" ]] && (is_valid_ipv4 "$ip" || is_valid_ipv6 "$ip"); then
            break
        fi
        ip=""
    done

    if [[ -z "$ip" ]]; then
        # Try to get from default route interface
        ip=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    fi

    if [[ -z "$ip" ]]; then
        die "Could not detect public IP address. Check internet connectivity."
    fi

    SERVER_PUB_IP="$ip"
    info "Public IP: ${BOLD}${SERVER_PUB_IP}${NC}"
    log_info "Public IP: ${SERVER_PUB_IP}"
}

detect_interface() {
    SERVER_PUB_NIC=$(ip -4 route ls | grep default | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -1)
    if [[ -z "$SERVER_PUB_NIC" ]]; then
        # Fallback: try IPv6
        SERVER_PUB_NIC=$(ip -6 route ls | grep default | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -1)
    fi
    if [[ -z "$SERVER_PUB_NIC" ]]; then
        die "Could not detect primary network interface. Check network configuration."
    fi
    info "Network interface: ${BOLD}${SERVER_PUB_NIC}${NC}"
    log_info "Network interface: ${SERVER_PUB_NIC}"
}

detect_mtu() {
    # Detect optimal MTU (WireGuard overhead is 60 bytes for IPv4, 80 for IPv6)
    local iface_mtu
    iface_mtu=$(ip link show "$SERVER_PUB_NIC" | awk '{for(i=1;i<=NF;i++) if($i=="mtu") print $(i+1)}')
    if [[ -n "$iface_mtu" ]] && [[ "$iface_mtu" =~ ^[0-9]+$ ]]; then
        # Subtract WireGuard overhead (80 bytes for IPv6 safety)
        DETECTED_MTU=$((iface_mtu - 80))
        log_info "Detected optimal MTU: ${DETECTED_MTU} (interface MTU: ${iface_mtu})"
    else
        DETECTED_MTU=1420
        log_warn "Could not detect interface MTU, using default: 1420"
    fi
}

# =============================================================================
# PACKAGE INSTALLATION
# =============================================================================

install_packages() {
    step "Installing WireGuard and dependencies..."
    log_info "Installing packages for OS: ${OS}"

    case "$OS" in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y -qq wireguard wireguard-tools qrencode curl iptables ip6tables 2>&1 | tail -5
            # Try to install resolvconf (not critical)
            apt-get install -y -qq resolvconf 2>/dev/null || true
            ;;
        fedora)
            dnf install -y wireguard-tools qrencode curl iptables ip6tables 2>&1 | tail -5
            ;;
        centos)
            yum install -y epel-release elrepo-release 2>/dev/null || true
            yum install -y wireguard-tools qrencode curl iptables ip6tables 2>&1 | tail -5
            ;;
        arch)
            pacman -Sy --needed --noconfirm wireguard-tools qrencode curl iptables 2>&1 | tail -5
            ;;
        alpine)
            apk update
            apk add wireguard-tools iptables ip6tables libqrencode-tools curl 2>&1 | tail -5
            ;;
        oracle)
            dnf install -y oraclelinux-developer-release-el8 2>/dev/null || true
            dnf install -y wireguard-tools qrencode curl iptables 2>&1 | tail -5
            ;;
    esac

    # Verify installation
    if ! command -v wg &>/dev/null; then
        die "WireGuard installation failed. The 'wg' command was not found."
    fi

    info "WireGuard installed successfully"
    log_info "WireGuard installation complete"
}

# =============================================================================
# FIREWALL MANAGEMENT
# =============================================================================

open_firewall() {
    local port="$1"
    local nic="$2"
    step "Configuring firewall rules..."

    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "active"; then
        ufw allow "${port}/udp" >/dev/null 2>&1
        ufw route allow in on "$nic" >/dev/null 2>&1 || true
        info "UFW: Port ${port}/udp opened"
        log_info "UFW: opened port ${port}/udp"
    elif pgrep -x firewalld &>/dev/null; then
        firewall-cmd --permanent --add-port="${port}/udp" >/dev/null 2>&1
        firewall-cmd --permanent --zone=public --add-interface="$nic" >/dev/null 2>&1 || true
        firewall-cmd --reload >/dev/null 2>&1
        info "Firewalld: Port ${port}/udp opened"
        log_info "Firewalld: opened port ${port}/udp"
    else
        log_info "No active firewall manager detected. Using iptables rules in PostUp/PostDown."
    fi
}

close_firewall() {
    local port="$1"
    step "Removing firewall rules..."

    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "active"; then
        ufw delete allow "${port}/udp" >/dev/null 2>&1 || true
    elif pgrep -x firewalld &>/dev/null; then
        firewall-cmd --permanent --remove-port="${port}/udp" >/dev/null 2>&1 || true
        firewall-cmd --reload >/dev/null 2>&1 || true
    fi
    log_info "Firewall: closed port ${port}/udp"
}

# =============================================================================
# BACKUP & RESTORE
# =============================================================================

create_backup() {
    local wg_nic="${1:-$DEFAULT_WG_NIC}"
    local config_file="/etc/wireguard/${wg_nic}.conf"
    if [[ ! -f "$config_file" ]]; then
        return 0
    fi
    mkdir -p "$BACKUP_DIR"
    local backup_name
    backup_name="${wg_nic}_$(date '+%Y%m%d_%H%M%S').conf"
    cp "$config_file" "${BACKUP_DIR}/${backup_name}"
    log_info "Backup created: ${BACKUP_DIR}/${backup_name}"
    # Keep only last 10 backups per interface
    find "$BACKUP_DIR" -name "${wg_nic}_*.conf" -printf '%T@ %p\n' 2>/dev/null | sort -rn | tail -n +11 | awk '{print $2}' | xargs -r rm -f
}

list_backups() {
    local wg_nic="${1:-$DEFAULT_WG_NIC}"
    header "Available Backups (${wg_nic})"
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -name "${wg_nic}_*.conf" -printf '%T@ %f %s\n' 2>/dev/null | sort -rn | awk '{printf "%d) %s (%s bytes)\n", NR, $2, $3}' || echo "  No backups found."
    else
        echo "  No backups found."
    fi
}

restore_backup() {
    local wg_nic="${1:-$DEFAULT_WG_NIC}"
    list_backups "$wg_nic"
    echo ""
    local backups
    mapfile -t backups < <(ls -t "${BACKUP_DIR}/${wg_nic}_"*.conf 2>/dev/null)
    if [[ ${#backups[@]} -eq 0 ]]; then
        warn "No backups available to restore."
        return 1
    fi

    local choice
    read -rp "Select backup number to restore (or 'q' to cancel): " choice
    if [[ "$choice" == "q" ]]; then
        return 0
    fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#backups[@]})); then
        error "Invalid selection."
        return 1
    fi

    local selected="${backups[$((choice - 1))]}"
    create_backup "$wg_nic" # Backup current before restoring
    cp "$selected" "/etc/wireguard/${wg_nic}.conf"
    systemctl restart "wg-quick@${wg_nic}" 2>/dev/null || true
    info "Restored backup: $(basename "$selected")"
    log_info "Restored backup: $selected"
}

# =============================================================================
# IP ALLOCATION (Collision-Free)
# =============================================================================

get_next_ipv4() {
    local wg_nic="$1"
    local base_ip="$2"  # e.g., "10.66.66"
    local config_file="/etc/wireguard/${wg_nic}.conf"

    # Build set of used IPs
    local -A used_ips=()
    used_ips[1]=1  # Server always uses .1

    if [[ -f "$config_file" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ AllowedIPs ]]; then
                local ip_str
                ip_str=$(echo "$line" | grep -oP "${base_ip//./\\.}\.\K[0-9]+" | head -1)
                if [[ -n "$ip_str" ]]; then
                    used_ips[$ip_str]=1
                fi
            fi
        done < "$config_file"
    fi

    # Find first available
    local i
    for ((i = 2; i <= 254; i++)); do
        if [[ -z "${used_ips[$i]:-}" ]]; then
            echo "$i"
            return 0
        fi
    done

    echo ""
    return 1
}

get_next_ipv6_suffix() {
    local wg_nic="$1"
    local base_ipv6="$2"  # e.g., "fd42:42:42::"
    local config_file="/etc/wireguard/${wg_nic}.conf"

    local -A used_suffixes=()
    used_suffixes[1]=1  # Server

    if [[ -f "$config_file" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ AllowedIPs ]] && [[ "$line" =~ ${base_ipv6} ]]; then
                local suffix
                suffix=$(echo "$line" | grep -oP "${base_ipv6//:/\\:}\K[0-9a-fA-F]+" | head -1)
                if [[ -n "$suffix" ]]; then
                    used_suffixes[$((16#$suffix))]=1
                fi
            fi
        done < "$config_file"
    fi

    local i
    for ((i = 2; i <= 254; i++)); do
        if [[ -z "${used_suffixes[$i]:-}" ]]; then
            echo "$i"
            return 0
        fi
    done

    echo ""
    return 1
}

# =============================================================================
# ATOMIC CONFIG WRITE
# =============================================================================

atomic_write() {
    local target="$1"
    local content="$2"
    local tmp_file="${target}.tmp.$$"
    CLEANUP_FILES+=("$tmp_file")
    echo "$content" > "$tmp_file"
    chmod 600 "$tmp_file"
    mv -f "$tmp_file" "$target"
}

# =============================================================================
# SERVER CONFIGURATION
# =============================================================================

setup_server() {
    header "WireGuard Server Setup"
    CLEANUP_NEEDED=true

    local wg_nic wg_port wg_ipv4 wg_ipv6 wg_dns_1 wg_dns_2 wg_mtu

    # --- Interface name ---
    if [[ "$AUTO_MODE" == true ]]; then
        wg_nic="${AUTO_INTERFACE:-$DEFAULT_WG_NIC}"
    else
        local suggested_nic="$DEFAULT_WG_NIC"
        read -rp "WireGuard interface name [${suggested_nic}]: " wg_nic
        wg_nic="${wg_nic:-$suggested_nic}"
    fi
    if ! is_valid_interface_name "$wg_nic"; then
        die "Invalid interface name: $wg_nic (must be alphanumeric, <16 chars)"
    fi

    # --- Port ---
    if [[ "$AUTO_MODE" == true ]]; then
        wg_port="${AUTO_PORT:-$DEFAULT_WG_PORT}"
    else
        local random_port
        random_port=$(shuf -i 49152-65535 -n1)
        read -rp "WireGuard port [${random_port}]: " wg_port
        wg_port="${wg_port:-$random_port}"
    fi
    if ! is_valid_port "$wg_port"; then
        die "Invalid port: $wg_port"
    fi

    # --- Server IPv4 ---
    if [[ "$AUTO_MODE" == true ]]; then
        wg_ipv4="$DEFAULT_WG_IPV4"
    else
        read -rp "Server WireGuard IPv4 [${DEFAULT_WG_IPV4}]: " wg_ipv4
        wg_ipv4="${wg_ipv4:-$DEFAULT_WG_IPV4}"
    fi

    # --- Server IPv6 ---
    if [[ "$AUTO_MODE" == true ]]; then
        wg_ipv6="$DEFAULT_WG_IPV6"
    else
        read -rp "Server WireGuard IPv6 [${DEFAULT_WG_IPV6}]: " wg_ipv6
        wg_ipv6="${wg_ipv6:-$DEFAULT_WG_IPV6}"
    fi

    # --- DNS ---
    if [[ "$AUTO_MODE" == true ]]; then
        wg_dns_1="${AUTO_DNS:-$DEFAULT_DNS_1}"
        wg_dns_2="$DEFAULT_DNS_2"
    else
        echo ""
        msg "${BOLD}DNS Presets:${NC}"
        msg "  1) Cloudflare    (1.1.1.1, 1.0.0.1)"
        msg "  2) Google        (8.8.8.8, 8.8.4.4)"
        msg "  3) Quad9         (9.9.9.9, 149.112.112.112)"
        msg "  4) AdGuard       (94.140.14.14, 94.140.15.15) ${DIM}[ad-blocking]${NC}"
        msg "  5) AdGuard Family(94.140.14.15, 94.140.15.16) ${DIM}[ad+adult blocking]${NC}"
        msg "  6) OpenDNS       (208.67.222.222, 208.67.220.220)"
        msg "  7) NextDNS       (45.90.28.167, 45.90.30.167)"
        msg "  8) Custom"
        echo ""
        local dns_choice
        read -rp "Choose DNS preset [1]: " dns_choice
        dns_choice="${dns_choice:-1}"
        case "$dns_choice" in
            1) wg_dns_1="1.1.1.1"; wg_dns_2="1.0.0.1" ;;
            2) wg_dns_1="8.8.8.8"; wg_dns_2="8.8.4.4" ;;
            3) wg_dns_1="9.9.9.9"; wg_dns_2="149.112.112.112" ;;
            4) wg_dns_1="94.140.14.14"; wg_dns_2="94.140.15.15" ;;
            5) wg_dns_1="94.140.14.15"; wg_dns_2="94.140.15.16" ;;
            6) wg_dns_1="208.67.222.222"; wg_dns_2="208.67.220.220" ;;
            7) wg_dns_1="45.90.28.167"; wg_dns_2="45.90.30.167" ;;
            8)
                read -rp "Primary DNS: " wg_dns_1
                read -rp "Secondary DNS (optional): " wg_dns_2
                wg_dns_2="${wg_dns_2:-$wg_dns_1}"
                ;;
            *) wg_dns_1="1.1.1.1"; wg_dns_2="1.0.0.1" ;;
        esac
    fi

    # --- MTU ---
    detect_mtu
    if [[ "$AUTO_MODE" != true ]]; then
        read -rp "MTU [${DETECTED_MTU}] (leave empty for auto): " wg_mtu
        wg_mtu="${wg_mtu:-$DETECTED_MTU}"
    else
        wg_mtu="$DETECTED_MTU"
    fi

    # --- Generate server keys ---
    step "Generating server keypair..."
    local server_privkey server_pubkey
    server_privkey=$(wg genkey)
    server_pubkey=$(echo "$server_privkey" | wg pubkey)

    # --- Create directories ---
    mkdir -p /etc/wireguard "$CLIENT_DIR" "$BACKUP_DIR"
    chmod 700 /etc/wireguard

    # --- Build PostUp/PostDown rules ---
    local post_up post_down
    if pgrep -x firewalld &>/dev/null; then
        local fw_ipv4_net
        fw_ipv4_net=$(echo "$wg_ipv4" | cut -d'.' -f1-3).0
        post_up="firewall-cmd --zone=public --add-interface=${wg_nic}; firewall-cmd --add-port ${wg_port}/udp; firewall-cmd --add-rich-rule='rule family=ipv4 source address=${fw_ipv4_net}/24 masquerade'; firewall-cmd --add-rich-rule='rule family=ipv6 masquerade'"
        post_down="firewall-cmd --zone=public --remove-interface=${wg_nic}; firewall-cmd --remove-port ${wg_port}/udp; firewall-cmd --remove-rich-rule='rule family=ipv4 source address=${fw_ipv4_net}/24 masquerade'; firewall-cmd --remove-rich-rule='rule family=ipv6 masquerade'"
    else
        post_up="iptables -I INPUT -p udp --dport ${wg_port} -j ACCEPT; iptables -I FORWARD -i ${SERVER_PUB_NIC} -o ${wg_nic} -j ACCEPT; iptables -I FORWARD -i ${wg_nic} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -I FORWARD -i ${wg_nic} -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE"
        post_down="iptables -D INPUT -p udp --dport ${wg_port} -j ACCEPT; iptables -D FORWARD -i ${SERVER_PUB_NIC} -o ${wg_nic} -j ACCEPT; iptables -D FORWARD -i ${wg_nic} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -D FORWARD -i ${wg_nic} -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE"
    fi

    # --- Write server config ---
    step "Writing server configuration..."
    local server_config="[Interface]
Address = ${wg_ipv4}/24,${wg_ipv6}/64
ListenPort = ${wg_port}
PrivateKey = ${server_privkey}
MTU = ${wg_mtu}
PostUp = ${post_up}
PostDown = ${post_down}"

    atomic_write "/etc/wireguard/${wg_nic}.conf" "$server_config"

    # --- Save params for future use ---
    atomic_write "$PARAMS_FILE" "SERVER_PUB_IP=${SERVER_PUB_IP}
SERVER_PUB_NIC=${SERVER_PUB_NIC}
SERVER_WG_NIC=${wg_nic}
SERVER_WG_IPV4=${wg_ipv4}
SERVER_WG_IPV6=${wg_ipv6}
SERVER_PORT=${wg_port}
SERVER_PRIV_KEY=${server_privkey}
SERVER_PUB_KEY=${server_pubkey}
CLIENT_DNS_1=${wg_dns_1}
CLIENT_DNS_2=${wg_dns_2}
CLIENT_MTU=${wg_mtu}
ALLOWED_IPS=${DEFAULT_ALLOWED_IPS}
KEEPALIVE=${DEFAULT_KEEPALIVE}"

    chmod 600 "$PARAMS_FILE"

    # --- Enable IP forwarding ---
    step "Enabling IP forwarding..."
    cat > /etc/sysctl.d/99-wireguard.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF
    sysctl --system >/dev/null 2>&1

    # --- Open firewall ---
    open_firewall "$wg_port" "$wg_nic"

    # --- Start WireGuard ---
    step "Starting WireGuard..."
    if [[ "$OS" == "alpine" ]]; then
        ln -sf /etc/init.d/wg-quick "/etc/init.d/wg-quick.${wg_nic}" 2>/dev/null || true
        rc-service "wg-quick.${wg_nic}" start 2>/dev/null || wg-quick up "$wg_nic"
        rc-update add "wg-quick.${wg_nic}" 2>/dev/null || true
    else
        systemctl enable "wg-quick@${wg_nic}" >/dev/null 2>&1
        systemctl start "wg-quick@${wg_nic}"
    fi

    # Verify it's running
    if wg show "$wg_nic" &>/dev/null; then
        info "WireGuard server is ${GREEN}running${NC} on ${BOLD}${wg_nic}${NC} (port ${wg_port})"
    else
        warn "WireGuard may not be running. Try rebooting if you see kernel module errors."
    fi

    CLEANUP_NEEDED=false
    log_info "Server setup complete: ${wg_nic} on port ${wg_port}"

    # Update default NIC for this session
    DEFAULT_WG_NIC="$wg_nic"
}

# =============================================================================
# CLIENT MANAGEMENT
# =============================================================================

add_client() {
    load_params
    local wg_nic="$SERVER_WG_NIC"
    local config_file="/etc/wireguard/${wg_nic}.conf"

    header "Add New Client"

    # --- Client name ---
    local client_name
    if [[ "$AUTO_MODE" == true && -n "${AUTO_CLIENT:-}" ]]; then
        client_name="$AUTO_CLIENT"
        AUTO_CLIENT=""
    else
        while true; do
            read -rp "Client name (alphanumeric, max 15 chars): " client_name
            if ! is_valid_client_name "$client_name"; then
                error "Invalid name. Use only letters, numbers, hyphens, underscores (max 15 chars)."
                continue
            fi
            if grep -q "^### Client ${client_name}$" "$config_file" 2>/dev/null; then
                error "Client '${client_name}' already exists. Choose a different name."
                continue
            fi
            break
        done
    fi

    if ! is_valid_client_name "$client_name"; then
        die "Invalid client name: $client_name"
    fi
    if grep -q "^### Client ${client_name}$" "$config_file" 2>/dev/null; then
        die "Client '${client_name}' already exists."
    fi

    acquire_lock
    CLEANUP_NEEDED=true
    create_backup "$wg_nic"

    # --- Allocate IPs ---
    local base_ipv4
    base_ipv4=$(echo "$SERVER_WG_IPV4" | cut -d'.' -f1-3)
    local next_ip
    next_ip=$(get_next_ipv4 "$wg_nic" "$base_ipv4")
    if [[ -z "$next_ip" ]]; then
        release_lock
        die "No available IPv4 addresses (subnet full, max 253 clients)."
    fi
    local client_ipv4="${base_ipv4}.${next_ip}"

    local base_ipv6="${SERVER_WG_IPV6%%::*}::"
    local next_ipv6
    next_ipv6=$(get_next_ipv6_suffix "$wg_nic" "$base_ipv6")
    local client_ipv6="${base_ipv6}${next_ipv6}"

    # --- Generate keys ---
    step "Generating client keypair and PSK..."
    local client_privkey client_pubkey client_psk
    client_privkey=$(wg genkey)
    client_pubkey=$(echo "$client_privkey" | wg pubkey)
    client_psk=$(wg genpsk)

    # --- DNS selection (if not auto) ---
    local dns_1="$CLIENT_DNS_1"
    local dns_2="$CLIENT_DNS_2"
    if [[ "$AUTO_MODE" != true ]]; then
        echo ""
        msg "${BOLD}DNS for this client:${NC}"
        msg "  1) Use server default (${CLIENT_DNS_1}, ${CLIENT_DNS_2})"
        msg "  2) Cloudflare (1.1.1.1)"
        msg "  3) AdGuard ad-blocking (94.140.14.14)"
        msg "  4) Custom"
        local dns_opt
        read -rp "Choice [1]: " dns_opt
        dns_opt="${dns_opt:-1}"
        case "$dns_opt" in
            2) dns_1="1.1.1.1"; dns_2="1.0.0.1" ;;
            3) dns_1="94.140.14.14"; dns_2="94.140.15.15" ;;
            4)
                read -rp "Primary DNS: " dns_1
                read -rp "Secondary DNS: " dns_2
                dns_2="${dns_2:-$dns_1}"
                ;;
        esac
    fi

    # --- Allowed IPs for client ---
    local allowed_ips="${ALLOWED_IPS:-0.0.0.0/0,::/0}"
    if [[ "$AUTO_MODE" != true ]]; then
        read -rp "AllowedIPs for client [${allowed_ips}]: " custom_allowed
        allowed_ips="${custom_allowed:-$allowed_ips}"
    fi

    # --- Add peer to server config ---
    step "Adding peer to server configuration..."
    cat >> "$config_file" <<EOF

### Client ${client_name}
[Peer]
PublicKey = ${client_pubkey}
PresharedKey = ${client_psk}
AllowedIPs = ${client_ipv4}/32,${client_ipv6}/128
EOF

    # --- Apply without restart (zero-downtime) ---
    if wg show "$wg_nic" &>/dev/null; then
        wg syncconf "$wg_nic" <(wg-quick strip "$wg_nic")
    else
        systemctl restart "wg-quick@${wg_nic}" 2>/dev/null || wg-quick up "$wg_nic" 2>/dev/null || true
    fi

    # --- Generate client config ---
    local endpoint="${SERVER_PUB_IP}:${SERVER_PORT}"
    # Wrap IPv6 in brackets
    if [[ "$SERVER_PUB_IP" =~ : ]]; then
        endpoint="[${SERVER_PUB_IP}]:${SERVER_PORT}"
    fi

    mkdir -p "$CLIENT_DIR"
    local client_config_file="${CLIENT_DIR}/${wg_nic}-client-${client_name}.conf"

    cat > "$client_config_file" <<EOF
[Interface]
PrivateKey = ${client_privkey}
Address = ${client_ipv4}/32,${client_ipv6}/128
DNS = ${dns_1},${dns_2}
MTU = ${CLIENT_MTU:-1420}

[Peer]
PublicKey = ${SERVER_PUB_KEY}
PresharedKey = ${client_psk}
Endpoint = ${endpoint}
AllowedIPs = ${allowed_ips}
PersistentKeepalive = ${KEEPALIVE:-25}
EOF

    chmod 600 "$client_config_file"

    CLEANUP_NEEDED=false
    release_lock

    # --- Output ---
    echo ""
    info "Client ${BOLD}'${client_name}'${NC} added successfully!"
    info "IPv4: ${client_ipv4}/32 | IPv6: ${client_ipv6}/128"
    info "Config saved: ${client_config_file}"
    echo ""

    # QR Code
    if command -v qrencode &>/dev/null; then
        msg "${BOLD}${BLUE}QR Code (scan with WireGuard mobile app):${NC}"
        echo ""
        qrencode -t ansiutf8 -l L < "$client_config_file"
        echo ""
    fi

    log_info "Client '${client_name}' added: ${client_ipv4}/32, ${client_ipv6}/128"
}

remove_client() {
    load_params
    local wg_nic="$SERVER_WG_NIC"
    local config_file="/etc/wireguard/${wg_nic}.conf"

    header "Remove Client"

    local num_clients
    num_clients=$(grep -c "^### Client" "$config_file" 2>/dev/null || echo "0")
    if [[ "$num_clients" -eq 0 ]]; then
        warn "No clients configured."
        return 0
    fi

    msg "${BOLD}Existing clients:${NC}"
    grep "^### Client" "$config_file" | cut -d' ' -f3 | nl -s ') '
    echo ""

    local client_num
    read -rp "Select client number to remove (or 'q' to cancel): " client_num
    [[ "$client_num" == "q" ]] && return 0

    if ! [[ "$client_num" =~ ^[0-9]+$ ]] || ((client_num < 1 || client_num > num_clients)); then
        error "Invalid selection."
        return 1
    fi

    local client_name
    client_name=$(grep "^### Client" "$config_file" | cut -d' ' -f3 | sed -n "${client_num}p")

    read -rp "Remove client '${client_name}'? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        msg "Cancelled."
        return 0
    fi

    acquire_lock
    create_backup "$wg_nic"

    # Remove peer block (from ### Client line to next blank line or EOF)
    sed -i "/^### Client ${client_name}$/,/^$/d" "$config_file"

    # Remove client config file
    rm -f "${CLIENT_DIR}/${wg_nic}-client-${client_name}.conf"

    # Apply changes
    if wg show "$wg_nic" &>/dev/null; then
        wg syncconf "$wg_nic" <(wg-quick strip "$wg_nic")
    fi

    release_lock

    info "Client '${client_name}' removed."
    log_info "Client '${client_name}' removed from ${wg_nic}."
}

list_clients() {
    load_params
    local wg_nic="$SERVER_WG_NIC"
    local config_file="/etc/wireguard/${wg_nic}.conf"

    header "Client List (${wg_nic})"

    local num_clients
    num_clients=$(grep -c "^### Client" "$config_file" 2>/dev/null || echo "0")
    if [[ "$num_clients" -eq 0 ]]; then
        warn "No clients configured."
        return 0
    fi

    printf "${BOLD}%-4s %-16s %-22s %-20s %-12s${NC}\n" "#" "Name" "IPv4" "Last Handshake" "Transfer"
    echo "────────────────────────────────────────────────────────────────────────────────"

    local idx=0
    local wg_dump
    wg_dump=$(wg show "$wg_nic" dump 2>/dev/null | tail -n +2 || echo "")

    while IFS= read -r client_line; do
        ((idx++))
        local name
        name=$(echo "$client_line" | cut -d' ' -f3)

        # Get client's public key from config
        local pubkey
        pubkey=$(grep -A 2 "^### Client ${name}$" "$config_file" | grep "PublicKey" | awk '{print $3}')

        # Get client's IP
        local client_ip
        client_ip=$(grep -A 3 "^### Client ${name}$" "$config_file" | grep "AllowedIPs" | awk '{print $3}' | cut -d',' -f1)

        # Get handshake and transfer from wg dump
        local handshake="never" transfer="-"
        if [[ -n "$wg_dump" && -n "$pubkey" ]]; then
            local peer_line
            peer_line=$(echo "$wg_dump" | grep "^${pubkey}" || echo "")
            if [[ -n "$peer_line" ]]; then
                local hs_epoch rx tx
                hs_epoch=$(echo "$peer_line" | awk -F'\t' '{print $5}')
                rx=$(echo "$peer_line" | awk -F'\t' '{print $6}')
                tx=$(echo "$peer_line" | awk -F'\t' '{print $7}')

                if [[ "$hs_epoch" != "0" && -n "$hs_epoch" ]]; then
                    local now diff
                    now=$(date +%s)
                    diff=$((now - hs_epoch))
                    if ((diff < 60)); then
                        handshake="${diff}s ago"
                    elif ((diff < 3600)); then
                        handshake="$((diff / 60))m ago"
                    elif ((diff < 86400)); then
                        handshake="$((diff / 3600))h ago"
                    else
                        handshake="$((diff / 86400))d ago"
                    fi
                fi

                if [[ -n "$rx" && -n "$tx" ]]; then
                    local rx_h tx_h
                    rx_h=$(numfmt --to=iec "$rx" 2>/dev/null || echo "${rx}B")
                    tx_h=$(numfmt --to=iec "$tx" 2>/dev/null || echo "${tx}B")
                    transfer="↓${rx_h} ↑${tx_h}"
                fi
            fi
        fi

        printf "%-4s %-16s %-22s %-20s %-12s\n" "$idx" "$name" "$client_ip" "$handshake" "$transfer"
    done < <(grep "^### Client" "$config_file")
}

toggle_client() {
    load_params
    local wg_nic="$SERVER_WG_NIC"
    local config_file="/etc/wireguard/${wg_nic}.conf"

    header "Enable/Disable Client"

    local num_clients
    num_clients=$(grep -c "^### Client" "$config_file" 2>/dev/null || echo "0")
    if [[ "$num_clients" -eq 0 ]]; then
        warn "No clients configured."
        return 0
    fi

    msg "${BOLD}Existing clients:${NC}"
    grep "^### Client" "$config_file" | cut -d' ' -f3 | nl -s ') '
    echo ""

    local client_num
    read -rp "Select client number to toggle: " client_num
    if ! [[ "$client_num" =~ ^[0-9]+$ ]] || ((client_num < 1 || client_num > num_clients)); then
        error "Invalid selection."
        return 1
    fi

    local client_name
    client_name=$(grep "^### Client" "$config_file" | cut -d' ' -f3 | sed -n "${client_num}p")

    acquire_lock
    create_backup "$wg_nic"

    # Check if currently disabled (commented [Peer])
    local peer_line_content
    peer_line_content=$(grep -A 1 "^### Client ${client_name}$" "$config_file" | tail -1)

    if [[ "$peer_line_content" == "#[Peer]"* || "$peer_line_content" == "# [Peer]"* ]]; then
        # Enable: uncomment the block
        sed -i "/^### Client ${client_name}$/,/^$/{s/^#//}" "$config_file"
        info "Client '${client_name}' ${GREEN}enabled${NC}."
        log_info "Client '${client_name}' enabled."
    else
        # Disable: comment the [Peer] block (but not the ### Client marker)
        sed -i "/^### Client ${client_name}$/,/^$/{/^### Client/!s/^/#/}" "$config_file"
        info "Client '${client_name}' ${RED}disabled${NC}."
        log_info "Client '${client_name}' disabled."
    fi

    # Apply
    if wg show "$wg_nic" &>/dev/null; then
        wg syncconf "$wg_nic" <(wg-quick strip "$wg_nic") 2>/dev/null || \
            systemctl restart "wg-quick@${wg_nic}" 2>/dev/null || true
    fi

    release_lock
}

regenerate_client() {
    load_params
    local wg_nic="$SERVER_WG_NIC"
    local config_file="/etc/wireguard/${wg_nic}.conf"

    header "Regenerate Client Config"

    local num_clients
    num_clients=$(grep -c "^### Client" "$config_file" 2>/dev/null || echo "0")
    if [[ "$num_clients" -eq 0 ]]; then
        warn "No clients configured."
        return 0
    fi

    # Check if config file exists for any client
    msg "${BOLD}Existing clients:${NC}"
    local idx=0
    while IFS= read -r client_line; do
        ((idx++))
        local name
        name=$(echo "$client_line" | cut -d' ' -f3)
        local status="${RED}[config missing]${NC}"
        if [[ -f "${CLIENT_DIR}/${wg_nic}-client-${name}.conf" ]]; then
            status="${GREEN}[config exists]${NC}"
        fi
        printf "  %d) %-16s %b\n" "$idx" "$name" "$status"
    done < <(grep "^### Client" "$config_file")
    echo ""

    local client_num
    read -rp "Select client to regenerate (or 'q' to cancel): " client_num
    [[ "$client_num" == "q" ]] && return 0

    if ! [[ "$client_num" =~ ^[0-9]+$ ]] || ((client_num < 1 || client_num > num_clients)); then
        error "Invalid selection."
        return 1
    fi

    local client_name
    client_name=$(grep "^### Client" "$config_file" | cut -d' ' -f3 | sed -n "${client_num}p")
    local client_config_file="${CLIENT_DIR}/${wg_nic}-client-${client_name}.conf"

    if [[ -f "$client_config_file" ]]; then
        msg "${YELLOW}Config file exists. Showing QR code:${NC}"
        echo ""
        if command -v qrencode &>/dev/null; then
            qrencode -t ansiutf8 -l L < "$client_config_file"
        fi
        cat "$client_config_file"
        echo ""
        read -rp "Re-key this client (generates new keys, old config will stop working)? [y/N]: " rekey
        if [[ "$rekey" != "y" && "$rekey" != "Y" ]]; then
            return 0
        fi
    fi

    warn "Re-keying client '${client_name}'. The old configuration will stop working."

    acquire_lock
    create_backup "$wg_nic"

    # Get current IPs
    local client_ips
    client_ips=$(grep -A 3 "^### Client ${client_name}$" "$config_file" | grep "AllowedIPs" | awk '{print $3}')
    local client_ipv4
    client_ipv4=$(echo "$client_ips" | cut -d',' -f1)
    local client_ipv6
    client_ipv6=$(echo "$client_ips" | cut -d',' -f2)

    # Generate new keys
    local new_privkey new_pubkey new_psk
    new_privkey=$(wg genkey)
    new_pubkey=$(echo "$new_privkey" | wg pubkey)
    new_psk=$(wg genpsk)

    # Update server config
    sed -i "/^### Client ${client_name}$/,/^$/{
        s|^PublicKey = .*|PublicKey = ${new_pubkey}|
        s|^PresharedKey = .*|PresharedKey = ${new_psk}|
    }" "$config_file"

    # Apply
    if wg show "$wg_nic" &>/dev/null; then
        wg syncconf "$wg_nic" <(wg-quick strip "$wg_nic")
    fi

    # Write new client config
    local endpoint="${SERVER_PUB_IP}:${SERVER_PORT}"
    if [[ "$SERVER_PUB_IP" =~ : ]]; then
        endpoint="[${SERVER_PUB_IP}]:${SERVER_PORT}"
    fi

    cat > "$client_config_file" <<EOF
[Interface]
PrivateKey = ${new_privkey}
Address = ${client_ipv4},${client_ipv6}
DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}
MTU = ${CLIENT_MTU:-1420}

[Peer]
PublicKey = ${SERVER_PUB_KEY}
PresharedKey = ${new_psk}
Endpoint = ${endpoint}
AllowedIPs = ${ALLOWED_IPS}
PersistentKeepalive = ${KEEPALIVE:-25}
EOF

    chmod 600 "$client_config_file"
    release_lock

    info "Client '${client_name}' re-keyed successfully!"
    info "New config: ${client_config_file}"
    echo ""
    if command -v qrencode &>/dev/null; then
        qrencode -t ansiutf8 -l L < "$client_config_file"
    fi
    log_info "Client '${client_name}' re-keyed."
}

show_client_config() {
    load_params
    local wg_nic="$SERVER_WG_NIC"
    local config_file="/etc/wireguard/${wg_nic}.conf"

    header "Client Configurations"

    local num_clients
    num_clients=$(grep -c "^### Client" "$config_file" 2>/dev/null || echo "0")
    if [[ "$num_clients" -eq 0 ]]; then
        warn "No clients configured."
        return 0
    fi

    while IFS= read -r client_line; do
        local name
        name=$(echo "$client_line" | cut -d' ' -f3)
        local client_config="${CLIENT_DIR}/${wg_nic}-client-${name}.conf"

        msg "\n${BOLD}${YELLOW}━━━ ${name} ━━━${NC}"
        if [[ -f "$client_config" ]]; then
            cat "$client_config"
            echo ""
            if command -v qrencode &>/dev/null; then
                qrencode -t ansiutf8 -l L < "$client_config"
            fi
        else
            warn "Config file not found. Use 'Regenerate' to create a new one."
        fi
    done < <(grep "^### Client" "$config_file")
}

# =============================================================================
# SERVER STATUS
# =============================================================================

show_status() {
    load_params
    local wg_nic="$SERVER_WG_NIC"

    header "Server Status (${wg_nic})"

    # Basic info
    printf "${BOLD}%-18s${NC} %s\n" "Interface:" "$wg_nic"
    printf "${BOLD}%-18s${NC} %s\n" "Public IP:" "$SERVER_PUB_IP"
    printf "${BOLD}%-18s${NC} %s\n" "Port:" "$SERVER_PORT"
    printf "${BOLD}%-18s${NC} %s\n" "Server IPv4:" "$SERVER_WG_IPV4/24"
    printf "${BOLD}%-18s${NC} %s\n" "Server IPv6:" "$SERVER_WG_IPV6/64"

    # Service status
    local svc_status
    if systemctl is-active "wg-quick@${wg_nic}" &>/dev/null; then
        svc_status="${GREEN}active (running)${NC}"
    else
        svc_status="${RED}inactive${NC}"
    fi
    printf "${BOLD}%-18s${NC} %b\n" "Service:" "$svc_status"

    # Uptime (from interface creation)
    if [[ -f "/sys/class/net/${wg_nic}/operstate" ]]; then
        printf "${BOLD}%-18s${NC} %s\n" "State:" "$(cat "/sys/class/net/${wg_nic}/operstate")"
    fi

    echo ""
    msg "${BOLD}Connected Peers:${NC}"
    echo ""

    local wg_output
    wg_output=$(wg show "$wg_nic" 2>/dev/null || echo "")
    if [[ -z "$wg_output" ]]; then
        warn "Could not query WireGuard interface."
        return 0
    fi

    # Detailed peer info
    wg show "$wg_nic" dump 2>/dev/null | tail -n +2 | while IFS=$'\t' read -r pubkey _psk _endpoint allowed_ips handshake rx tx _keepalive; do
        # Find client name
        local config_file="/etc/wireguard/${wg_nic}.conf"
        local name="unknown"
        local found_name
        found_name=$(grep -B 1 "PublicKey = ${pubkey}" "$config_file" 2>/dev/null | grep "^### Client" | cut -d' ' -f3 || echo "")
        [[ -n "$found_name" ]] && name="$found_name"

        # Format
        local hs_str="never"
        if [[ "$handshake" != "0" && -n "$handshake" ]]; then
            local now diff
            now=$(date +%s)
            diff=$((now - handshake))
            if ((diff < 60)); then hs_str="${diff}s ago"
            elif ((diff < 3600)); then hs_str="$((diff / 60))m ago"
            elif ((diff < 86400)); then hs_str="$((diff / 3600))h ago"
            else hs_str="$((diff / 86400))d ago"
            fi
        fi

        local rx_h tx_h
        rx_h=$(numfmt --to=iec "${rx:-0}" 2>/dev/null || echo "0B")
        tx_h=$(numfmt --to=iec "${tx:-0}" 2>/dev/null || echo "0B")

        printf "  ${CYAN}●${NC} %-15s │ IPs: %-24s │ Handshake: %-10s │ ↓%s ↑%s\n" \
            "$name" "$allowed_ips" "$hs_str" "$rx_h" "$tx_h"
    done
}

# =============================================================================
# EXPORT CONFIGS
# =============================================================================

export_configs() {
    load_params
    local wg_nic="$SERVER_WG_NIC"

    header "Export Client Configurations"

    local export_dir="/tmp/wireguard-export-${wg_nic}"
    local export_tar
    export_tar="/tmp/wireguard-clients-${wg_nic}-$(date '+%Y%m%d').tar.gz"

    rm -rf "$export_dir"
    mkdir -p "$export_dir"

    local count=0
    for conf in "${CLIENT_DIR}/${wg_nic}-client-"*.conf; do
        if [[ -f "$conf" ]]; then
            cp "$conf" "$export_dir/"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]]; then
        warn "No client configs found to export."
        rm -rf "$export_dir"
        return 0
    fi

    tar -czf "$export_tar" -C /tmp "wireguard-export-${wg_nic}"
    rm -rf "$export_dir"

    info "Exported ${count} client configs to: ${BOLD}${export_tar}${NC}"
    info "Size: $(du -h "$export_tar" | awk '{print $1}')"
    log_info "Exported ${count} configs to ${export_tar}"
}

# =============================================================================
# INTERFACE MANAGEMENT
# =============================================================================

switch_interface() {
    header "Interface Management"

    msg "${BOLD}Available WireGuard interfaces:${NC}"
    echo ""
    local idx=0
    local -a interfaces=()
    for conf in /etc/wireguard/wg*.conf; do
        if [[ -f "$conf" ]]; then
            ((idx++))
            local iface
            iface=$(basename "$conf" .conf)
            interfaces+=("$iface")
            local status="${RED}inactive${NC}"
            if systemctl is-active "wg-quick@${iface}" &>/dev/null; then
                status="${GREEN}active${NC}"
            fi
            local num_peers
            num_peers=$(grep -c "^### Client" "$conf" 2>/dev/null || echo "0")
            local marker=""
            if [[ "$iface" == "$SERVER_WG_NIC" ]]; then
                marker=" ${CYAN}← current${NC}"
            fi
            printf "  %d) %-10s [%b] %d clients%b\n" "$idx" "$iface" "$status" "$num_peers" "$marker"
        fi
    done

    if [[ $idx -eq 0 ]]; then
        warn "No WireGuard interfaces found."
    fi

    echo ""
    msg "  N) Create new interface"
    msg "  Q) Back to menu"
    echo ""

    local choice
    read -rp "Select: " choice

    case "$choice" in
        [Qq]) return 0 ;;
        [Nn])
            # Create new interface
            read -rp "New interface name (e.g., wg1): " new_nic
            if ! is_valid_interface_name "$new_nic"; then
                error "Invalid interface name."
                return 1
            fi
            if [[ -f "/etc/wireguard/${new_nic}.conf" ]]; then
                error "Interface '${new_nic}' already exists."
                return 1
            fi
            DEFAULT_WG_NIC="$new_nic"
            setup_server
            ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= idx)); then
                local selected="${interfaces[$((choice - 1))]}"
                # Update params to use this interface
                if [[ -f "$PARAMS_FILE" ]]; then
                    sed -i "s/^SERVER_WG_NIC=.*/SERVER_WG_NIC=${selected}/" "$PARAMS_FILE"
                fi
                SERVER_WG_NIC="$selected"
                info "Switched to interface: ${BOLD}${selected}${NC}"
            else
                error "Invalid selection."
            fi
            ;;
    esac
}

# =============================================================================
# SELF-UPDATE
# =============================================================================

self_update() {
    header "Check for Updates"
    step "Fetching latest version info..."

    local tmp_script="/tmp/wireguard_installer_update_$$.sh"
    CLEANUP_FILES+=("$tmp_script")

    if ! curl -s --max-time 15 -o "$tmp_script" "$SCRIPT_URL"; then
        error "Could not reach update server."
        return 1
    fi

    local remote_version
    remote_version=$(grep '^readonly SCRIPT_VERSION=' "$tmp_script" 2>/dev/null | cut -d'"' -f2)
    if [[ -z "$remote_version" ]]; then
        remote_version=$(grep '^SCRIPT_VERSION=' "$tmp_script" 2>/dev/null | cut -d'"' -f2)
    fi

    if [[ -z "$remote_version" ]]; then
        error "Could not determine remote version."
        rm -f "$tmp_script"
        return 1
    fi

    msg "  Current version: ${BOLD}v${SCRIPT_VERSION}${NC}"
    msg "  Latest version:  ${BOLD}v${remote_version}${NC}"
    echo ""

    if [[ "$remote_version" == "$SCRIPT_VERSION" ]]; then
        info "You are running the latest version."
        rm -f "$tmp_script"
        return 0
    fi

    read -rp "Update to v${remote_version}? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        msg "Update cancelled."
        rm -f "$tmp_script"
        return 0
    fi

    local script_path
    script_path=$(realpath "${BASH_SOURCE[0]}")
    cp "$tmp_script" "$script_path"
    chmod +x "$script_path"
    rm -f "$tmp_script"

    info "Updated to v${remote_version}! Please re-run the script."
    log_info "Self-updated from v${SCRIPT_VERSION} to v${remote_version}"
    exit 0
}

# =============================================================================
# UNINSTALL
# =============================================================================

uninstall_wireguard() {
    header "Uninstall WireGuard"

    echo -e "${RED}${BOLD}WARNING: This will completely remove WireGuard and ALL configurations!${NC}"
    echo -e "${YELLOW}All client configs, keys, and server settings will be permanently deleted.${NC}"
    echo ""
    read -rp "Type 'UNINSTALL' to confirm: " confirm

    if [[ "$confirm" != "UNINSTALL" ]]; then
        msg "Uninstall cancelled."
        return 0
    fi

    log_info "Uninstalling WireGuard..."

    # Stop all WireGuard interfaces
    for conf in /etc/wireguard/wg*.conf; do
        if [[ -f "$conf" ]]; then
            local iface
            iface=$(basename "$conf" .conf)
            systemctl stop "wg-quick@${iface}" 2>/dev/null || true
            systemctl disable "wg-quick@${iface}" 2>/dev/null || true
        fi
    done

    # Close firewall port
    if [[ -f "$PARAMS_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$PARAMS_FILE" 2>/dev/null || true
        if [[ -n "${SERVER_PORT:-}" ]]; then
            close_firewall "$SERVER_PORT"
        fi
    fi

    # Remove packages
    case "$OS" in
        ubuntu|debian)
            apt-get remove -y --purge wireguard wireguard-tools 2>/dev/null || true
            apt-get autoremove -y 2>/dev/null || true
            ;;
        fedora)
            dnf remove -y --noautoremove wireguard-tools 2>/dev/null || true
            ;;
        centos)
            yum remove -y --noautoremove wireguard-tools 2>/dev/null || true
            ;;
        arch)
            pacman -Rs --noconfirm wireguard-tools 2>/dev/null || true
            ;;
        alpine)
            apk del wireguard-tools 2>/dev/null || true
            ;;
    esac

    # Remove all configs
    rm -rf /etc/wireguard
    rm -f /etc/sysctl.d/99-wireguard.conf
    sysctl --system >/dev/null 2>&1 || true

    info "WireGuard has been completely uninstalled."
    log_info "WireGuard uninstalled."
    exit 0
}

# =============================================================================
# PARAMS LOADING
# =============================================================================

load_params() {
    if [[ ! -f "$PARAMS_FILE" ]]; then
        die "WireGuard params not found at $PARAMS_FILE. Run initial setup first."
    fi
    # shellcheck source=/dev/null
    source "$PARAMS_FILE"

    # Validate critical params
    if [[ -z "${SERVER_WG_NIC:-}" ]]; then
        die "SERVER_WG_NIC not set in params file."
    fi
    if [[ -z "${SERVER_PUB_KEY:-}" ]]; then
        die "SERVER_PUB_KEY not set in params file."
    fi
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto|--non-interactive)
                AUTO_MODE=true; shift ;;
            --port)
                AUTO_PORT="${2:-}"; shift 2 ;;
            --dns)
                AUTO_DNS="${2:-}"; shift 2 ;;
            --client)
                AUTO_CLIENT="${2:-}"; shift 2 ;;
            --interface)
                AUTO_INTERFACE="${2:-}"; shift 2 ;;
            --version|-v)
                echo "WireGuard Installer v${SCRIPT_VERSION}"
                exit 0 ;;
            --help|-h)
                show_help; exit 0 ;;
            *)
                die "Unknown option: $1. Use --help for usage." ;;
        esac
    done
}

show_help() {
    cat <<EOF
${BOLD}WireGuard Automated Installer v${SCRIPT_VERSION}${NC}

${BOLD}USAGE:${NC}
    sudo ./wireguard_installer.sh [OPTIONS]

${BOLD}OPTIONS:${NC}
    --auto, --non-interactive   Run without prompts (use defaults)
    --port PORT                 WireGuard listening port (default: random high port)
    --dns IP                    DNS server for clients (default: 1.1.1.1)
    --client NAME               First client name (auto mode)
    --interface NAME            WireGuard interface name (default: wg0)
    --version, -v               Show version and exit
    --help, -h                  Show this help

${BOLD}EXAMPLES:${NC}
    # Interactive installation
    sudo ./wireguard_installer.sh

    # Fully automated setup
    sudo ./wireguard_installer.sh --auto --port 51820 --client phone --dns 1.1.1.1

    # Use custom interface
    sudo ./wireguard_installer.sh --interface wg1

${BOLD}MANAGEMENT:${NC}
    After installation, run the script again to access the management menu.

EOF
}

# =============================================================================
# MAIN MENU
# =============================================================================

show_menu() {
    echo ""
    msg "${BOLD}${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${BOLD}WireGuard Manager v${SCRIPT_VERSION}${NC}  ${DIM}(${SERVER_WG_NIC:-wg0})${NC}            ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}╠══════════════════════════════════════════════════╣${NC}"
    msg "${BOLD}${BLUE}║${NC}                                                  ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 1)${NC} Add new client                            ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 2)${NC} Remove client                             ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 3)${NC} List clients & status                     ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 4)${NC} Enable/Disable client                     ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 5)${NC} Regenerate client config                  ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 6)${NC} Show all configs & QR codes               ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 7)${NC} Server status & connections               ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 8)${NC} Export all client configs                  ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW} 9)${NC} Switch/Create interface                   ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW}10)${NC} Backup & Restore                          ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW}11)${NC} Check for updates                         ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW}12)${NC} Uninstall WireGuard                       ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}  ${YELLOW}13)${NC} Exit                                      ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}║${NC}                                                  ${BOLD}${BLUE}║${NC}"
    msg "${BOLD}${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    local option
    read -rp "Select option: " option

    case "$option" in
        1)  add_client ;;
        2)  remove_client ;;
        3)  list_clients ;;
        4)  toggle_client ;;
        5)  regenerate_client ;;
        6)  show_client_config ;;
        7)  show_status ;;
        8)  export_configs ;;
        9)  switch_interface ;;
        10)
            echo ""
            msg "  1) List backups"
            msg "  2) Restore a backup"
            local bk_choice
            read -rp "  Choice: " bk_choice
            case "$bk_choice" in
                1) list_backups "${SERVER_WG_NIC:-wg0}" ;;
                2) restore_backup "${SERVER_WG_NIC:-wg0}" ;;
                *) error "Invalid choice." ;;
            esac
            ;;
        11) self_update ;;
        12) uninstall_wireguard ;;
        13)
            info "Goodbye!"
            exit 0
            ;;
        *)
            error "Invalid option. Please choose 1-13."
            ;;
    esac
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

main() {
    # Parse arguments
    parse_args "$@"

    # Initialize logging
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE" 2>/dev/null || true
    log_info "════════ WireGuard Installer v${SCRIPT_VERSION} started (PID $$) ════════"

    # System checks
    check_root
    check_virtualization
    detect_os

    # Check if already installed
    if [[ -f "$PARAMS_FILE" ]]; then
        # Load existing configuration
        # shellcheck source=/dev/null
        source "$PARAMS_FILE"
        DEFAULT_WG_NIC="${SERVER_WG_NIC:-wg0}"

        msg ""
        msg "${GREEN}${BOLD}WireGuard is installed and configured.${NC}"
        msg "${DIM}Interface: ${SERVER_WG_NIC} | Port: ${SERVER_PORT} | IP: ${SERVER_WG_IPV4}${NC}"
        msg ""

        # Management loop
        while true; do
            show_menu
        done
    else
        # Fresh installation
        msg ""
        msg "${BOLD}${CYAN}Welcome to the WireGuard Automated Installer v${SCRIPT_VERSION}${NC}"
        msg "${DIM}https://github.com/happyhitzz/wireguard-auto-installer${NC}"
        msg ""

        detect_public_ip
        detect_interface

        install_packages
        setup_server
        add_client

        msg ""
        info "${BOLD}Initial setup complete!${NC}"
        msg ""
        log_info "Initial setup complete."

        # Enter management mode
        while true; do
            show_menu
        done
    fi
}

# Run
main "$@"
