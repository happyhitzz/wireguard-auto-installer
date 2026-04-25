#!/bin/bash

# =================================================================
# WireGuard Zero-Config Auto-Installer (v4.1)
# =================================================================
# Features: Zero-Config, Stealth Mode, Performance Tuning,
# User Expiration, Anti-DDoS, AI Detection, Auto-Update,
# Telegram Alerts, MTU Optimizer, Multi-Hop, and NEW: AI DDoS Shield.
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

# --- Telegram Alert Logic ---

send_telegram_msg() {
    if [[ -f $TELEGRAM_CONF ]]; then
        source $TELEGRAM_CONF
        if [[ -n "$TG_TOKEN" && -n "$TG_CHAT_ID" ]]; then
            curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
                -d chat_id="$TG_CHAT_ID" \
                -d text="$1" > /dev/null
        fi
    fi
}

setup_telegram() {
    echo -e "${YELLOW}Setting up Telegram Alerts...${NC}"
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    read -p "Enter Telegram Chat ID: " TG_CHAT_ID
    echo "TG_TOKEN=\"$TG_TOKEN\"" > $TELEGRAM_CONF
    echo "TG_CHAT_ID=\"$TG_CHAT_ID\"" >> $TELEGRAM_CONF
    echo -e "${GREEN}Telegram Alerts Configured!${NC}"
    send_telegram_msg "🚀 WireGuard Server Alert System Activated!"
}

# --- Advanced Features ---

optimize_mtu() {
    echo -e "${YELLOW}Optimizing MTU for best performance...${NC}"
    for mtu in 1500 1420 1380 1280; do
        if ping -c 1 -M do -s $((mtu - 28)) 8.8.8.8 &> /dev/null; then
            BEST_MTU=$mtu
            break
        fi
    done
    BEST_MTU=${BEST_MTU:-1420}
    echo -e "${GREEN}Best MTU detected: $BEST_MTU${NC}"
    sed -i "s/MTU = .*/MTU = $BEST_MTU/" $WG_CONF
    systemctl restart wg-quick@wg0
}

setup_multi_hop() {
    echo -e "${YELLOW}Configuring Multi-Hop Relay...${NC}"
    read -p "Enter Remote WireGuard Public Key: " REMOTE_PUB
    read -p "Enter Remote Endpoint (IP:Port): " REMOTE_END
    
    cat <<EOF >> $WG_CONF

[Peer]
# Multi-Hop Relay to Remote
PublicKey = $REMOTE_PUB
Endpoint = $REMOTE_END
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    systemctl restart wg-quick@wg0
    echo -e "${GREEN}Multi-Hop Relay Configured!${NC}"
}

# --- Auto-Update Logic ---

self_update() {
    echo -e "${YELLOW}Checking for script updates...${NC}"
    TMP_FILE=$(mktemp)
    if wget -q $SCRIPT_URL -O "$TMP_FILE"; then
        if ! diff "$0" "$TMP_FILE" > /dev/null; then
            echo -e "${GREEN}New version found! Updating...${NC}"
            mv "$TMP_FILE" "$0"
            chmod +x "$0"
            send_telegram_msg "🔄 WireGuard Script updated to latest version."
            echo -e "${GREEN}Update complete. Restarting script...${NC}"
            exec "$0" "$@"
        else
            echo -e "${BLUE}Script is already up to date.${NC}"
            rm "$TMP_FILE"
        fi
    else
        echo -e "${RED}Failed to check for updates.${NC}"
        rm "$TMP_FILE"
    fi
}

update_ai_module() {
    for script in "$AI_DETECTOR_SCRIPT:$AI_SCRIPT_URL" "$AI_SHIELD_SCRIPT:$SHIELD_SCRIPT_URL"; do
        path="${script%%:*}"
        url="${script#*:}"
        if [[ -f $path ]]; then
            echo -e "${YELLOW}Updating $(basename $path)...${NC}"
            wget -q "$url" -O "$path.tmp" && mv "$path.tmp" "$path"
        fi
    done
    systemctl is-active --quiet $AI_DETECTOR_SERVICE && systemctl restart $AI_DETECTOR_SERVICE
    systemctl is-active --quiet $AI_SHIELD_SERVICE && systemctl restart $AI_SHIELD_SERVICE
}

# --- Core Logic ---

install_wg() {
    echo -e "${YELLOW}Starting Zero-Config Installation...${NC}"
    
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
     echo "0 3 * * * $(realpath $0) --auto-update") | crontab -
    
    echo -e "${GREEN}WireGuard successfully installed!${NC}"
    send_telegram_msg "✅ WireGuard Server Installed on $SERVER_IP"
}

