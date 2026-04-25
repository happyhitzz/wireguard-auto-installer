# 🚀 WireGuard Auto-Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This script provides a **streamlined and automated solution** for deploying a WireGuard VPN server on various Linux distributions. Get your secure VPN up and running with minimal effort!

## ✨ Features

*   **Operating System Detection:** 🐧 Automatically identifies and configures WireGuard for Ubuntu, Debian, CentOS, and Fedora.
*   **Customizable Port:** ⚙️ Easily specify your desired WireGuard listening port (default: `51820`).
*   **Secure Protocol:** 🛡️ Leverages WireGuard's efficient and secure UDP-based protocol.
*   **Cutting-Edge Encryption:** 🔒 Utilizes WireGuard's built-in, modern cryptographic suite (ChaCha20-Poly1305) for robust security.
*   **Effortless Client Configuration:** 📱 Generates client configuration files and convenient QR codes for quick setup on your devices.

## ⚡ Quick Start

Follow these simple steps to get your WireGuard VPN server installed:

1.  **Download the script:**
    ```bash
    wget https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh
    ```
2.  **Make the script executable:**
    ```bash
    chmod +x wireguard_installer.sh
    ```
3.  **Run the installer with superuser privileges:**
    ```bash
    sudo ./wireguard_installer.sh
    ```

    The script will guide you through the installation, configure your server, and display the client configuration along with a QR code in your terminal. Save these details to set up your client devices.

## ⚠️ Important Notes

*   **Firewall Configuration:** Ensure your server's firewall is configured to allow incoming UDP traffic on the chosen WireGuard port.
*   **Public IP Address:** The script attempts to automatically detect your server's public IP. Please verify its accuracy during the setup process.
*   **Encryption Details:** WireGuard exclusively uses ChaCha20-Poly1305 for symmetric encryption. It does not offer alternative ciphers like AES, as its design prioritizes a fixed, modern, and highly secure cryptographic standard.

## 📄 License

This project is proudly open-source and distributed under the [MIT License](https://opensource.org/licenses/MIT). See the `LICENSE` file for more details.

## 🤝 Contact & Support

Should you encounter any issues or have questions, feel free to reach out on Discord:

*   **Usagi#4255**
*   **Maajjins**

## ❓ Common Issues & Solutions

Here are some common problems users might encounter and their solutions:

### 1. VPN Client Cannot Connect
*   **Issue:** Your WireGuard client (phone, laptop) fails to connect to the VPN server.
*   **Solution:**
    *   **Firewall:** Ensure your server's firewall (e.g., `ufw`, `firewalld`) allows incoming UDP traffic on the WireGuard port (default `51820`). You might need to open the port: `sudo ufw allow 51820/udp` or `sudo firewall-cmd --add-port=51820/udp --permanent && sudo firewall-cmd --reload`.
    *   **Public IP:** Verify that the `Endpoint` IP address in your client configuration (`client.conf`) is the correct public IP of your server. If your server's IP changed, update the client configuration.
    *   **Server Status:** Check if the WireGuard service is running on your server: `sudo systemctl status wg-quick@wg0`.

### 2. No Internet Access After Connecting to VPN
*   **Issue:** The VPN client connects successfully, but you cannot access the internet.
*   **Solution:**
    *   **IP Forwarding:** Ensure IP forwarding is enabled on your server. The script attempts to enable it, but you can verify with `sysctl net.ipv4.ip_forward`. It should return `net.ipv4.ip_forward = 1`. If not, run `echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf && sudo sysctl -p`.
    *   **NAT Rules:** Confirm that the `PostUp` and `PostDown` rules in `/etc/wireguard/wg0.conf` are correctly configured for Network Address Translation (NAT). These rules allow traffic from the VPN to exit through your server's public interface.
    *   **DNS:** Check the DNS server configured in your client.conf. Try using public DNS servers like `8.8.8.8` (Google DNS) or `1.1.1.1` (Cloudflare DNS).

### 3. Script Fails to Install WireGuard
*   **Issue:** The script encounters an error during the WireGuard installation phase.
*   **Solution:**
    *   **Unsupported OS:** While the script supports major distributions, if you are on a less common Linux distribution, manual installation might be required. Refer to the [official WireGuard installation guide](https://www.wireguard.com/install/) for your specific OS.
    *   **Package Manager Issues:** Ensure your system's package manager (`apt`, `dnf`) is up-to-date and functional. Run `sudo apt update` or `sudo dnf update` before running the script.


## ☁️ Recommended Hosting Providers

For optimal performance and reliability when deploying your WireGuard VPN server, we recommend the following hosting providers:

*   **OVHcloud:** Known for their robust infrastructure, competitive pricing, and global data centers.
    *   [Visit OVHcloud](https://www.ovhcloud.com/)
*   **NFOservers:** A popular choice for gaming and high-performance applications, offering dedicated servers and low-latency networks.
    *   [Visit NFOservers](https://www.nfoservers.com/)
*   **Tempest Hosting:** Provides reliable and scalable hosting solutions, suitable for various VPN deployment needs.
    *   [Visit Tempest Hosting](https://tempest.host/)

These providers offer a range of services that can complement your WireGuard setup, ensuring a stable and fast VPN experience.
