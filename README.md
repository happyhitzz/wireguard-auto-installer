# 🚀 WireGuard Advanced Auto-Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

A powerful, all-in-one solution for deploying and managing a secure WireGuard VPN server. This script now features a full management menu for multi-client support, ad-blocking DNS, and more.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🐧 **OS Detection** | Automatically configures for Ubuntu, Debian, CentOS, and Fedora. |
| 👥 **Multi-Client** | Add, list, and manage multiple devices from a single menu. |
| 🛡️ **Ad-Blocking** | Optional **AdGuard DNS** integration to block ads and trackers. |
| ⚙️ **DNS Options** | Choose between Google, Cloudflare, or AdGuard DNS. |
| 📱 **QR Codes** | Instant QR code generation for mobile setup. |
| 🗑️ **Uninstaller** | Cleanly remove WireGuard and all configurations when needed. |

---

## 🛠️ System Requirements

| Requirement | Details |
| :--- | :--- |
| **Supported OS** | Ubuntu 20.04+, Debian 10+, CentOS 7+, Fedora 32+ |
| **Privileges** | Root or Sudo access required |
| **Tools** | `wget`, `curl`, `qrencode` (Script will help install these) |

---

## ⚡ Quick Start Guide

**1. Download the script:**
```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh
```

**2. Make it executable:**
```bash
chmod +x wireguard_installer.sh
```

**3. Run the manager:**
```bash
sudo ./wireguard_installer.sh
```

---

## 🎮 Management Menu

Once installed, running the script again will open the **WireGuard Manager**:
1. **Install WireGuard:** Initial setup.
2. **Add New Client:** Create a new peer with custom DNS and QR code.
3. **List Clients:** See all currently configured devices.
4. **Uninstall:** Completely remove the VPN from your system.

---

## ⚠️ Important Considerations

*   **Firewall:** Ensure UDP port `51820` is open on your server's firewall.
*   **Public IP:** The script auto-detects your IP; verify it during setup.
*   **Encryption:** Uses industry-standard **ChaCha20-Poly1305** for maximum security.

---

## ❓ Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **No Connection** | Check if UDP port `51820` is open: `sudo ufw allow 51820/udp` |
| **No Internet** | Verify IP forwarding: `sysctl net.ipv4.ip_forward` should be `1`. |
| **DNS Issues** | Try switching to Google (8.8.8.8) or Cloudflare (1.1.1.1) in the client config. |

---

## ☁️ Recommended Hosting

*   [**OVHcloud**](https://www.ovhcloud.com/) - Global reliability.
*   [**NFOservers**](https://www.nfoservers.com/) - Low-latency gaming focus.
*   [**Tempest Hosting**](https://tempest.net/) - Scalable and secure.
*   [**100up.net**](https://100up.net/) - High-performance speed and reliability.
*   [**Vultr**](https://www.vultr.com/) - Global cloud platform with high-performance SSD VPS.
*   [**BuyVM / Frantech**](https://buyvm.net/) - Known for unmetered bandwidth and excellent DDoS protection.

---

## 🤝 Contact & Support

Discord: **Usagi#4255** or **Maajjins**

---

## 📄 License

Distributed under the [MIT License](https://opensource.org/licenses/MIT).
