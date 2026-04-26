#!/bin/bash

# Fully Automated WireGuard Installer with Interactive Options
# This script automates WireGuard installation, server configuration, and client management.
# Version: 1.1 (Ad-Block & Advanced Features)

# --- Configuration Variables (Defaults) ---
WG_NIC="wg0"
DEFAULT_WG_PORT="51820"
DEFAULT_WG_IPV4="10.0.0.1/24"
DEFAULT_WG_DNS="1.1.1.1"
ADBLOCK_DNS="94.140.14.14" # AdGuard DNS as a lightweight ad-blocking option

# --- Colors for better output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Functions ---

function check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "${RED}This script must be run as root.${NC}" >&2
        exit 1
    fi
}

function detect_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
    elif [[ -f /etc/redhat-release ]]; then
        OS="redhat"
    else
        echo -e "${RED}Unsupported OS. Please install WireGuard manually.${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Detected OS: ${OS}${NC}"
}

function install_wireguard() {
    echo -e "${BLUE}Installing WireGuard and dependencies...${NC}"
    if [[ "$OS" == "debian" ]]; then
        apt update && apt install -y wireguard qrencode curl iptables
    elif [[ "$OS" == "redhat" ]]; then
        yum install -y epel-release && yum install -y wireguard-tools qrencode curl iptables
    fi
    echo -e "${GREEN}WireGuard and dependencies installed successfully.${NC}"
}

function get_public_ip() {
    SERVER_PUB_IP=$(curl -s ifconfig.me)
    if [[ -z "$SERVER_PUB_IP" ]]; then
        echo -e "${RED}Could not detect public IP. Please ensure curl is installed and working.${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Detected Public IP: ${SERVER_PUB_IP}${NC}"
}

function generate_keys() {
    echo -e "${BLUE}Generating server keys...${NC}"
    SERVER_PRIVKEY=$(wg genkey)
    SERVER_PUBKEY=$(echo "$SERVER_PRIVKEY" | wg pubkey)
    echo -e "${GREEN}Server keys generated.${NC}"
}

function configure_server() {
    echo -e "${BLUE}Configuring WireGuard server...${NC}"

    # Prompt for WireGuard Port
    read -p "Enter WireGuard listening port (default: $DEFAULT_WG_PORT): " WG_PORT
    WG_PORT=${WG_PORT:-$DEFAULT_WG_PORT}

    # Detect primary interface
    SERVER_NIC=$(ip route get 8.8.8.8 | awk -- '{printf $5}')

    # Create server config
    cat <<EOF > /etc/wireguard/$WG_NIC.conf
[Interface]
PrivateKey = $SERVER_PRIVKEY
Address = $DEFAULT_WG_IPV4
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i $WG_NIC -j ACCEPT; iptables -t nat -A POSTROUTING -o $SERVER_NIC -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_NIC -j ACCEPT; iptables -t nat -D POSTROUTING -o $SERVER_NIC -j MASQUERADE
EOF

    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
    sysctl --system

    # Start WireGuard
    systemctl enable wg-quick@$WG_NIC
    systemctl start wg-quick@$WG_NIC
    echo -e "${GREEN}WireGuard server configured and started on port ${WG_PORT}.${NC}"
}

function add_client() {
    echo -e "${BLUE}Adding a new WireGuard client...${NC}"

    read -p "Enter client name (e.g., 'phone', 'laptop'): " CLIENT_NAME
    if [[ -z "$CLIENT_NAME" ]]; then
        echo -e "${RED}Client name cannot be empty. Aborting.${NC}" >&2
        return 1
    fi

    # Generate client keys
    CLIENT_PRIVKEY=$(wg genkey)
    CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)

    # Determine next available client IP
    LAST_IP=$(grep "AllowedIPs" /etc/wireguard/$WG_NIC.conf | tail -1 | awk -F'[./]' '{print $4}')
    if [[ -z "$LAST_IP" ]]; then
        CLIENT_IPV4="10.0.0.2/32"
    else
        CLIENT_IPV4="10.0.0.$((LAST_IP + 1))/32"
    fi

    # Feature Options
    echo -e "\n${BLUE}--- Client Options ---${NC}"
    echo -e "1) Standard DNS (Cloudflare: 1.1.1.1)"
    echo -e "2) Ad-Blocking DNS (AdGuard: 94.140.14.14)"
    echo -e "3) Custom DNS"
    read -p "Choose DNS option (default: 1): " DNS_CHOICE
    DNS_CHOICE=${DNS_CHOICE:-1}

    case $DNS_CHOICE in
        1) WG_DNS="1.1.1.1" ;;
        2) WG_DNS="$ADBLOCK_DNS" ;;
        3) read -p "Enter custom DNS: " WG_DNS ;;
        *) WG_DNS="1.1.1.1" ;;
    esac

    # Add client to server config
    cat <<EOF >> /etc/wireguard/$WG_NIC.conf