add_client() {
    echo -e "${YELLOW}Adding a new client...${NC}"
    read -p "Enter client name: " CLIENT_NAME
    CLIENT_NAME=${CLIENT_NAME:-"client"}
    
    read -p "Set expiration in days (0 for never): " EXPIRY_DAYS
    EXPIRY_DAYS=${EXPIRY_DAYS:-0}

    LAST_IP=$(grep "AllowedIPs" $WG_CONF | tail -n1 | awk '{print $3}' | cut -d. -f4 | cut -d/ -f1)
    CLIENT_IP=$(( ${LAST_IP:-1} + 1 ))

    CLIENT_PRIV=$(wg genkey)
    CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
    
    echo -e "Select DNS (Default: Google):"
    echo "1) Google (8.8.8.8)"
    echo "2) Cloudflare (1.1.1.1)"
    echo "3) AdGuard (Ad-Blocking)"
    read -p "Choice [1-3]: " DNS_CHOICE
    case $DNS_CHOICE in
        2) DNS="1.1.1.1" ;;
        3) DNS="94.140.14.14" ;;
        *) DNS="8.8.8.8" ;;
    esac

    cat <<EOF >> $WG_CONF

[Peer]
# Client: $CLIENT_NAME
PublicKey = $CLIENT_PUB
AllowedIPs = 10.0.0.$CLIENT_IP/32
EOF

    wg addconf wg0 <(echo -e "[Peer]\nPublicKey = $CLIENT_PUB\nAllowedIPs = 10.0.0.$CLIENT_IP/32")

    if [[ $EXPIRY_DAYS -gt 0 ]]; then
        EXPIRY_DATE=$(date -d "+$EXPIRY_DAYS days" +%s)
        echo "$CLIENT_NAME:$CLIENT_PUB:$EXPIRY_DATE" >> $EXPIRY_LOG
        echo -e "${YELLOW}Client will expire on $(date -d @$EXPIRY_DATE).${NC}"
    fi

    get_public_ip
    SERVER_PUB=$(cat "$WG_DIR/server_public.key")
    
    CLIENT_CONF_FILE="$HOME/${CLIENT_NAME}_wg.conf"
    cat <<EOF > "$CLIENT_CONF_FILE"
[Interface]
PrivateKey = $CLIENT_PRIV
Address = 10.0.0.$CLIENT_IP/32
DNS = $DNS
MTU = 1420

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    echo -e "${GREEN}Client '$CLIENT_NAME' created!${NC}"
    send_telegram_msg "👤 New Client Added: $CLIENT_NAME"
    qrencode -t ansiutf8 < "$CLIENT_CONF_FILE"
}

check_expiry() {
    CURRENT_TIME=$(date +%s)
    TEMP_LOG=$(mktemp)
    RELOAD_NEEDED=false

    while IFS=: read -r NAME PUB EXPIRY; do
        if [[ $CURRENT_TIME -ge $EXPIRY ]]; then
            echo -e "${RED}Expiring client: $NAME${NC}"
            wg set wg0 peer "$PUB" remove
            sed -i "/PublicKey = $PUB/,/AllowedIPs/ s/^/#EXPIRED# /" $WG_CONF
            send_telegram_msg "⏳ Client Expired & Blocked: $NAME"
            RELOAD_NEEDED=true
        else
            echo "$NAME:$PUB:$EXPIRY" >> $TEMP_LOG
        fi
    done < $EXPIRY_LOG

    mv $TEMP_LOG $EXPIRY_LOG
    if [[ "$RELOAD_NEEDED" == "true" ]]; then
        systemctl restart wg-quick@wg0
    fi
}

apply_performance_tuning() {
    echo -e "${YELLOW}Applying Performance Tuning...${NC}"
    get_main_interface
    if [[ -n "$INTERFACE" ]]; then
        ethtool -K "$INTERFACE" gso off gro off tso off &> /dev/null
    fi
    systemctl enable --now irqbalance &> /dev/null
    cat <<EOF > /etc/sysctl.d/99-wg-ultimate.conf
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF
    sysctl -p /etc/sysctl.d/99-wg-ultimate.conf &> /dev/null
    echo -e "${GREEN}Optimized!${NC}"
}

