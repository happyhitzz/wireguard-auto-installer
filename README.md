# WireGuard Automated Installer & Manager v3.0

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-88171A.svg)](https://www.wireguard.com/)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-Passing-brightgreen.svg)](https://www.shellcheck.net/)

A production-grade, fully automated WireGuard VPN installer and management tool for Linux servers. Supports dual-stack IPv4/IPv6, multiple interfaces, pre-shared keys, and comprehensive client lifecycle management — all from a single script.

---

## Features

### Core

- **One-command installation** — detects OS, installs packages, configures server, creates first client
- **Full IPv4 + IPv6 dual-stack** — every client gets both IPv4 and IPv6 addresses
- **Pre-shared keys (PSK)** — post-quantum resistance on every peer connection
- **Zero-downtime changes** — uses `wg syncconf` to apply peer changes without restarting the tunnel
- **Multi-interface support** — run multiple WireGuard instances (wg0, wg1, ...) on one server

### Security & Reliability

- **`set -euo pipefail`** — strict error handling; script fails fast on any error
- **Atomic config writes** — temporary file + `mv` prevents corruption on interruption
- **File locking (`flock`)** — prevents concurrent modifications from parallel runs
- **Signal trapping** — `SIGINT`, `SIGTERM`, `SIGHUP` caught with proper cleanup
- **Collision-free IP allocation** — bitmap-based tracking prevents IP conflicts even after client removal
- **Automatic backups** — config backed up before every destructive operation (last 10 retained)
- **Virtualization detection** — blocks unsupported environments (OpenVZ, LXC)

### Client Management

- **Add / Remove clients** — with validated names (alphanumeric, max 15 chars)
- **Enable / Disable clients** — temporarily revoke access without deleting
- **Regenerate configs** — re-key a client if their config is lost or compromised
- **QR code generation** — scan directly with the WireGuard mobile app
- **Export all configs** — tarball of all client configurations for backup
- **Per-client DNS selection** — choose from 7 DNS presets or enter custom

### Server Operations

- **Detailed status dashboard** — shows each peer's name, IP, last handshake, and bandwidth
- **Firewall integration** — automatically opens ports via `ufw`, `firewalld`, or raw `iptables`
- **MTU auto-detection** — calculates optimal MTU from interface settings
- **IP forwarding** — enables IPv4 + IPv6 forwarding with sysctl hardening
- **Self-update** — checks GitHub for new versions and updates in-place
- **Full uninstall** — removes packages, configs, firewall rules, and sysctl settings

### Automation

- **Non-interactive mode** (`--auto`) — fully scripted deployments with zero prompts
- **CLI flags** — `--port`, `--dns`, `--client`, `--interface` for customization
- **Structured logging** — all operations logged to `/var/log/wireguard-installer.log`

---

## Supported Operating Systems

| OS | Minimum Version |
|:---|:---|
| Ubuntu | 18.04+ |
| Debian | 10 (Buster)+ |
| Fedora | 32+ |
| CentOS / AlmaLinux / Rocky | 8+ |
| Arch Linux | Rolling |
| Alpine Linux | Latest |
| Oracle Linux | 8+ |

---

## Quick Start

### One-Line Install

```bash
wget -O wireguard_installer.sh https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh
chmod +x wireguard_installer.sh
sudo ./wireguard_installer.sh
```

Or with curl:

```bash
curl -O https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh
chmod +x wireguard_installer.sh
sudo ./wireguard_installer.sh
```

### Automated (Non-Interactive) Install

```bash
sudo ./wireguard_installer.sh --auto --port 51820 --client phone --dns 1.1.1.1
```

### Management Menu

After installation, run the script again to access the management interface:

```bash
sudo ./wireguard_installer.sh
```

```
╔══════════════════════════════════════════════════╗
║  WireGuard Manager v3.0  (wg0)                  ║
╠══════════════════════════════════════════════════╣
║                                                  ║
║   1) Add new client                              ║
║   2) Remove client                               ║
║   3) List clients & status                       ║
║   4) Enable/Disable client                       ║
║   5) Regenerate client config                    ║
║   6) Show all configs & QR codes                 ║
║   7) Server status & connections                 ║
║   8) Export all client configs                   ║
║   9) Switch/Create interface                     ║
║  10) Backup & Restore                            ║
║  11) Check for updates                           ║
║  12) Uninstall WireGuard                         ║
║  13) Exit                                        ║
║                                                  ║
╚══════════════════════════════════════════════════╝
```

---

## Command-Line Options

| Flag | Description | Default |
|:---|:---|:---|
| `--auto` | Non-interactive mode | Off |
| `--port PORT` | WireGuard listening port | Random (49152-65535) |
| `--dns IP` | DNS server for clients | 1.1.1.1 |
| `--client NAME` | First client name | Prompted |
| `--interface NAME` | WireGuard interface name | wg0 |
| `--version`, `-v` | Show version | — |
| `--help`, `-h` | Show help | — |

---

## DNS Presets

During client creation, choose from these built-in DNS options:

| # | Provider | Primary | Secondary | Notes |
|:---|:---|:---|:---|:---|
| 1 | Cloudflare | 1.1.1.1 | 1.0.0.1 | Fast, privacy-focused |
| 2 | Google | 8.8.8.8 | 8.8.4.4 | Reliable, global |
| 3 | Quad9 | 9.9.9.9 | 149.112.112.112 | Security-focused, blocks malware |
| 4 | AdGuard | 94.140.14.14 | 94.140.15.15 | Ad & tracker blocking |
| 5 | AdGuard Family | 94.140.14.15 | 94.140.15.16 | Ad + adult content blocking |
| 6 | OpenDNS | 208.67.222.222 | 208.67.220.220 | Cisco Umbrella |
| 7 | NextDNS | 45.90.28.167 | 45.90.30.167 | Customizable filtering |
| 8 | Custom | — | — | Enter any IP |

---

## File Structure

```
/etc/wireguard/
├── wg0.conf                    # Server configuration
├── params                      # Saved installation parameters
├── clients/
│   ├── wg0-client-phone.conf   # Client config files
│   ├── wg0-client-laptop.conf
│   └── ...
└── backups/
    ├── wg0_20260804_120000.conf
    └── ...

/var/log/wireguard-installer.log  # Operation log
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    WireGuard Server (wg0)                         │
│                                                                   │
│  IPv4: 10.66.66.1/24          IPv6: fd42:42:42::1/64            │
│  Port: 51820 (UDP)            MTU: Auto-detected                 │
│                                                                   │
│  PostUp:  iptables NAT + FORWARD + ip6tables                    │
│  PostDown: Cleanup all rules                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Client: phone                Client: laptop                     │
│  IPv4: 10.66.66.2/32          IPv4: 10.66.66.3/32               │
│  IPv6: fd42:42:42::2/128      IPv6: fd42:42:42::3/128           │
│  PSK: ✓                       PSK: ✓                             │
│  DNS: 1.1.1.1                 DNS: 94.140.14.14 (AdGuard)       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Recommended Hosting Providers

For optimal VPN performance, use providers with low latency and DDoS protection:

| Provider | DDoS Protection | Best For |
|:---|:---|:---|
| [Vultr](https://www.vultr.com/) | Optional Advanced | Global reach, developer-friendly |
| [DigitalOcean](https://www.digitalocean.com/) | Cloud-level | Simplicity, great docs |
| [Hetzner](https://www.hetzner.com/) | Included | European locations, best value |
| [Contabo](https://contabo.com/) | Always-on | Price-to-performance ratio |
| [Oracle Cloud](https://www.oracle.com/cloud/free/) | Included | Free tier (always free ARM) |
| [AWS Lightsail](https://aws.amazon.com/lightsail/) | AWS Shield | Enterprise reliability |

---

## Troubleshooting

### WireGuard won't start after installation

```bash
# Check if the kernel module is loaded
sudo modprobe wireguard

# If that fails, you may need to reboot after a kernel update
sudo reboot
```

### Client can't connect

1. Verify the server port is open: `sudo ss -ulnp | grep 51820`
2. Check firewall: `sudo ufw status` or `sudo firewall-cmd --list-all`
3. Verify IP forwarding: `sysctl net.ipv4.ip_forward`
4. Check WireGuard status: `sudo wg show`

### View logs

```bash
sudo tail -f /var/log/wireguard-installer.log
```

---

## Security Considerations

- All private keys are generated locally and never transmitted
- Config files are stored with `600` permissions (root-only readable)
- Pre-shared keys add symmetric encryption layer (post-quantum safe)
- The `/etc/wireguard/` directory is set to `700` permissions
- Backups retain sensitive keys — secure your server accordingly

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Ensure your code passes `shellcheck` with zero warnings
4. Submit a pull request

---

## Contact

Discord: **Usagi#4255** or **Maajjins**

---

## License

Distributed under the [MIT License](https://opensource.org/licenses/MIT).
