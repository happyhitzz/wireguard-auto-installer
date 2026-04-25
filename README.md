# 🚀 WireGuard Zero-Config Auto-Installer (v4.0)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

The ultimate "Zero-Config" WireGuard deployment suite. Version 4.0 introduces the **Power User Suite**, featuring Telegram alerts, automated MTU optimization, and multi-hop relay support.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 📢 **Telegram Alerts** | Get instant notifications on your phone for new clients, expirations, and updates. |
| ⚡ **MTU Optimizer** | Automatically detects and applies the best MTU for your network to prevent fragmentation. |
| 🔗 **Multi-Hop Relay** | Easily configure your server to relay traffic to another WireGuard node. |
| 🔄 **Full Auto-Update** | Automatically keeps the script, AI module, and system dependencies updated. |
| 🤖 **AI Attack Detection** | Optional real-time log analysis to detect and alert on brute-force and handshake attacks. |
| 🛡️ **Anti-DDoS** | One-click **Blackhole Toggle** to drop malicious traffic and harden the network stack. |
| ⏳ **User Expiration** | Set access duration in days; users are automatically blocked upon expiry. |

---

## ⚡ Quick Start (No Config Needed)

Just run this single command on your server:

```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh && chmod +x wireguard_installer.sh && sudo ./wireguard_installer.sh
```

---

## 🎮 Management Menu (v4.0)

1. **Install WireGuard:** Fully automated setup.
2. **Add New Client:** Create peers with optional **Expiration Days**.
3. **List Clients:** See who is currently configured.
4. **Monitor Connections:** Real-time traffic dashboard.
5. **Run Speed Test:** Verify your VPN performance.
6. **Optimize Performance:** One-click kernel and network tuning.
7. **Optimize MTU:** Auto-detect the best MTU for your connection.
8. **Toggle Stealth Mode:** Bypass DPI and firewalls with one click.
9. **Toggle Anti-DDoS Blackhole:** Harden server against DDoS attacks.
10. **Toggle AI Attack Detector:** Enable/Disable optional AI-driven security monitoring.
11. **Setup Telegram Alerts:** Configure instant mobile notifications.
12. **Setup Multi-Hop Relay:** Chain your VPN to another server.
13. **Check for Updates Now:** Manually trigger a full system and script update.
14. **Uninstall:** Cleanly remove everything from your system.

---

## 📢 Power User Features

*   **Telegram Integration:** Stay informed anywhere. The script sends alerts for installation success, new client creation, and automated user blocking.
*   **MTU Auto-Detection:** No more manual MTU guessing. The script tests your network path to find the largest non-fragmented packet size.
*   **Multi-Hop Support:** Perfect for advanced privacy setups where you want to route your traffic through multiple VPN servers.

---

## ☁️ Recommended Hosting

*   [**OVHcloud**](https://www.ovhcloud.com/) - Global Enterprise Infrastructure.
*   [**NFOservers**](https://www.nfoservers.com/) - High-Performance Gaming Network.
*   [**Tempest Hosting**](https://tempest.net/) - Secure & Scalable Solutions.
*   [**100up.net**](https://100up.net/) - Speed-Focused Hosting.
*   [**Vultr**](https://www.vultr.com/) - High-Performance Cloud VPS.
*   [**BuyVM / Frantech**](https://buyvm.net/) - Unmetered Bandwidth & DDoS Protection.

---

## 🤝 Contact & Support

Discord: **Usagi#4255** or **Maajjins**

---

## 📄 License

Distributed under the [MIT License](https://opensource.org/licenses/MIT).
