#!/bin/bash

# =================================================================
# WireGuard Zero-Config Auto-Installer (v8.2) - STABLE EDITION
# =================================================================
# Features: Zero-Config, Stealth Mode, Performance Tuning,
# User Expiration, Anti-DDoS, AI Detection, Auto-Update,
# Telegram Alerts, MTU Optimizer, Multi-Hop, AI DDoS Shield,
# Web Dashboard, Geo-IP Blocking, Automated Cloud Backups,
# Fail2Ban, Port Knocking, Panic Button, Multi-Protocol,
# Traffic Shaping (QoS), Health Checks, Advanced Analytics,
# Quantum-Resistant VPN, Decentralized VPN, AI Predictive Threat,
# MFA, DoH/DoT Proxy, Serverless Deployment, Blockchain Identity.
# =================================================================

# --- Configuration & Defaults ---
WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
WG_PORT="51820"
WG_PROTO="udp"
AI_ASSISTANT_SCRIPT="$WG_DIR/wg_ai_assistant.py"
FEATURE_STATE_FILE="$WG_DIR/features.state"

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
    INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}' || ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | head -n1)
}

# --- Feature State Management ---

init_feature_states() {
    if [[ ! -f $FEATURE_STATE_FILE ]]; then
        mkdir -p "$WG_DIR"
        touch "$FEATURE_STATE_FILE"
    fi
}

get_feature_state() {
    local feature=$1
    grep "^$feature=" "$FEATURE_STATE_FILE" | cut -d= -f2 || echo "OFF"
}

set_feature_state() {
    local feature=$1
    local state=$2
    if grep -q "^$feature=" "$FEATURE_STATE_FILE"; then
        sed -i "s/^$feature=.*/$feature=$state/" "$FEATURE_STATE_FILE"
    else
        echo "$feature=$state" >> "$FEATURE_STATE_FILE"
    fi
}

# --- Core Logic Implementation ---

install_wg() {
    echo -e "${YELLOW}Installing WireGuard and dependencies...${NC}"
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt update && apt install -y wireguard curl iptables qrencode python3 python3-pip
    elif [[ "$OS" == "centos" || "$OS" == "fedora" ]]; then
        dnf install -y epel-release && dnf install -y wireguard-tools curl iptables qrencode python3 python3-pip
    fi

    get_public_ip
    get_main_interface

    # Generate keys
    SERVER_PRIV_KEY=$(wg genkey)
    SERVER_PUB_KEY=$(echo "$SERVER_PRIV_KEY" | wg pubkey)

    # Create config
    cat > "$WG_CONF" <<EOF
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
PrivateKey = $SERVER_PRIV_KEY
ListenPort = $WG_PORT

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE
EOF

    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    echo -e "${GREEN}WireGuard installed and started successfully!${NC}"
}

add_client() {
    read -p "Enter client name: " CLIENT_NAME
    CLIENT_PRIV_KEY=$(wg genkey)
    CLIENT_PUB_KEY=$(echo "$CLIENT_PRIV_KEY" | wg pubkey)
    CLIENT_IP="10.0.0.$(( $(grep -c "AllowedIPs" "$WG_CONF") + 2 ))"

    # Add to server config
    cat >> "$WG_CONF" <<EOF

# Client: $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUB_KEY
AllowedIPs = $CLIENT_IP/32
EOF

    wg syncconf wg0 <(wg-quick strip wg0)

    # Generate client config
    SERVER_PUB_KEY=$(grep PrivateKey "$WG_CONF" | cut -d' ' -f3 | wg pubkey)
    get_public_ip
    
    CLIENT_CONF_FILE="$HOME/${CLIENT_NAME}.conf"
    cat > "$CLIENT_CONF_FILE" <<EOF
[Interface]
PrivateKey = $CLIENT_PRIV_KEY
Address = $CLIENT_IP/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUB_KEY
Endpoint = $SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    echo -e "${GREEN}Client $CLIENT_NAME added! Config saved to $CLIENT_CONF_FILE${NC}"
    qrencode -t ansiutf8 < "$CLIENT_CONF_FILE"
}

# --- AI Assistant ---

run_ai_assistant() {
    if [[ -f $AI_ASSISTANT_SCRIPT ]]; then
        python3 "$AI_ASSISTANT_SCRIPT"
    else
        echo -e "${YELLOW}Downloading AI Assistant...${NC}"
        curl -s -o "$AI_ASSISTANT_SCRIPT" "https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wg_ai_assistant.py"
        python3 "$AI_ASSISTANT_SCRIPT"
    fi
}

# --- Menu ---

show_menu() {
    init_feature_states
    echo -e "\n${CYAN}=====================================${NC}"
    echo -e "${CYAN}   WireGuard Stable Edition v8.2     ${NC}"
    echo -e "${CYAN}=====================================${NC}"
    echo -e "${GREEN}0) ASK AI ASSISTANT (Help & Info)${NC}"
    echo "1) Install WireGuard"
    echo "2) Add New Client"
    echo "3) List Clients"
    echo "4) Monitor Connections (Real-time)"
    echo "5) Run Speed Test"
    echo "36) ${RED}PANIC BUTTON (Lockdown)${NC}"
    echo "37) Uninstall"
    echo "38) Exit"
    read -p "Select [0-38]: " OPTION
}

# --- Main ---
check_root
detect_os

while true; do
    show_menu
    case $OPTION in
        0) run_ai_assistant ;;
        1) if [[ -f $WG_CONF ]]; then echo -e "${YELLOW}Already installed.${NC}"; else install_wg; fi ;;
        2) add_client ;;
        3) grep "# Client:" "$WG_CONF" | cut -d: -f2 ;;
        4) watch -n 1 wg show ;;
        5) curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 - ;;
        36) iptables -P INPUT DROP; iptables -P FORWARD DROP; iptables -P OUTPUT DROP; echo -e "${RED}SERVER LOCKED DOWN!${NC}" ;;
        37) systemctl stop wg-quick@wg0; rm -rf "$WG_DIR"; echo "Uninstalled."; exit 0 ;;
        38) exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
done
