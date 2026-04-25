# 🚀 WireGuard Zero-Config Auto-Installer (v3.5)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

The ultimate "Zero-Config" WireGuard deployment suite. Version 3.5 introduces **Full Auto-Update**, ensuring your script, AI security module, and system dependencies are always running the latest and most secure versions.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🔄 **Full Auto-Update** | Automatically keeps the script, AI module, and system dependencies updated. |
| 🤖 **AI Attack Detection** | Optional real-time log analysis to detect and alert on brute-force and handshake attacks. |
| 🛡️ **Anti-DDoS** | One-click **Blackhole Toggle** to drop malicious traffic and harden the network stack. |
| ⏳ **User Expiration** | Set access duration in days; users are automatically blocked upon expiry. |
| 🤖 **Auto-Detection** | Automatically detects Public IP, Network Interface, and OS. |
| 🧙 **Setup Wizard** | Interactive prompts guide you through the entire process. |
| 📱 **Instant QR** | Scan a QR code on your phone to connect instantly. |

---

## ⚡ Quick Start (No Config Needed)

Just run this single command on your server:

```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh && chmod +x wireguard_installer.sh && sudo ./wireguard_installer.sh
```

---

## 🎮 Management Menu (v3.5)

1. **Install WireGuard:** Fully automated setup.
2. **Add New Client:** Create peers with optional **Expiration Days**.
3. **List Clients:** See who is currently configured.
4. **Monitor Connections:** Real-time traffic dashboard.
5. **Run Speed Test:** Verify your VPN performance.
6. **Optimize Performance:** One-click kernel and network tuning.
7. **Toggle Stealth Mode:** Bypass DPI and firewalls with one click.
8. **Toggle Anti-DDoS Blackhole:** Harden server against DDoS attacks.
9. **Toggle AI Attack Detector:** Enable/Disable optional AI-driven security monitoring.
10. **Check for Updates Now:** Manually trigger a full system and script update.
11. **Uninstall:** Cleanly remove everything from your system.

---

## 🔄 How Auto-Update Works

The script implements a robust self-updating mechanism:
*   **Script Self-Update:** Checks for the latest version on GitHub and updates itself automatically.
*   **AI Module Update:** Keeps the AI attack detection script synchronized with the latest patterns.
*   **System Security:** Leverages `unattended-upgrades` or `dnf-automatic` for OS-level security patches.
*   **Scheduled Task:** A daily cron job ensures your server stays updated without manual intervention.

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
