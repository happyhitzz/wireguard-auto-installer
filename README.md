# 🚀 WireGuard Zero-Config Auto-Installer (v6.0) - ULTIMATE

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)

The ultimate "Zero-Config" WireGuard deployment suite. Version 6.0 introduces the **Ultimate Edition**, featuring Multi-Protocol support, Traffic Shaping (QoS), Advanced Analytics, and Automated Health Checks.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🚀 **Multi-Protocol** | Integrated support for **Shadowsocks** as an alternative stealth layer. |
| 🚦 **Traffic Shaping** | Advanced **QoS** to ensure fair bandwidth distribution among all clients. |
| 📊 **Advanced Analytics** | Detailed kernel-level logging and traffic analysis for power users. |
| 🏥 **Health Checks** | Automated 24/7 monitoring and self-healing for the WireGuard service. |
| 🛡️ **Hardened Security** | Fail2Ban, Port Knocking, and a Panic Button for maximum protection. |
| 🌐 **Web Dashboard** | Manage your VPN, clients, and traffic through a beautiful web interface. |
| 🌍 **Geo-IP Blocking** | Block entire countries from accessing your VPN server with a single command. |
| 🛡️ **AI Security Suite** | AI-driven DDoS protection and log-based attack detection. |

---

## ⚡ Quick Start (No Config Needed)

Just run this single command on your server:

```bash
wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh && chmod +x wireguard_installer.sh && sudo ./wireguard_installer.sh
```

---

## 🎮 Management Menu (v6.0)

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
16. **Setup Traffic Shaping (QoS):** Ensure fair bandwidth for all users.
17. **Setup Health Checks:** Enable automated self-healing and alerts.
18. **Setup Advanced Analytics:** Enable detailed traffic logging.
19. **Setup Multi-Protocol:** Add Shadowsocks for alternative obfuscation.
20. **Setup Telegram Alerts:** Configure instant mobile notifications.
21. **Setup Multi-Hop Relay:** Chain your VPN to another server.
22. **Run Cloud Backup Now:** Manually trigger a configuration backup.
23. **Check for Updates Now:** Manually trigger a full system and script update.
24. **PANIC BUTTON:** Instant server lockdown in case of emergency.
25. **Uninstall:** Cleanly remove everything from your system.

---

## 🛡️ Hardened Security Suite

*   **Fail2Ban:** Adds an extra layer of protection by monitoring logs and banning malicious actors who attempt to brute-force your server.
*   **Port Knocking:** Your WireGuard port remains "closed" to the public. You must "knock" on a specific sequence of ports (7000, 8000, 9000) to open it for your IP.
*   **Panic Button:** If you suspect your server is under heavy attack, the Panic Button instantly drops all incoming and outgoing traffic, preserving only your current SSH connection.

---

## ☁️ Recommended Hosting (DDoS Protected)

For the best experience and maximum uptime, we recommend hosting your WireGuard server with providers that offer robust, enterprise-grade DDoS protection.

| Provider | Protection Type | Best For |
| :--- | :--- | :--- |
| [**Tempest Hosting**](https://tempest.net/) | **Path.net / Cosmic Guard** | Ultimate DDoS Protection & Low Latency. |
| [**BuyVM / Frantech**](https://buyvm.net/) | **Stallion / Anycast** | Unmetered Bandwidth & High-Volume Traffic. |
| [**OVHcloud**](https://www.ovhcloud.com/) | **VAC (Proprietary)** | Global Infrastructure & Enterprise Reliability. |
| [**NFOservers**](https://www.nfoservers.com/) | **Custom In-House** | Gaming-Grade Network & Low Jitter. |
| [**Evolution Host**](https://evolution-host.com/) | **EvoShield** | Advanced Layer 3, 4, and 7 Mitigation. |
| [**Path.net**](https://path.net/) | **Direct Infrastructure** | Direct access to world-class DDoS filtering. |
| [**100up.net**](https://100up.net/) | **Premium Filtering** | Speed-Focused Hosting with Security. |
| [**Vultr**](https://www.vultr.com/) | **Cloud Mitigation** | High-Performance Cloud VPS with global reach. |
| [**Kamatera**](https://www.kamatera.com/) | **Enterprise Cloud** | Scalable resources with built-in security. |
| [**Hostinger**](https://www.hostinger.com/) | **Wanguard** | Budget-friendly with solid protection. |
| [**IONOS**](https://www.ionos.com/) | **Proprietary** | Scalable resources and reliable infrastructure. |
| [**AvenaCloud**](https://avenacloud.com/) | **Advanced Mitigation** | High-performance VPS with built-in security. |
| [**Sparked Host**](https://sparkedhost.com/) | **Enterprise Grade** | Game-server grade DDoS protection. |
| [**RubyHost**](https://rubyhost.com/) | **NeoProtect** | Specialized DDoS protection for high-risk apps. |
| [**Daydream Host**](https://daydreamhost.com/) | **Premium KVM** | High-performance VPS with unmetered NVMe. |
| [**VelocityHost**](https://velocityhost.com/) | **Advanced Protection** | High-performance hosting for game servers and VPS. |
| [**Hybrid Hosting**](https://hybridhosting.com/) | **Cosmic Guard** | Advanced protection via custom management interface. |
| [**Ateex Cloud**](https://ateex.cloud/) | **Path.net / Cosmic Guard** | Premium protection included at no extra cost. |

---

## 🤝 Contact & Support

Discord: **Usagi#4255** or **Maajjins**

---

## 📄 License

Distributed under the [MIT License](https://opensource.org/licenses/MIT).