setup_stealth_mode() {
    echo -e "${YELLOW}Toggling Stealth Mode...${NC}"
    if pgrep -x "udp2raw" > /dev/null; then
        pkill udp2raw && echo -e "${GREEN}Stealth Mode Disabled.${NC}"
    else
        if [[ ! -f /usr/local/bin/udp2raw ]]; then
            wget https://github.com/wangyu-/udp2raw/releases/download/20230206.0/udp2raw_binaries.tar.gz -O /tmp/udp2raw.tar.gz
            tar -xvf /tmp/udp2raw.tar.gz -C /tmp/ && cp /tmp/udp2raw_amd64 /usr/local/bin/udp2raw && chmod +x /usr/local/bin/udp2raw
        fi
        nohup udp2raw -s -l 0.0.0.0:443 -r 127.0.0.1:$WG_PORT -k "mypassword123" --raw-mode faketcp > /var/log/udp2raw.log 2>&1 &
        echo -e "${GREEN}Stealth Mode Enabled on Port 443.${NC}"
    fi
}

toggle_anti_ddos() {
    if [[ -f $BLACKHOLE_CONF ]]; then
        rm $BLACKHOLE_CONF
        sysctl --system &> /dev/null
        echo -e "${RED}Anti-DDoS Blackhole Disabled.${NC}"
    else
        echo -e "${YELLOW}Enabling Anti-DDoS Blackhole Protection...${NC}"
        cat <<EOF > $BLACKHOLE_CONF
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF
        sysctl -p $BLACKHOLE_CONF &> /dev/null
        echo -e "${GREEN}Anti-DDoS Blackhole Enabled.${NC}"
    fi
}

toggle_ai_detector() {
    if systemctl is-active --quiet $AI_DETECTOR_SERVICE; then
        systemctl stop $AI_DETECTOR_SERVICE
        systemctl disable $AI_DETECTOR_SERVICE
        echo -e "${RED}AI Attack Detector Disabled.${NC}"
    else
        echo -e "${YELLOW}Enabling AI Attack Detector...${NC}"
        if [[ ! -f $AI_DETECTOR_SCRIPT ]]; then
            wget -q $AI_SCRIPT_URL -O $AI_DETECTOR_SCRIPT
        fi
        read -p "Enter Discord Webhook URL (optional): " WEBHOOK
        if [[ -n "$WEBHOOK" ]]; then
            sed -i "s|DISCORD_WEBHOOK = .*|DISCORD_WEBHOOK = \"$WEBHOOK\"|" $AI_DETECTOR_SCRIPT
        fi
        cat <<EOF > /etc/systemd/system/$AI_DETECTOR_SERVICE.service
[Unit]
Description=WireGuard AI Attack Detector
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $AI_DETECTOR_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable --now $AI_DETECTOR_SERVICE
        echo -e "${GREEN}AI Attack Detector Enabled and Running.${NC}"
    fi
}

toggle_ai_shield() {
    if systemctl is-active --quiet $AI_SHIELD_SERVICE; then
        systemctl stop $AI_SHIELD_SERVICE
        systemctl disable $AI_SHIELD_SERVICE
        echo -e "${RED}AI DDoS Shield Disabled.${NC}"
    else
        echo -e "${YELLOW}Enabling AI DDoS Shield...${NC}"
        if [[ ! -f $AI_SHIELD_SCRIPT ]]; then
            wget -q $SHIELD_SCRIPT_URL -O $AI_SHIELD_SCRIPT
        fi
        cat <<EOF > /etc/systemd/system/$AI_SHIELD_SERVICE.service
[Unit]
Description=WireGuard AI DDoS Shield
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $AI_SHIELD_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable --now $AI_SHIELD_SERVICE
        echo -e "${GREEN}AI DDoS Shield Enabled and Running.${NC}"
    fi
}

# --- Menu ---

show_menu() {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${BLUE}   WireGuard AI-Shield v4.1          ${NC}"
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
    echo "10) Toggle AI Attack Detector (Logs)"
    echo "11) Toggle AI DDoS Shield (Traffic)"
    echo "12) Setup Telegram Alerts"
    echo "13) Setup Multi-Hop Relay"
    echo "14) Check for Updates Now"
    echo "15) Uninstall"
    echo "16) Exit"
    read -p "Select [1-16]: " OPTION
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
            12) setup_telegram ;;
            13) setup_multi_hop ;;
            14) self_update; update_ai_module ;;
            15) systemctl stop wg-quick@wg0; systemctl stop $AI_DETECTOR_SERVICE &> /dev/null; systemctl stop $AI_SHIELD_SERVICE &> /dev/null; rm -rf $WG_DIR; crontab -l | grep -v "wireguard_installer.sh" | crontab -; echo "Uninstalled."; exit 0 ;;
            16) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
fi
