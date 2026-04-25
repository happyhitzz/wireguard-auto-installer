#!/bin/bash

# =================================================================
# WireGuard Advanced Auto-Installer (v2.2)
# =================================================================
# Features:
# - OS Detection (Ubuntu, Debian, CentOS, Fedora)
# - Multi-Client Management (Add/Remove/List)
# - Custom DNS Options (Google, Cloudflare, AdGuard)
# - Automatic Firewall Configuration
# - Automated Security Updates (Unattended Upgrades)
# - Real-time Connection Monitoring
# - Built-in Speed Test
# - Optional Performance Tuning (GSO, IRQ, Kernel Tweaks)
# - Optional Stealth Mode (Obfuscation via udp2raw)
# - Uninstaller
# =================================================================

# --- Configuration & Defaults ---
WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
WG_PORT="51820"
WG_PROTO="udp"
STEALTH_PORT="443"
STEALTH_PASS="mypassword123"

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# --- Core Logic ---

install_wg() {
    echo -e "${YELLOW}Installing WireGuard and essential tools...${NC}"
    case $OS in
        ubuntu|debian)
            apt update && apt install -y wireguard qrencode curl iptables unattended-upgrades ethtool irqbalance wget tar
            # Enable unattended upgrades for security
            dpkg-reconfigure -plow unattended-upgrades
            ;;
        centos|fedora)
            dnf install -y epel-release
            dnf install -y wireguard-tools qrencode curl iptables dnf-automatic ethtool irqbalance wget tar
            # Enable automatic security updates
            sed -i 's/upgrade_type = default/upgrade_type = security/' /etc/dnf/automatic.conf
            systemctl enable --now dnf-automatic.timer
            ;;
    esac
    
    mkdir -p $WG_DIR
    chmod 700 $WG_DIR

    # Generate Server Keys
    SERVER_PRIV=$(wg genkey)
    SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)
    echo "$SERVER_PRIV" > "$WG_DIR/server_private.key"
    echo "$SERVER_PUB" > "$WG_DIR/server_public.key"

    # Default Server Config
    cat <<EOF > $WG_CONF
[Interface]
Address = 10.0.0.1/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIV
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; iptables -A FORWARD -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; iptables -D FORWARD -o wg0 -j ACCEPT
EOF

    # Enable IP Forwarding
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf

    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    echo -e "${GREEN}WireGuard installed and started!${NC}"
}

add_client() {
    echo -e "${YELLOW}Adding a new client...${NC}"
    read -p "Enter client name (e.g., phone): " CLIENT_NAME
    
    # Find next available IP
    LAST_IP=$(grep "AllowedIPs" $WG_CONF | tail -n1 | awk '{print $3}' | cut -d. -f4 | cut -d/ -f1)
    if [ -z "$LAST_IP" ]; then
        CLIENT_IP="2"
    else
        CLIENT_IP=$((LAST_IP + 1))
    fi

    CLIENT_PRIV=$(wg genkey)
    CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
    
    # Choose DNS
    echo -e "Select DNS Provider:"
    echo "1) Google (8.8.8.8)"
    echo "2) Cloudflare (1.1.1.1)"
    echo "3) AdGuard (Ad-Blocking: 94.140.14.14)"
    read -p "Choice [1-3]: " DNS_CHOICE
    case $DNS_CHOICE in
        2) DNS="1.1.1.1" ;;
        3) DNS="94.140.14.14" ;;
        *) DNS="8.8.8.8" ;;
    esac

    # Add to Server Config
    cat <<EOF >> $WG_CONF

[Peer]
# Client: $CLIENT_NAME
PublicKey = $CLIENT_PUB
AllowedIPs = 10.0.0.$CLIENT_IP/32
EOF

    wg addconf wg0 <(echo -e "[Peer]\nPublicKey = $CLIENT_PUB\nAllowedIPs = 10.0.0.$CLIENT_IP/32")

    # Generate Client Config File
    get_public_ip
    SERVER_PUB=$(cat "$WG_DIR/server_public.key")
    
    CLIENT_CONF_FILE="$HOME/${CLIENT_NAME}_wg.conf"
    cat <<EOF > "$CLIENT_CONF_FILE"
[Interface]
PrivateKey = $CLIENT_PRIV
Address = 10.0.0.$CLIENT_IP/32
DNS = $DNS

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    echo -e "${GREEN}Client '$CLIENT_NAME' added!${NC}"
    echo -e "Config saved to: $CLIENT_CONF_FILE"
    
    # Check if Stealth Mode is active
    if pgrep -x "udp2raw" > /dev/null; then
        echo -e "${YELLOW}Stealth Mode is ACTIVE. Use the following for client setup:${NC}"
        echo -e "1. Run udp2raw on your client: udp2raw -c -l 127.0.0.1:51820 -r $SERVER_IP:$STEALTH_PORT -k \"$STEALTH_PASS\" --raw-mode faketcp"
        echo -e "2. Change Endpoint in your config to: 127.0.0.1:51820"
    fi

    echo -e "${YELLOW}QR Code for mobile setup:${NC}"
    qrencode -t ansiutf8 < "$CLIENT_CONF_FILE"
}

