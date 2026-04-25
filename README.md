# 🚀 WireGuard Advanced Auto-Installer (v2.2)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

A powerful, all-in-one solution for deploying and managing a secure WireGuard VPN server. Version 2.2 introduces **Stealth Mode**, an optional obfuscation layer to bypass strict firewalls and deep packet inspection (DPI).

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🐧 **OS Detection** | Automatically configures for Ubuntu, Debian, CentOS, and Fedora. |
| 👥 **Multi-Client** | Add, list, and manage multiple devices from a single menu. |
| 🛡️ **Ad-Blocking** | Optional **AdGuard DNS** integration to block ads and trackers. |
| 🕵️ **Stealth Mode** | Optional **udp2raw** obfuscation to bypass DPI and firewalls. |
| ⚡ **Performance Tuning** | Optional **GSO offloading**, **IRQ balancing**, and **BBR** congestion control. |
| 🔒 **Auto-Security** | Enables **Unattended Upgrades** for automatic OS security patches. |
| 📊 **Monitoring** | Real-time connection monitoring to see active peers and traffic. |
| 🚀 **Speed Test** | Built-in speed test utility to verify your VPN performance. |
| 📱 **QR Codes** | Instant QR code generation for mobile setup. |
| 🗑️ **Uninstaller** | Cleanly remove WireGuard and all configurations when needed. |

---

## 🛠️ System Requirements

| Requirement | Details |
| :--- | :--- |
| **Supported OS** | Ubuntu 20.04+, Debian 10+, CentOS 7+, Fedora 32+ |
| **Privileges** | Root or Sudo access required |
| **Tools** | `wget`, `curl`, `qrencode`, `ethtool`, `irqbalance`, `udp2raw` |

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

## 🎮 Management Menu (v2.2)

Once installed, running the script again will open the **WireGuard Manager**:
1. **Install WireGuard:** Initial setup.
2. **Add New Client:** Create a new peer with custom DNS and QR code.
3. **List Clients:** See all currently configured devices.
4. **Monitor Connections:** View real-time traffic and connection status.
5. **Run Speed Test:** Check your server's upload and download speeds.
6. **Apply Performance Tuning:** Optimize network stack (GSO, IRQ, BBR).
7. **Toggle Stealth Mode:** Enable/Disable **udp2raw** obfuscation.
8. **Uninstall:** Completely remove the VPN from your system.

---

## 🕵️ How Stealth Mode Works

Stealth Mode uses **udp2raw** to tunnel WireGuard's UDP traffic over a fake TCP connection. This makes your VPN traffic look like standard HTTPS (if using port 443), helping you bypass strict network restrictions.

**Client Setup for Stealth Mode:**
1. Enable Stealth Mode in the script menu.
2. On your client device, run the `udp2raw` client.
3. Update your WireGuard client config to point to `127.0.0.1` instead of the server's public IP.

---

## ⚠️ Important Considerations

*   **Firewall:** Ensure UDP port `51820` (standard) or your chosen Stealth Port (e.g., `443` TCP) is open.
*   **Performance Tuning:** Recommended for high-speed servers to reduce CPU overhead.
*   **Security:** Automated updates are enabled by default to keep your server patched.

---

## ❓ Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **No Connection** | Check if UDP port `51820` is open: `sudo ufw allow 51820/udp` |
| **Stealth Mode Fails** | Ensure the Stealth Port (e.g., 443) is not being used by another service like Nginx. |
| **No Internet** | Verify IP forwarding: `sysctl net.ipv4.ip_forward` should be `1`. |

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
