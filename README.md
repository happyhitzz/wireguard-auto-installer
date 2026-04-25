# 🚀 WireGuard Zero-Config Auto-Installer (v3.3)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

The ultimate "Zero-Config" WireGuard deployment suite. Version 3.3 introduces **Anti-DDoS Blackhole Protection**, giving you a one-click toggle to harden your server against common network attacks.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🛡️ **Anti-DDoS** | One-click **Blackhole Toggle** to drop malicious traffic and harden the network stack. |
| ⏳ **User Expiration** | Set access duration in days; users are automatically blocked upon expiry. |
| 🤖 **Auto-Detection** | Automatically detects Public IP, Network Interface, and OS. |
| 🧙 **Setup Wizard** | Interactive prompts guide you through the entire process. |
| 📱 **Instant QR** | Scan a QR code on your phone to connect instantly. |
| 🕵️ **Stealth Mode** | One-click obfuscation to bypass strict firewalls (Port 443). |
| ⚡ **One-Click Tuning** | Instantly optimize your network stack for maximum speed. |

---

## ⚡ Quick Start (No Config Needed)

Just run this single command on your server:

```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh && chmod +x wireguard_installer.sh && sudo ./wireguard_installer.sh
```

---

## 🎮 Management Menu (v3.3)

1. **Install WireGuard:** Fully automated setup.
2. **Add New Client:** Create peers with optional **Expiration Days**.
3. **List Clients:** See who is currently configured.
4. **Monitor Connections:** Real-time traffic dashboard.
5. **Run Speed Test:** Verify your VPN performance.
6. **Optimize Performance:** One-click kernel and network tuning.
7. **Toggle Stealth Mode:** Bypass DPI and firewalls with one click.
8. **Toggle Anti-DDoS Blackhole:** Harden server against DDoS attacks.
9. **Check/Force Expiry:** Manually trigger the expiration check.
10. **Uninstall:** Cleanly remove everything from your system.

---

## 🛡️ How Anti-DDoS Blackhole Works

When enabled, the script applies several kernel-level protections:
*   **ICMP Drop:** Ignores all Ping requests to hide the server.
*   **TCP SYN Cookies:** Protects against SYN flood attacks.
*   **Spoofing Protection:** Enables strict reverse path filtering.
*   **Bogus Response Ignore:** Drops invalid network responses.
*   **Redirect Drop:** Prevents ICMP redirect attacks.

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