[Peer]
# Client Name: $CLIENT_NAME
PublicKey = $CLIENT_PUBKEY
AllowedIPs = $CLIENT_IPV4
EOF

    # Restart WireGuard to apply changes
    systemctl restart wg-quick@$WG_NIC

    # Generate client config file
    CLIENT_CONFIG_FILE="${CLIENT_NAME}_wg0.conf"
    WG_PORT=$(grep "ListenPort" /etc/wireguard/$WG_NIC.conf | awk '{print $3}')
    
    cat <<EOF > "$CLIENT_CONFIG_FILE"
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IPV4
DNS = $WG_DNS

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $SERVER_PUB_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

    echo -e "${GREEN}Client '${CLIENT_NAME}' added successfully!${NC}"
    echo -e "${YELLOW}Client configuration saved to '${CLIENT_CONFIG_FILE}'${NC}"
    echo -e "${BLUE}QR Code for '${CLIENT_CONFIG_FILE}':${NC}"
    qrencode -t ansiutf8 < "$CLIENT_CONFIG_FILE"
}

function remove_client() {
    echo -e "${BLUE}Removing a WireGuard client...${NC}"
    # List current clients
    echo -e "${YELLOW}Current Clients:${NC}"
    grep "# Client Name:" /etc/wireguard/$WG_NIC.conf | sed 's/# Client Name: //'

    read -p "Enter the name of the client to remove: " CLIENT_TO_REMOVE
    if [[ -z "$CLIENT_TO_REMOVE" ]]; then
        echo -e "${RED}Client name cannot be empty. Aborting.${NC}" >&2
        return 1
    fi

    # Remove client from server config
    sed -i "/Client Name: ${CLIENT_TO_REMOVE}/,/^$/d" /etc/wireguard/$WG_NIC.conf

    # Restart WireGuard
    systemctl restart wg-quick@$WG_NIC
    echo -e "${GREEN}Client '${CLIENT_TO_REMOVE}' removed successfully.${NC}"
}

function show_menu() {
    echo -e "\n${BLUE}--- WireGuard Management Menu ---${NC}"
    echo -e "${YELLOW}1) Add New Client (with Ad-Block option)${NC}"
    echo -e "${YELLOW}2) Remove Client${NC}"
    echo -e "${YELLOW}3) Show All Client Configs (QR Codes)${NC}"
    echo -e "${YELLOW}4) Exit${NC}"
    read -p "Choose an option: " OPTION

    case $OPTION in
        1)
            add_client
            ;;
        2)
            remove_client
            ;;
        3)
            echo -e "${BLUE}Showing all client configurations:${NC}"
            for CLIENT_FILE in *_wg0.conf; do
                if [[ -f "$CLIENT_FILE" ]]; then
                    echo -e "\n${YELLOW}--- ${CLIENT_FILE} ---${NC}"
                    qrencode -t ansiutf8 < "$CLIENT_FILE"
                fi
            done
            ;;
        4)
            echo -e "${GREEN}Exiting WireGuard Management. Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
}

# --- Main Script Execution ---

check_root
detect_os
get_public_ip

# Check if WireGuard is already installed and configured
if [[ -f /etc/wireguard/$WG_NIC.conf ]]; then
    echo -e "${YELLOW}WireGuard appears to be already installed and configured.${NC}"
    echo -e "${YELLOW}Entering management mode...${NC}"
    while true; do
        show_menu
    done
else
    install_wireguard
    generate_keys
    configure_server
    add_client # Add first client after initial setup
    echo -e "\n${GREEN}WireGuard initial setup complete!${NC}"
    echo -e "${YELLOW}Entering management mode...${NC}"
    while true; do
        show_menu
    done
fi
