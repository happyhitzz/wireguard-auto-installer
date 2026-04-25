#!/bin/bash

# =================================================================
# WireGuard Ultimate Auto-Installer (v3.0)
# =================================================================
# A comprehensive, high-performance VPN management suite.
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

# --- Core Logic ---

install_wg() {
    echo -e "${YELLOW}Installing WireGuard and essential tools...${NC}"
    case $OS in
        ubuntu|debian)
            apt update && apt install -y wireguard qrencode curl iptables unattended-upgrades ethtool irqbalance wget tar bc
            dpkg-reconfigure -plow unattended-upgrades
            ;;
        centos|fedora)
            dnf install -y epel-release
            dnf install -y wireguard-tools qrencode curl iptables dnf-automatic ethtool irqbalance wget tar bc
            sed -i 's/upgrade_type = default/upgrade_type = security/' /etc/dnf/automatic.conf
            systemctl enable --now dnf-automatic.timer
            ;;
    esac
    
    mkdir -p $WG_DIR
    chmod 700 $WG_DIR

    SERVER_PRIV=$(wg genkey)
    SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)
    echo "$SERVER_PRIV" > "$WG_DIR/server_private.key"
    echo "$SERVER_PUB" > "$WG_DIR/server_public.key"

    cat <<EOF > $WG_CONF
[Interface]
Address = 10.0.0.1/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIV
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; iptables -A FORWARD -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; iptables -D FORWARD -o wg0 -j ACCEPT
EOF

    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf

    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    echo -e "${GREEN}WireGuard installed and started!${NC}"
}

add_client() {
    echo -e "${YELLOW}Adding a new client...${NC}"
    read -p "Enter client name: " CLIENT_NAME
    
    LAST_IP=$(grep "AllowedIPs" $WG_CONF | tail -n1 | awk '{print $3}' | cut -d. -f4 | cut -d/ -f1)
    CLIENT_IP=$(( ${LAST_IP:-1} + 1 ))

    CLIENT_PRIV=$(wg genkey)
    CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
    
    echo -e "Select DNS Provider:"
    echo "1) Google (8.8.8.8)"
    echo "2) Cloudflare (1.1.1.1)"
    echo "3) AdGuard (Ad-Blocking)"
    echo "4) Quad9 (9.9.9.9)"
    read -p "Choice [1-4]: " DNS_CHOICE
    case $DNS_CHOICE in
        2) DNS="1.1.1.1" ;;
        3) DNS="94.140.14.14" ;;
        4) DNS="9.9.9.9" ;;
        *) DNS="8.8.8.8" ;;
    esac

    cat <<EOF >> $WG_CONF

[Peer]
# Client: $CLIENT_NAME
PublicKey = $CLIENT_PUB
AllowedIPs = 10.0.0.$CLIENT_IP/32
EOF

    wg addconf wg0 <(echo -e "[Peer]\nPublicKey = $CLIENT_PUB\nAllowedIPs = 10.0.0.$CLIENT_IP/32")

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

    echo -e "${GREEN}Client '$CLIENT_NAME' added! Config: $CLIENT_CONF_FILE${NC}"
    if pgrep -x "udp2raw" > /dev/null; then
        echo -e "${YELLOW}Stealth Mode is ACTIVE. Update Endpoint to 127.0.0.1:51820 and run udp2raw client.${NC}"
    fi
    qrencode -t ansiutf8 < "$CLIENT_CONF_FILE"
}

# --- Advanced Performance Tuning ---

apply_performance_tuning() {
    echo -e "${YELLOW}Applying Advanced Performance Optimizations...${NC}"
    
    # 1. Interface Tuning
    INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
    if [[ -n "$INTERFACE" ]]; then
        ethtool -K "$INTERFACE" gso off gro off tso off &> /dev/null
        ethtool -G "$INTERFACE" rx 4096 tx 4096 &> /dev/null
        echo -e "${GREEN}Interface $INTERFACE tuned (Offloading disabled, Ring buffers increased).${NC}"
    fi

    # 2. IRQ & CPU Pinning
    systemctl enable --now irqbalance &> /dev/null
    echo -e "${GREEN}IRQ Balance enabled for multi-core efficiency.${NC}"

    # 3. Advanced Kernel Network Stack
    cat <<EOF > /etc/sysctl.d/99-wg-ultimate.conf
# Memory buffers
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.optmem_max = 65536
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Congestion Control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0

# UDP Tuning
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# MTU Probing
net.ipv4.tcp_mtu_probing = 1
EOF
    sysctl -p /etc/sysctl.d/99-wg-ultimate.conf &> /dev/null
    echo -e "${GREEN}Kernel stack optimized with BBR and high-buffer limits.${NC}"
}

# --- Stealth & Security ---

setup_stealth_mode() {
    echo -e "${YELLOW}Toggling Stealth Mode (udp2raw)...${NC}"
    if pgrep -x "udp2raw" > /dev/null; then
        pkill udp2raw && echo -e "${GREEN}Stealth Mode stopped.${NC}"
    else
        if [[ ! -f /usr/local/bin/udp2raw ]]; then
            wget https://github.com/wangyu-/udp2raw/releases/download/20230206.0/udp2raw_binaries.tar.gz -O /tmp/udp2raw.tar.gz
            tar -xvf /tmp/udp2raw.tar.gz -C /tmp/ && cp /tmp/udp2raw_amd64 /usr/local/bin/udp2raw && chmod +x /usr/local/bin/udp2raw
        fi
        read -p "Stealth Port [443]: " USER_PORT
        read -p "Stealth Password: " USER_PASS
        nohup udp2raw -s -l 0.0.0.0:${USER_PORT:-443} -r 127.0.0.1:$WG_PORT -k "${USER_PASS:-mypassword123}" --raw-mode faketcp > /var/log/udp2raw.log 2>&1 &
        echo -e "${GREEN}Stealth Mode active on port ${USER_PORT:-443}.${NC}"
    fi
}

# --- Maintenance & Tools ---

monitor_connections() { watch -n 1 wg show; }

run_speedtest() {
    command -v speedtest-cli &> /dev/null || (apt install -y speedtest-cli || dnf install -y speedtest-cli)
    speedtest-cli
}

# --- Menu ---

show_menu() {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${BLUE}   WireGuard Ultimate Manager v3.0   ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo "1) Install WireGuard"
    echo "2) Add New Client"
    echo "3) List Clients"
    echo "4) Monitor Connections"
    echo "5) Run Speed Test"
    echo "6) Apply Performance Tuning (BBR, Buffers, IRQ)"
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
