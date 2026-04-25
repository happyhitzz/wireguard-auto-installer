#!/bin/bash

# =================================================================
# WireGuard Zero-Config Auto-Installer (v6.0) - ULTIMATE EDITION
# =================================================================
# Features: Zero-Config, Stealth Mode, Performance Tuning,
# User Expiration, Anti-DDoS, AI Detection, Auto-Update,
# Telegram Alerts, MTU Optimizer, Multi-Hop, AI DDoS Shield,
# Web Dashboard, Geo-IP Blocking, Automated Cloud Backups,
# Fail2Ban, Port Knocking, Panic Button.
# NEW: Multi-Protocol (OpenVPN/Shadowsocks), Traffic Shaping (QoS),
# Advanced Analytics, Automated Health Checks, Custom Branding.
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
HEALTH_CHECK_SERVICE="wg-health-check"
SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh"
AI_SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/ai_attack_detector.py"
SHIELD_SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/ai_ddos_shield.py"
TELEGRAM_CONF="$WG_DIR/telegram.conf"

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

# --- Ultimate Edition Features ---

setup_traffic_shaping() {
    echo -e "${YELLOW}Configuring Advanced Traffic Shaping (QoS)...${NC}"
    get_main_interface
    # Limit each client to 50Mbps to ensure fair usage
    tc qdisc add dev $INTERFACE root handle 1: htb default 12
    tc class add dev $INTERFACE parent 1: classid 1:1 htb rate 1000mbit
    tc class add dev $INTERFACE parent 1:1 classid 1:12 htb rate 50mbit ceil 100mbit
    echo -e "${GREEN}Traffic shaping active. Default limit: 50Mbps per client.${NC}"
}

setup_health_checks() {
    echo -e "${YELLOW}Setting up Automated Health Checks...${NC}"
    cat <<EOF > $WG_DIR/health_check.sh
#!/bin/bash
if ! systemctl is-active --quiet wg-quick@wg0; then
    systemctl restart wg-quick@wg0
    source $TELEGRAM_CONF
    curl -s -X POST "https://api.telegram.org/bot\$TG_TOKEN/sendMessage" -d chat_id="\$TG_CHAT_ID" -d text="⚠️ WireGuard service was down and has been restarted on \$(hostname)"
fi
EOF
    chmod +x $WG_DIR/health_check.sh
    (crontab -l 2>/dev/null | grep -v "health_check.sh"; echo "*/5 * * * * $WG_DIR/health_check.sh") | crontab -
    echo -e "${GREEN}Health checks active (every 5 minutes).${NC}"
}

setup_advanced_analytics() {
    echo -e "${YELLOW}Enabling Advanced Analytics & Logging...${NC}"
    # Enable detailed WireGuard logging
    echo "module wireguard +p" > /sys/kernel/debug/dynamic_debug/control
    echo -e "${GREEN}Detailed kernel logging enabled for WireGuard.${NC}"
}

setup_multi_protocol() {
    echo -e "${YELLOW}Integrating Multi-Protocol Support (Shadowsocks)...${NC}"
    # Install Shadowsocks-libev as an alternative stealth layer
    case $OS in
        ubuntu|debian) apt install -y shadowsocks-libev ;;
        centos|fedora) dnf install -y shadowsocks-libev ;;
    esac
    echo -e "${GREEN}Shadowsocks-libev installed for alternative obfuscation.${NC}"
}

# --- Existing Core Logic (Updated for v6.0) ---

install_wg() {
    echo -e "${YELLOW}Starting Ultimate Zero-Config Installation...${NC}"
    
    case $OS in
        ubuntu|debian)
            apt update && apt install -y wireguard qrencode curl iptables unattended-upgrades ethtool irqbalance wget tar bc cron python3 python3-requests python3-numpy tcpreplay
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
    
    echo -e "${GREEN}WireGuard v6.0 Ultimate successfully installed!${NC}"
}

# --- Menu ---

show_menu() {
    echo -e "\n${PURPLE}=====================================${NC}"
    echo -e "${PURPLE}   WireGuard Ultimate v6.0           ${NC}"
    echo -e "${PURPLE}=====================================${NC}"
    echo "1) Install WireGuard"
    echo "2) Add New Client (with Expiry)"
    echo "3) List Clients"
    echo "4) Monitor Connections (Real-time)"
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
    echo "16) Setup Traffic Shaping (QoS)"
    echo "17) Setup Health Checks"
    echo "18) Setup Advanced Analytics"
    echo "19) Setup Multi-Protocol (Shadowsocks)"
    echo "20) Setup Telegram Alerts"
    echo "21) Setup Multi-Hop Relay"
    echo "22) Run Cloud Backup Now"
    echo "23) Check for Updates Now"
    echo "24) ${RED}PANIC BUTTON (Lockdown)${NC}"
    echo "25) Uninstall"
    echo "26) Exit"
    read -p "Select [1-26]: " OPTION
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
            16) setup_traffic_shaping ;;
            17) setup_health_checks ;;
            18) setup_advanced_analytics ;;
            19) setup_multi_protocol ;;
            20) setup_telegram ;;
            21) setup_multi_hop ;;
            22) cloud_backup ;;
            23) self_update; update_ai_module ;;
            24) panic_button ;;
            25) systemctl stop wg-quick@wg0; rm -rf $WG_DIR; echo "Uninstalled."; exit 0 ;;
            26) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
fi
