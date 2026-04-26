# Simple WireGuard Auto-Installer

This script provides a basic, zero-configuration installation of a WireGuard VPN server on Linux and generates a client configuration.

## ✨ Features

*   **Automated Installation:** Installs WireGuard and `qrencode`.
*   **Server Configuration:** Sets up the WireGuard server with basic networking and IP forwarding.
*   **Client Configuration:** Generates a client configuration file (`client_wg0.conf`) and displays a QR code for easy setup.

## 🚀 Quick Start

To install WireGuard and generate a client configuration, run the following command on your server:

```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh && chmod +x wireguard_installer.sh && sudo ./wireguard_installer.sh
```

After execution, your client configuration will be saved to `client_wg0.conf` in the current directory, and a QR code will be displayed in the terminal.

## ⚠️ Important Notes

*   This script is designed for a fresh installation on a clean server.
*   It assumes `eth0` as the primary network interface for `MASQUERADE` rules.
*   For advanced configurations or multiple clients, consider using a more feature-rich installer.

## 🤝 Contact

Discord: **Usagi#4255** or **Maajjins**
