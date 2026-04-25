# 🚀 WireGuard Zero-Config Auto-Installer (v6.1) - FULL CONTROL

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

The ultimate "Zero-Config" WireGuard deployment suite. Version 6.1 introduces **Full Control**, allowing you to toggle (ON/OFF) every single advanced feature directly from the management menu.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🔄 **Full Toggle Support** | Every feature (MTU, AI, QoS, etc.) can now be turned ON or OFF with one click. |
| 🚀 **Multi-Protocol** | Integrated support for **Shadowsocks** as an alternative stealth layer. |
| 🚦 **Traffic Shaping** | Advanced **QoS** to ensure fair bandwidth distribution among all clients. |
| 📊 **Advanced Analytics** | Detailed kernel-level logging and traffic analysis for power users. |
| 🏥 **Health Checks** | Automated 24/7 monitoring and self-healing for the WireGuard service. |
| 🛡️ **Hardened Security** | Fail2Ban, Port Knocking, and a Panic Button for maximum protection. |
| 🌐 **Web Dashboard** | Manage your VPN, clients, and traffic through a beautiful web interface. |
| 🛡️ **AI Security Suite** | AI-driven DDoS protection and log-based attack detection. |

---

## ⚡ Quick Start (No Config Needed)

Just run this single command on your server:

```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh && chmod +x wireguard_installer.sh && sudo ./wireguard_installer.sh
```

---

## 🎮 Management Menu (v6.1)

The new menu displays the current status (**[ON]** or **[OFF]**) for all toggleable features:

1. **Install WireGuard:** Fully automated setup.
2. **Add New Client:** Create peers with optional **Expiration Days**.
3. **List Clients:** See who is currently configured.
4. **Monitor Connections:** Real-time traffic dashboard.
5. **Run Speed Test:** Verify your VPN performance.
6. **Toggle Performance Tuning:** [ON/OFF] Kernel and network optimizations.
7. **Toggle Auto-MTU Optimizer:** [ON/OFF] Automatically detect and apply best MTU.
8. **Toggle Stealth Mode:** [ON/OFF] Bypass DPI and firewalls.
9. **Toggle Anti-DDoS Blackhole:** [ON/OFF] Harden server against DDoS attacks.
10. **Toggle AI Attack Detector:** [ON/OFF] Log-based security monitoring.
11. **Toggle AI DDoS Shield:** [ON/OFF] Traffic-based anomaly protection.
12. **Toggle Web Dashboard:** [ON/OFF] Browser-based management UI.
13. **Toggle Geo-IP Blocking:** [ON/OFF] Block traffic from specific countries.
14. **Toggle Fail2Ban:** [ON/OFF] Protect SSH and VPN from brute-force.
15. **Toggle Port Knocking:** [ON/OFF] Hide your VPN port from scanners.
16. **Toggle Traffic Shaping (QoS):** [ON/OFF] Ensure fair bandwidth for all users.
17. **Toggle Health Checks:** [ON/OFF] Automated self-healing and alerts.
18. **Toggle Advanced Analytics:** [ON/OFF] Detailed traffic logging.
19. **Toggle Multi-Protocol:** [ON/OFF] Add Shadowsocks for alternative obfuscation.
20. **Setup Telegram Alerts:** Configure instant mobile notifications.
21. **Setup Multi-Hop Relay:** Chain your VPN to another server.
22. **Run Cloud Backup Now:** Manually trigger a configuration backup.
23. **Check for Updates Now:** Manually trigger a full system and script update.
24. **PANIC BUTTON:** Instant server lockdown in case of emergency.
25. **Uninstall:** Cleanly remove everything from your system.

---

## 🔄 Full Control Capabilities

*   **Granular Management:** Don't like a feature? Turn it off. Want to test performance? Toggle the MTU optimizer or QoS and run a speed test.
*   **Status Visibility:** The management menu now acts as a dashboard, showing you exactly which security and performance layers are active at a glance.
*   **Zero-Risk Testing:** Safely experiment with advanced features like Port Knocking or Stealth Mode, knowing you can revert the changes instantly if needed.

---

## ☁️ Recommended Hosting (DDoS Protected)

| Provider | Protection Type | Best For |
| :--- | :--- | :--- |
| [**Tempest Hosting**](https://tempest.net/) | **Path.net / Cosmic Guard** | Ultimate DDoS Protection & Low Latency. |
| [**BuyVM / Frantech**](https://buyvm.net/) | **Stallion / Anycast** | Unmetered Bandwidth & High-Volume Traffic. |
| [**OVHcloud**](https://www.ovhcloud.com/) | **VAC (Proprietary)** | Global Infrastructure & Enterprise Reliability. |
| [**NFOservers**](https://www.nfoservers.com/) | **Custom In-House** | Gaming-Grade Network & Low Jitter. |
| [**Evolution Host**](https://evolution-host.com/) | **EvoShield** | Advanced Layer 3, 4, and 7 Mitigation. |

---

## 🤝 Contact & Support

Discord: **Usagi#4255** or **Maajjins**

---

## 📄 License

Distributed under the [MIT License](https://opensource.org/licenses/MIT).
