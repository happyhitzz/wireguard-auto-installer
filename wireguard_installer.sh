#!/bin/bash

# =================================================================
# WireGuard Zero-Config Auto-Installer (v5.1) - HARDENED SECURITY
# =================================================================
# Features: Zero-Config, Stealth Mode, Performance Tuning,
# User Expiration, Anti-DDoS, AI Detection, Auto-Update,
# Telegram Alerts, MTU Optimizer, Multi-Hop, AI DDoS Shield,
# Web Dashboard, Geo-IP Blocking, Automated Cloud Backups,
# NEW: Fail2Ban Integration, Port Knocking, Panic Button.
# =================================================================

# --- Configuration & Defaults ---
WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
WG_PORT="51820"
WG_PROTO="udp"
STEALTH_PORT="443"
STEALTH_PASS="mypassword123"
EXPIRY_LOG="$WG_DIR/expiry.log"
BLACKHOLE_CONF="/etc/sysctl.d/99-anti-ddos.conf"
AI_DETECTOR_SCRIPT="$WG_DIR/ai_attack_detector.py"
AI_SHIELD_SCRIPT="$WG_DIR/ai_ddos_shield.py"
AI_DETECTOR_SERVICE="wg-ai-detector"
AI_SHIELD_SERVICE="wg-ai-shield"
DASHBOARD_SERVICE="wg-dashboard"
SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh"
AI_SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/ai_attack_detector.py"
SHIELD_SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/ai_ddos_shield.py"
TELEGRAM_CONF="$WG_DIR/telegram.conf"

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root.${NC}"
        exit 1
    fi
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        echo -e "${RED}Unsupported OS.${NC}"
        exit 1
    fi
}

get_public_ip() {
    SERVER_IP=$(curl -s ifconfig.me || curl -s api.ipify.org || echo "YOUR_SERVER_IP")
}

get_main_interface() {
    INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
    if [[ -z "$INTERFACE" ]]; then
        INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | head -n1)
    fi
}

# --- Hardened Security Features ---

setup_fail2ban() {
    echo -e "${YELLOW}Integrating Fail2Ban for SSH and VPN protection...${NC}"
    case $OS in
        ubuntu|debian) apt install -y fail2ban ;;
        centos|fedora) dnf install -y fail2ban ;;
    esac

    cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[wireguard]
enabled = true
port = $WG_PORT
protocol = udp
filter = wireguard
logpath = /var/log/syslog
maxretry = 5
bantime = 86400
EOF

    cat <<EOF > /etc/fail2ban/filter.d/wireguard.conf
[Definition]
failregex = wireguard: .* handshake for .* failed
ignoreregex =
EOF

    systemctl enable --now fail2ban
    echo -e "${GREEN}Fail2Ban configured and active.${NC}"
}

setup_port_knocking() {
    echo -e "${YELLOW}Setting up Port Knocking (knockd)...${NC}"
    case $OS in
        ubuntu|debian) apt install -y knockd ;;
        centos|fedora) dnf install -y knockd ;;
    esac

    cat <<EOF > /etc/knockd.conf
[options]
    UseSyslog

[openWireGuard]
    sequence    = 7000,8000,9000
    seq_timeout = 5
    command     = /sbin/iptables -I INPUT -s %IP% -p udp --dport $WG_PORT -j ACCEPT
    tcpflags    = syn

[closeWireGuard]
    sequence    = 9000,8000,7000
    seq_timeout = 5
    command     = /sbin/iptables -D INPUT -s %IP% -p udp --dport $WG_PORT -j ACCEPT
    tcpflags    = syn
EOF

    systemctl enable --now knockd
    echo -e "${GREEN}Port Knocking active. Sequence: 7000, 8000, 9000 (TCP).${NC}"
}

panic_button() {
    echo -e "${RED}🚨 PANIC BUTTON ACTIVATED! LOCKING DOWN SERVER...${NC}"
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -A INPUT -i lo -j ACCEPT
    # Allow current SSH session to prevent lockout
    SSH_IP=$(echo $SSH_CLIENT | awk '{print $1}')
    if [[ -n "$SSH_IP" ]]; then
        iptables -A INPUT -s $SSH_IP -p tcp --dport 22 -j ACCEPT
    fi
    systemctl stop wg-quick@wg0
    echo -e "${RED}All VPN traffic blocked. Only current SSH session allowed.${NC}"
    send_telegram_msg "🚨 PANIC BUTTON ACTIVATED on $SERVER_IP! Server is in lockdown."
}

# --- Existing Core Logic (Updated for v5.1) ---

