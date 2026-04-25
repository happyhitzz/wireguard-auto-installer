# 🚀 WireGuard Auto-Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

A streamlined, automated solution for deploying a secure WireGuard VPN server on various Linux distributions. Get your VPN up and running with minimal effort, complete with automatic client configuration and QR code generation.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🐧 **OS Detection** | Automatically identifies and configures for Ubuntu, Debian, CentOS, and Fedora. |
| ⚙️ **Custom Port** | Easily specify your desired WireGuard listening port (default: `51820`). |
| 🛡️ **Secure Protocol** | Leverages WireGuard's efficient and secure UDP-based protocol. |
| 🔒 **Modern Encryption** | Utilizes WireGuard's built-in cryptographic suite (ChaCha20-Poly1305). |
| 📱 **Easy Client Setup** | Generates client configuration files and QR codes for instant mobile setup. |

---

## 🛠️ System Requirements

Before running the installer, ensure your system meets the following criteria:

### Supported Operating Systems
*   **Ubuntu:** 20.04 LTS or newer
*   **Debian:** 10 Buster or newer
*   **CentOS:** 7 or newer
*   **Fedora:** 32 or newer

### Required Utilities
The script requires `sudo` privileges and the following tools. If they are missing, use the commands below to install them:

| Utility | Purpose | Debian / Ubuntu Command | CentOS / Fedora Command |
| :--- | :--- | :--- | :--- |
| `wget` | Downloading the script | `sudo apt install -y wget` | `sudo dnf install -y wget` |
| `curl` | Detecting public IP | `sudo apt install -y curl` | `sudo dnf install -y curl` |
| `qrencode` | Generating QR codes | `sudo apt install -y qrencode` | `sudo dnf install -y qrencode` |

*(Note: `iptables` and `systemctl` are also required but are typically pre-installed on modern distributions.)*

---

## ⚡ Quick Start Guide

Follow these three simple steps to deploy your VPN:

**1. Download the script:**
```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh
```

**2. Make the script executable:**
```bash
chmod +x wireguard_installer.sh
```

**3. Run the installer:**
```bash
sudo ./wireguard_installer.sh
```

> **Note:** The script will guide you through the installation, configure your server, and display the client configuration along with a QR code in your terminal.

---

## ⚠️ Important Considerations

*   **Firewall Configuration:** You **must** configure your server's firewall to allow incoming UDP traffic on your chosen WireGuard port (default is `51820`).
*   **Public IP Address:** The script attempts to auto-detect your server's public IP. Please verify its accuracy during the setup process.
*   **Encryption Details:** WireGuard exclusively uses ChaCha20-Poly1305 for symmetric encryption. It does not offer alternative ciphers like AES, prioritizing a fixed, modern, and highly secure standard.

---

## ❓ Troubleshooting & Common Issues

| Issue | Potential Cause | Solution |
| :--- | :--- | :--- |
| **Client Cannot Connect** | Firewall blocking traffic | Ensure UDP port `51820` (or your custom port) is open. Example: `sudo ufw allow 51820/udp` |
| | Incorrect Endpoint IP | Verify the `Endpoint` IP in your `client.conf` matches your server's current public IP. |
| | Service not running | Check server status: `sudo systemctl status wg-quick@wg0` |
| **No Internet Access** | IP Forwarding disabled | Verify with `sysctl net.ipv4.ip_forward`. If not `1`, run: `echo "net.ipv4.ip_forward=1" \| sudo tee -a /etc/sysctl.conf && sudo sysctl -p` |
| | NAT Rules missing | Check `PostUp`/`PostDown` rules in `/etc/wireguard/wg0.conf`. |
| | DNS Issues | Try changing the DNS in `client.conf` to `8.8.8.8` or `1.1.1.1`. |
| **Installation Fails** | Unsupported OS | Refer to the [official WireGuard guide](https://www.wireguard.com/install/) for manual installation. |
| | Package Manager error | Run `sudo apt update` or `sudo dnf update` before running the script. |

---

## ☁️ Recommended Hosting Providers

For optimal performance and reliability, we recommend deploying your WireGuard server with one of these trusted providers:

*   [**OVHcloud**](https://www.ovhcloud.com/): Known for robust infrastructure, competitive pricing, and global data centers.
*   [**NFOservers**](https://www.nfoservers.com/): A popular choice for gaming and high-performance applications, offering low-latency networks.
*   [**Tempest Hosting**](https://tempest.host/): Provides reliable and scalable hosting solutions suitable for various VPN needs.

---

## 🤝 Contact & Support

Should you encounter any issues or have questions, feel free to reach out on Discord:

*   **Usagi#4255**
*   **Maajjins**

---

## 📄 License

This project is open-source and distributed under the [MIT License](https://opensource.org/licenses/MIT). See the `LICENSE` file for more details.
