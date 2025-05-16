# ebusd Proxmox Installer

This script installs and configures `ebusd` inside an LXC container on Proxmox VE.  
It automatically downloads the configuration files, sets up the service, and connects to a LAN-based eBus adapter.

## 📥 Installation

To install `ebusd` in a Debian-based LXC container, run:

```bash
bash <(curl -s https://raw.githubusercontent.com/stephan233/ebusd-proxmox-installer/main/ebusd.sh)