install_wg() {
    echo -e "${YELLOW}Starting Hardened Zero-Config Installation...${NC}"
    
    case $OS in
        ubuntu|debian)
            apt update && apt install -y wireguard qrencode curl iptables unattended-upgrades ethtool irqbalance wget tar bc cron python3 python3-requests python3-numpy
            dpkg-reconfigure -plow unattended-upgrades
            ;;
        centos|fedora)
            dnf install -y epel-release
            dnf install -y wireguard-tools qrencode curl iptables dnf-automatic ethtool irqbalance wget tar bc cronie python3 python3-requests python3-numpy
            sed -i 's/upgrade_type = default/upgrade_type = security/' /etc/dnf/automatic.conf
            systemctl enable --now dnf-automatic.timer
            ;;
    esac
    
    mkdir -p $WG_DIR
    chmod 700 $WG_DIR
    touch $EXPIRY_LOG

    SERVER_PRIV=$(wg genkey)
    SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)
    echo "$SERVER_PRIV" > "$WG_DIR/server_private.key"
    echo "$SERVER_PUB" > "$WG_DIR/server_public.key"

    get_main_interface
    get_public_ip

    cat <<EOF > $WG_CONF
[Interface]
Address = 10.0.0.1/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIV
MTU = 1420
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE; iptables -A FORWARD -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE; iptables -D FORWARD -o wg0 -j ACCEPT
EOF

    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf

    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    (crontab -l 2>/dev/null | grep -v "wireguard_installer.sh"; 
     echo "0 * * * * $(realpath $0) --check-expiry";
     echo "0 3 * * * $(realpath $0) --auto-update";
     echo "0 4 * * * $(realpath $0) --backup") | crontab -
    
    echo -e "${GREEN}WireGuard v5.1 successfully installed!${NC}"
    send_telegram_msg "✅ Hardened WireGuard Server Installed on $SERVER_IP"
}

# --- Menu ---

show_menu() {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${BLUE}   WireGuard Hardened v5.1           ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo "1) Install WireGuard"
    echo "2) Add New Client (with Expiry)"
    echo "3) List Clients"
    echo "4) Monitor Connections"
    echo "5) Run Speed Test"
    echo "6) Optimize Performance (Kernel/BBR)"
    echo "7) Optimize MTU (Auto-Detect)"
    echo "8) Toggle Stealth Mode (udp2raw)"
    echo "9) Toggle Anti-DDoS Blackhole"
    echo "10) Toggle AI Attack Detector"
    echo "11) Toggle AI DDoS Shield"
    echo "12) Setup Web Dashboard"
    echo "13) Setup Geo-IP Blocking"
    echo "14) Setup Fail2Ban Protection"
    echo "15) Setup Port Knocking"
    echo "16) Setup Telegram Alerts"
    echo "17) Setup Multi-Hop Relay"
    echo "18) Run Cloud Backup Now"
    echo "19) Check for Updates Now"
    echo "20) ${RED}PANIC BUTTON (Lockdown)${NC}"
    echo "21) Uninstall"
    echo "22) Exit"
    read -p "Select [1-22]: " OPTION
}

# --- Main ---
check_root
detect_os

# Handle background flags
if [[ "$1" == "--check-expiry" ]]; then
    check_expiry
    exit 0
fi

if [[ "$1" == "--auto-update" ]]; then
    self_update --quiet
    update_ai_module
    exit 0
fi

if [[ "$1" == "--backup" ]]; then
    cloud_backup
    exit 0
fi

if [[ ! -d $WG_DIR ]]; then
    install_wg
    add_client
else
    while true; do
        show_menu
        case $OPTION in
            1) echo -e "${YELLOW}Already installed.${NC}" ;;
            2) add_client ;;
            3) grep "# Client:" $WG_CONF | cut -d: -f2 ;;
            4) watch -n 1 wg show ;;
            5) command -v speedtest-cli &> /dev/null || apt install -y speedtest-cli || dnf install -y speedtest-cli; speedtest-cli ;;
            6) apply_performance_tuning ;;
            7) optimize_mtu ;;
            8) setup_stealth_mode ;;
            9) toggle_anti_ddos ;;
            10) toggle_ai_detector ;;
            11) toggle_ai_shield ;;
            12) setup_web_dashboard ;;
            13) setup_geoip_blocking ;;
            14) setup_fail2ban ;;
            15) setup_port_knocking ;;
            16) setup_telegram ;;
            17) setup_multi_hop ;;
            18) cloud_backup ;;
            19) self_update; update_ai_module ;;
            20) panic_button ;;
            21) systemctl stop wg-quick@wg0; rm -rf $WG_DIR; echo "Uninstalled."; exit 0 ;;
            22) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
fi
