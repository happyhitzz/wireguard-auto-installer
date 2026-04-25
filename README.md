# 🚀 WireGuard Zero-Config Auto-Installer (v5.1) - HARDENED

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

The ultimate "Zero-Config" WireGuard deployment suite. Version 5.1 introduces the **Hardened Security Suite**, featuring Fail2Ban integration, Port Knocking, and a Panic Button for instant lockdown.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🛡️ **Fail2Ban Integration** | Automatically bans IPs that fail SSH or WireGuard handshakes multiple times. |
| 🚪 **Port Knocking** | Keeps your WireGuard port hidden from scanners until a specific sequence is sent. |
| 🚨 **Panic Button** | Instant server lockdown—blocks all traffic except your current SSH session. |
| 🌐 **Web Dashboard** | Manage your VPN, clients, and traffic through a beautiful web interface. |
| 🌍 **Geo-IP Blocking** | Block entire countries from accessing your VPN server with a single command. |
| 💾 **Cloud Backups** | Automated daily backups of your entire WireGuard configuration. |
| 🛡️ **AI DDoS Shield** | Adaptive traffic anomaly detection and automated mitigation. |

---

## ⚡ Quick Start (No Config Needed)

Just run this single command on your server:

```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh && chmod +x wireguard_installer.sh && sudo ./wireguard_installer.sh
```

---

## 🎮 Management Menu (v5.1)

1. **Install WireGuard:** Fully automated setup.
2. **Add New Client:** Create peers with optional **Expiration Days**.
3. **List Clients:** See who is currently configured.
4. **Monitor Connections:** Real-time traffic dashboard.
5. **Run Speed Test:** Verify your VPN performance.
6. **Optimize Performance:** One-click kernel and network tuning.
7. **Optimize MTU:** Auto-detect the best MTU for your connection.
8. **Toggle Stealth Mode:** Bypass DPI and firewalls with one click.
9. **Toggle Anti-DDoS Blackhole:** Harden server against DDoS attacks.
10. **Toggle AI Attack Detector:** Enable/Disable log-based security monitoring.
11. **Toggle AI DDoS Shield:** Enable/Disable traffic-based anomaly protection.
12. **Setup Web Dashboard:** Activate the browser-based management UI.
13. **Setup Geo-IP Blocking:** Block traffic from specific countries.
14. **Setup Fail2Ban:** Protect SSH and VPN from brute-force attacks.
15. **Setup Port Knocking:** Hide your VPN port from the public internet.
16. **Setup Telegram Alerts:** Configure instant mobile notifications.
17. **Setup Multi-Hop Relay:** Chain your VPN to another server.
18. **Run Cloud Backup Now:** Manually trigger a configuration backup.
19. **Check for Updates Now:** Manually trigger a full system and script update.
20. **PANIC BUTTON:** Instant server lockdown in case of emergency.
21. **Uninstall:** Cleanly remove everything from your system.

---

## 🛡️ Hardened Security Suite

*   **Fail2Ban:** Adds an extra layer of protection by monitoring logs and banning malicious actors who attempt to brute-force your server.
*   **Port Knocking:** Your WireGuard port remains "closed" to the public. You must "knock" on a specific sequence of ports (7000, 8000, 9000) to open it for your IP.
*   **Panic Button:** If you suspect your server is under heavy attack, the Panic Button instantly drops all incoming and outgoing traffic, preserving only your current SSH connection.

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
