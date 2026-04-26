#!/bin/bash

# Simple WireGuard Installer
# This script automates the installation of WireGuard and generates a client configuration.

# --- Configuration Variables ---
WG_NIC="wg0"
WG_PORT="51820"
WG_IPV4="10.0.0.1/24"
WG_CLIENT_IPV4="10.0.0.2/32"
WG_DNS="1.1.1.1"

# --- Functions ---

function install_wireguard() {
    echo "Installing WireGuard..."
    # Detect OS and install WireGuard
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        apt update && apt install -y wireguard qrencode
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS/Fedora
        yum install -y epel-release && yum install -y wireguard-tools qrencode
    else
        echo "Unsupported OS. Please install WireGuard manually." >&2
        exit 1
    fi
    echo "WireGuard installed successfully."
}

function generate_keys() {
    echo "Generating server and client keys..."
    SERVER_PRIVKEY=$(wg genkey)
    SERVER_PUBKEY=$(echo "$SERVER_PRIVKEY" | wg pubkey)
    CLIENT_PRIVKEY=$(wg genkey)
    CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)
    echo "Keys generated."
}

function configure_server() {
    echo "Configuring WireGuard server..."
    # Get public IP
    SERVER_PUB_IP=$(curl -s ifconfig.me)

    # Create server config
    cat <<EOF > /etc/wireguard/$WG_NIC.conf
[Interface]
PrivateKey = $SERVER_PRIVKEY
Address = $WG_IPV4
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i $WG_NIC -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_NIC -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUBKEY
AllowedIPs = $WG_CLIENT_IPV4
EOF

    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
    sysctl --system

    # Start WireGuard
    systemctl enable wg-quick@$WG_NIC
    systemctl start wg-quick@$WG_NIC
    echo "WireGuard server configured and started."
}

function generate_client_config() {
    echo "Generating client configuration..."
    cat <<EOF > client_wg0.conf
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $WG_CLIENT_IPV4
DNS = $WG_DNS

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $SERVER_PUB_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

    echo "Client configuration saved to client_wg0.conf"
    echo "QR Code for client_wg0.conf:"
    qrencode -t ansiutf8 < client_wg0.conf
}

# --- Main Script Execution ---

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

install_wireguard
generate_keys
configure_server
generate_client_config

echo "\nWireGuard installation complete!"
echo "Your client configuration is in client_wg0.conf and displayed as a QR code above."
echo "Use this file or QR code to connect your client device."