list_clients() {
    echo -e "${YELLOW}Current Clients:${NC}"
    grep "# Client:" $WG_CONF | cut -d: -f2
}

monitor_connections() {
    echo -e "${YELLOW}Real-time Connection Monitoring (Ctrl+C to exit):${NC}"
    watch -n 1 wg show
}

run_speedtest() {
    echo -e "${YELLOW}Running Speed Test...${NC}"
    if ! command -v speedtest-cli &> /dev/null; then
        echo -e "${YELLOW}Installing speedtest-cli...${NC}"
        case $OS in
            ubuntu|debian) apt install -y speedtest-cli ;;
            centos|fedora) dnf install -y speedtest-cli ;;
        esac
    fi
    speedtest-cli
}

apply_performance_tuning() {
    echo -e "${YELLOW}Applying Performance Optimizations...${NC}"
    
    INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
    if [[ -n "$INTERFACE" ]]; then
        ethtool -K "$INTERFACE" gso off gro off tso off &> /dev/null
        echo -e "${GREEN}GSO/GRO/TSO offloading disabled for $INTERFACE.${NC}"
    fi

    systemctl enable --now irqbalance &> /dev/null
    
    cat <<EOF > /etc/sysctl.d/99-wg-performance.conf
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 10000
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF
    sysctl -p /etc/sysctl.d/99-wg-performance.conf &> /dev/null
    echo -e "${GREEN}Performance tuning complete!${NC}"
}

setup_stealth_mode() {
    echo -e "${YELLOW}Setting up Stealth Mode (udp2raw)...${NC}"
    
    if pgrep -x "udp2raw" > /dev/null; then
        echo -e "${YELLOW}Stealth Mode is already running.${NC}"
        read -p "Do you want to stop it? [y/N]: " STOP_STEALTH
        if [[ $STOP_STEALTH == "y" || $STOP_STEALTH == "Y" ]]; then
            pkill udp2raw
            echo -e "${GREEN}Stealth Mode stopped.${NC}"
        fi
        return
    fi

    # Download udp2raw
    if [[ ! -f /usr/local/bin/udp2raw ]]; then
        echo -e "Downloading udp2raw..."
        wget https://github.com/wangyu-/udp2raw/releases/download/20230206.0/udp2raw_binaries.tar.gz -O /tmp/udp2raw.tar.gz
        tar -xvf /tmp/udp2raw.tar.gz -C /tmp/
        cp /tmp/udp2raw_amd64 /usr/local/bin/udp2raw
        chmod +x /usr/local/bin/udp2raw
    fi

    read -p "Enter Stealth Port (default 443): " USER_PORT
    STEALTH_PORT=${USER_PORT:-$STEALTH_PORT}
    read -p "Enter Stealth Password (default mypassword123): " USER_PASS
    STEALTH_PASS=${USER_PASS:-$STEALTH_PASS}

    # Start udp2raw in background
    nohup udp2raw -s -l 0.0.0.0:$STEALTH_PORT -r 127.0.0.1:$WG_PORT -k "$STEALTH_PASS" --raw-mode faketcp > /var/log/udp2raw.log 2>&1 &
    
    echo -e "${GREEN}Stealth Mode started on port $STEALTH_PORT!${NC}"
    echo -e "Traffic is now obfuscated as FakeTCP."
}

uninstall_wg() {
    read -p "Are you sure you want to uninstall WireGuard? [y/N]: " CONFIRM
    if [[ $CONFIRM == "y" || $CONFIRM == "Y" ]]; then
        systemctl stop wg-quick@wg0
        systemctl disable wg-quick@wg0
        pkill udp2raw &> /dev/null
        rm -rf $WG_DIR
        rm /etc/sysctl.d/99-wireguard.conf
        rm /etc/sysctl.d/99-wg-performance.conf &> /dev/null
        rm /usr/local/bin/udp2raw &> /dev/null
        echo -e "${GREEN}WireGuard has been uninstalled.${NC}"
    fi
}

# --- Menu ---

show_menu() {
    echo -e "\n${GREEN}--- WireGuard Manager (v2.2) ---${NC}"
    echo "1) Install WireGuard"
    echo "2) Add New Client"
    echo "3) List Clients"
    echo "4) Monitor Connections"
    echo "5) Run Speed Test"
    echo "6) Apply Performance Tuning"
    echo "7) Toggle Stealth Mode (Obfuscation)"
    echo "8) Uninstall WireGuard"
    echo "9) Exit"
    read -p "Select an option [1-9]: " OPTION
}

# --- Main ---
check_root
detect_os

if [[ ! -d $WG_DIR ]]; then
    install_wg
    add_client
else
    while true; do
        show_menu
        case $OPTION in
            1) echo -e "${YELLOW}Already installed.${NC}" ;;
            2) add_client ;;
            3) list_clients ;;
            4) monitor_connections ;;
            5) run_speedtest ;;
            6) apply_performance_tuning ;;
            7) setup_stealth_mode ;;
            8) uninstall_wg; exit 0 ;;
            9) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
fi
