#!/bin/bash

# WireGuard Auto-Installer Script
# This script automates the installation and configuration of WireGuard VPN server.

# --- Configuration Variables (can be customized) ---
WG_PORT="51820"
WG_PROTOCOL="udp" # WireGuard primarily uses UDP
WG_AES_ENCRYPTION_NOTE="WireGuard uses ChaCha20-Poly1305 for encryption, not AES. This script will use WireGuard's default strong cryptography."

# --- Functions ---

# Function to detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
        VERSION_ID=$(grep -oE '[0-9.]+' /etc/redhat-release | cut -d. -f1)
    else
        echo "Unsupported operating system. Exiting."
        exit 1
    fi
    echo "Detected OS: $OS $VERSION_ID"
}

# Function to install WireGuard
install_wireguard() {
    echo "Installing WireGuard on $OS..."
    case $OS in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y wireguard qrencode
            ;;
        centos|fedora)
            sudo dnf install -y epel-release
            sudo dnf install -y wireguard-tools qrencode
            ;;
        *)
            echo "WireGuard installation not supported for $OS. Please install manually." # Placeholder for other OS
            exit 1
            ;;
    esac
    echo "WireGuard installed successfully."
}

# Function to generate server and client configurations
generate_configs() {
    echo "Generating WireGuard configurations..."

    # Generate server keys
    SERVER_PRIVKEY=$(wg genkey)
    SERVER_PUBKEY=$(echo "$SERVER_PRIVKEY" | wg pubkey)

    # Generate client keys
    CLIENT_PRIVKEY=$(wg genkey)
    CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)

    # Get server's public IP
    SERVER_EXTERNAL_IP=$(curl -s ifconfig.me)
    if [ -z "$SERVER_EXTERNAL_IP" ]; then
        SERVER_EXTERNAL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
    fi

    # Create server configuration
    SERVER_CONFIG="[Interface]
PrivateKey = $SERVER_PRIVKEY
Address = 10.0.0.1/24
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; iptables -A FORWARD -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; iptables -D FORWARD -o wg0 -j ACCEPT

[Peer]
PublicKey = $CLIENT_PUBKEY
AllowedIPs = 10.0.0.2/32"

    echo "$SERVER_CONFIG" | sudo tee /etc/wireguard/wg0.conf > /dev/null
    sudo chmod 600 /etc/wireguard/wg0.conf

    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo sysctl -p

    # Start WireGuard
    sudo systemctl enable wg-quick@wg0
    sudo systemctl start wg-quick@wg0

    echo "Server configuration created at /etc/wireguard/wg0.conf"

    # Create client configuration
    CLIENT_CONFIG="[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = 10.0.0.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $SERVER_EXTERNAL_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0, ::/0"

    echo "Client configuration (client.conf):"
    echo "$CLIENT_CONFIG"
    echo ""
    echo "QR Code for client configuration:"
    echo "$CLIENT_CONFIG" | qrencode -t ansiutf8
    echo ""
    echo "Please save the client.conf content and QR code to configure your client device."
}

# --- Main Script Execution ---
echo "Starting WireGuard Auto-Installer..."

detect_os
install_wireguard
generate_configs

echo "WireGuard setup complete!"
echo "Note on encryption: $WG_AES_ENCRYPTION_NOTE"
