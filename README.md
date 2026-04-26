# 🚀 WireGuard Automated Installer (v1.2) - Interactive Edition

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

This script provides a fully automated and interactive way to install and manage a WireGuard VPN server. It guides you through the setup process with clear prompts and handles all the technical configurations in the background.

---

## ✨ Features

*   **Fully Automated Installation:** Installs WireGuard and all necessary dependencies (qrencode, curl).
*   **Interactive Setup:** Asks for your preferred WireGuard port and DNS server during initial setup.
*   **🛡️ Ad-Blocking Options:** Choose between standard DNS, Ad-Blocking DNS (AdGuard), or custom DNS for each client.
*   **Advanced Client Management:**
    *   **Add New Client:** Easily create new client configurations with unique names and custom DNS settings.
    *   **Remove Client:** Permanently remove existing clients.
    *   **List All Clients:** View a summary of all clients, their IPs, and their current status (Enabled/Disabled).
    *   **Enable/Disable Client:** Temporarily revoke access for a client without deleting their configuration.
    *   **Server Status:** View real-time connection status, data usage, and latest handshakes.
*   **Automatic OS Detection:** Supports Debian/Ubuntu and CentOS/Fedora.
*   **Smart Interface Detection:** Automatically detects the primary network interface for firewall rules.
*   **Public IP Detection:** Automatically detects your server's public IP address.
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
3.  The server will be configured, and you'll be asked to add your first client.
4.  **New in v1.1:** You can now select **Ad-Blocking DNS** during client creation.
5.  A client configuration file (`<client_name>_wg0.conf`) and its QR code will be generated.

### Management Menu:

After the initial setup, or if WireGuard is already installed, the script will present an interactive management menu:

```
--- WireGuard Management Menu ---
1) Add New Client (with Ad-Block option)
2) Remove Client
3) List All Clients & Status
4) Enable/Disable Client
5) Show Server Status & Connections
6) Show All Client Configs (QR Codes)
7) Exit
Choose an option:
```

---

## 🛡️ Recommended Hosting (DDoS Protected)

For the best VPN experience, we recommend using hosting providers that offer robust, network-level DDoS protection to keep your server online.

| Provider | DDoS Protection | Best For |
| :--- | :--- | :--- |
| [**Hostinger**](https://www.hostinger.com/) | Advanced WAF & Network-level | Budget-friendly & High Performance |
| [**KnownHost**](https://www.knownhost.com/) | Enterprise-grade Imunify360 | Fully Managed & High Reliability |
| [**Contabo**](https://contabo.com/) | Always-on Network Protection | Best Price-to-Performance Ratio |
| [**Liquid Web**](https://www.liquidweb.com/) | Proactive Monitoring & Shield | Enterprise & Compliance Needs |
| [**Vultr**](https://www.vultr.com/) | Optional Advanced Mitigation | Global Reach & Developer Friendly |
| [**DigitalOcean**](https://www.digitalocean.com/) | Cloud-level Protection | Simplicity & Ease of Use |

---

## ⚠️ Important Notes

*   This script is designed for a fresh installation on a clean server.
*   It automatically detects your primary network interface (e.g., `eth0`, `ens3`) for `MASQUERADE` rules.

## 🤝 Contact

Discord: **Usagi#4255** or **Maajjins**

---

## 📄 License

Distributed under the [MIT License](https://opensource.org/licenses/MIT).
