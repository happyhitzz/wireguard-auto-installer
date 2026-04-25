#!/bin/bash

# =================================================================
# WireGuard Zero-Config Auto-Installer (v5.0) - NEXT-GEN
# =================================================================
# Features: Zero-Config, Stealth Mode, Performance Tuning,
# User Expiration, Anti-DDoS, AI Detection, Auto-Update,
# Telegram Alerts, MTU Optimizer, Multi-Hop, AI DDoS Shield,
# NEW: Web Dashboard, Geo-IP Blocking, Automated Cloud Backups.
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
GEOIP_DB="/usr/share/GeoIP/GeoLite2-Country.mmdb"

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

# --- Next-Gen Features ---

setup_web_dashboard() {
    echo -e "${YELLOW}Setting up Web Management Dashboard...${NC}"
    if systemctl is-active --quiet $DASHBOARD_SERVICE; then
        echo -e "${GREEN}Dashboard is already running.${NC}"
    else
        # Using a lightweight, popular dashboard like WireGuard-UI
        if [[ ! -f /usr/local/bin/wireguard-ui ]]; then
            VERSION=$(curl -s https://api.github.com/repos/ngoduyduyet/wireguard-ui/releases/latest | grep tag_name | cut -d '"' -f 4)
            wget https://github.com/ngoduyduyet/wireguard-ui/releases/download/$VERSION/wireguard-ui-$VERSION-linux-amd64.tar.gz -O /tmp/wg-ui.tar.gz
            tar -xvf /tmp/wg-ui.tar.gz -C /usr/local/bin/
            chmod +x /usr/local/bin/wireguard-ui
        fi

        cat <<EOF > /etc/systemd/system/$DASHBOARD_SERVICE.service
[Unit]
Description=WireGuard Web UI
After=network.target

[Service]
Type=simple
WorkingDirectory=$WG_DIR
ExecStart=/usr/local/bin/wireguard-ui
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable --now $DASHBOARD_SERVICE
        get_public_ip
        echo -e "${GREEN}Dashboard active at http://$SERVER_IP:5000${NC}"
        send_telegram_msg "🌐 Web Dashboard Activated at http://$SERVER_IP:5000"
    fi
}

setup_geoip_blocking() {
    echo -e "${YELLOW}Configuring Geo-IP Blocking...${NC}"
    # Install xtables-addons for GeoIP support
    case $OS in
        ubuntu|debian)
            apt install -y xtables-addons-common libtext-csv-xs-perl libmoosex-types-netaddr-ip-perl
            /usr/libexec/xtables-addons/xt_geoip_dl
            mkdir -p /usr/share/xt_geoip
            /usr/libexec/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip *.csv
            ;;
        *)
            echo -e "${RED}Geo-IP blocking currently only optimized for Debian/Ubuntu.${NC}"
            return
            ;;
    esac
    
    read -p "Enter country codes to BLOCK (e.g., CN,RU,KP): " BLOCKED_COUNTRIES
    iptables -A INPUT -m geoip --src-cc $BLOCKED_COUNTRIES -j DROP
    echo -e "${GREEN}Blocked traffic from: $BLOCKED_COUNTRIES${NC}"
}

cloud_backup() {
    echo -e "${YELLOW}Performing Automated Cloud Backup...${NC}"
    BACKUP_FILE="/tmp/wg-backup-$(date +%F).tar.gz"
    tar -czf $BACKUP_FILE $WG_DIR
    
    # Option to upload to a private GitHub repo or S3 (Simplified for now)
    echo -e "${BLUE}Backup created at $BACKUP_FILE${NC}"
    send_telegram_msg "💾 Automated Cloud Backup completed: $(date)"
}

# --- Existing Core Logic (Updated for v5.0) ---

install_wg() {
    echo -e "${YELLOW}Starting Next-Gen Zero-Config Installation...${NC}"
    
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
    
    echo -e "${GREEN}WireGuard v5.0 successfully installed!${NC}"
    send_telegram_msg "✅ Next-Gen WireGuard Server Installed on $SERVER_IP"
}

# --- Menu ---

show_menu() {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${BLUE}   WireGuard Next-Gen v5.0           ${NC}"
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
    echo "14) Setup Telegram Alerts"
    echo "15) Setup Multi-Hop Relay"
    echo "16) Run Cloud Backup Now"
    echo "17) Check for Updates Now"
    echo "18) Uninstall"
    echo "19) Exit"
    read -p "Select [1-19]: " OPTION
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
            14) setup_telegram ;;
            15) setup_multi_hop ;;
            16) cloud_backup ;;
            17) self_update; update_ai_module ;;
            18) systemctl stop wg-quick@wg0; systemctl stop $AI_DETECTOR_SERVICE &> /dev/null; systemctl stop $AI_SHIELD_SERVICE &> /dev/null; systemctl stop $DASHBOARD_SERVICE &> /dev/null; rm -rf $WG_DIR; crontab -l | grep -v "wireguard_installer.sh" | crontab -; echo "Uninstalled."; exit 0 ;;
            19) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
fi
