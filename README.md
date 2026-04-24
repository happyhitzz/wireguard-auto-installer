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
