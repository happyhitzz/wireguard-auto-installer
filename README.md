# 🚀 WireGuard Automated Installer (v1.0) - Interactive Edition

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

This script provides a fully automated and interactive way to install and manage a WireGuard VPN server. It guides you through the setup process with clear prompts and handles all the technical configurations in the background.

---

## ✨ Features

*   **Fully Automated Installation:** Installs WireGuard and all necessary dependencies (qrencode, curl).
*   **Interactive Setup:** Asks for your preferred WireGuard port and DNS server during initial setup.
*   **Automatic OS Detection:** Supports Debian/Ubuntu and CentOS/Fedora.
*   **Public IP Detection:** Automatically detects your server's public IP address.
*   **Client Management Menu:**
    *   **Add New Client:** Easily create new client configurations with unique names and IP addresses.
    *   **Remove Client:** Remove existing clients from your WireGuard server.
    *   **Show All Client Configs:** View all generated client configurations and their QR codes.
*   **QR Code Generation:** Generates QR codes for client configurations for easy mobile setup.

---

## 🚀 Quick Start

To install WireGuard and manage your clients, run the following command on your server:

```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh && chmod +x wireguard_installer.sh && sudo ./wireguard_installer.sh
```

### First-Time Setup:

1.  The script will automatically detect your OS and public IP.
2.  You will be prompted to enter your desired WireGuard listening port (default: `51820`).
3.  The server will be configured, and you'll be asked to add your first client, including a client name and preferred DNS server.
4.  A client configuration file (`<client_name>_wg0.conf`) and its QR code will be generated.

### Management Menu:

After the initial setup, or if WireGuard is already installed, the script will present an interactive management menu:

```
--- WireGuard Management Menu ---
1) Add New Client
2) Remove Client
3) Show All Client Configs (QR Codes)
4) Exit
Choose an option:
```

Use this menu to easily manage your WireGuard clients.

## ⚠️ Important Notes

*   This script is designed for a fresh installation on a clean server.
*   It assumes `eth0` as the primary network interface for `MASQUERADE` rules. If your primary interface is different, you may need to manually adjust the `PostUp` and `PostDown` rules in `/etc/wireguard/wg0.conf`.

## 🤝 Contact

Discord: **Usagi#4255** or **Maajjins**

---

## 📄 License

Distributed under the [MIT License](https://opensource.org/licenses/MIT).
