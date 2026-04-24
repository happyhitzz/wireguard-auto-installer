# WireGuard Auto-Installer

This script automates the installation and configuration of a WireGuard VPN server on various Linux distributions. It sets up the server, generates client configurations, and provides a QR code for easy client setup.

## Features

*   **Operating System Detection:** Automatically detects and adapts installation steps for Ubuntu, Debian, CentOS, and Fedora.
*   **Customizable Port:** Allows selection of the WireGuard listening port (default: `51820`).
*   **Protocol:** WireGuard primarily uses UDP. This script configures it accordingly.
*   **Encryption:** WireGuard uses state-of-the-art cryptography (ChaCha20-Poly1305) by default. This script leverages WireGuard's built-in strong encryption, as AES is not directly used by WireGuard.
*   **Client Configuration:** Generates a client configuration file and a QR code for easy import on client devices.

## Usage

1.  **Download the script:**
    ```bash
    wget https://raw.githubusercontent.com/happyhitzz/bot/main/wireguard_installer.sh
    ```
2.  **Make the script executable:**
    ```bash
    chmod +x wireguard_installer.sh
    ```
3.  **Run the script:**
    ```bash
    sudo ./wireguard_installer.sh
    ```

    The script will guide you through the installation and configuration process. It will output the client configuration and a QR code to your terminal.

## Important Notes

*   **Firewall:** Ensure your server's firewall allows incoming UDP traffic on the chosen WireGuard port.
*   **Public IP:** The script attempts to auto-detect your server's public IP address. Verify its correctness.
*   **Encryption:** WireGuard uses ChaCha20-Poly1305 for encryption, which is a modern and secure cipher suite. It does not use AES directly.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For any issues or questions, please contact us on Discord:
*   **Usagi#4255**
*   **Maajjins**
