#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

# ----------------------------------------------------------------------------
# Title:         ebusd LXC Installer for Proxmox
# Author:        Stephan Putzke
# License:       MIT
# Source:        https://github.com/stephan233/ebusd-proxmox-installer
# Description:   Installs and configures ebusd in an LXC container on Proxmox
# ----------------------------------------------------------------------------

set -e

# Colored output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

# === User input ===
echo -e "${YELLOW}🔧 Please enter the IP address of your eBus LAN adapter (e.g. 192.168.1.100):${NC}"
read -rp "Adapter IP: " EBUS_ADAPTER_IP

# === Configuration ===
CONFIG_DIR="/etc/ebusd"
REPO_URL="https://github.com/john30/ebusd-configuration.git"
BRANCH="master"
LOGFILE="/var/log/ebusd.log"

# === Install ebusd ===
echo -e "${GREEN}📦 Installing ebusd and Git...${NC}"
apt update
apt install -y ebusd git

# === Create logfile ===
touch "$LOGFILE"
chown ebusd:ebusd "$LOGFILE"

# === Set ebusd startup options ===
echo -e "${GREEN}⚙️ Configuring startup options...${NC}"
sed -i 's|^EBUSD_OPTS=.*|EBUSD_OPTS="-d '"$EBUS_ADAPTER_IP"':23 --scanconfig --latency=50 --loglevel=info --logfile='"$LOGFILE"'"|' /etc/default/ebusd

# === Download configuration files ===
echo -e "${GREEN}📥 Downloading configuration files (branch: $BRANCH)...${NC}"
TMP_DIR=$(mktemp -d)

git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"

# Backup existing config
if [ -d "$CONFIG_DIR" ]; then
    BACKUP_DIR="${CONFIG_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}🔁 Backing up existing configuration to $BACKUP_DIR${NC}"
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
fi

mkdir -p "$CONFIG_DIR"
cp -r "$TMP_DIR"/ebusd* "$CONFIG_DIR/"
rm -rf "$TMP_DIR"
chown -R ebusd:ebusd "$CONFIG_DIR"

echo -e "${GREEN}✅ Configuration files installed to $CONFIG_DIR${NC}"

# === Enable and start service ===
echo -e "${GREEN}🚀 Enabling and starting ebusd...${NC}"
systemctl enable ebusd
systemctl restart ebusd

# === Show status ===
echo -e "${GREEN}📄 Service status:${NC}"
systemctl status ebusd --no-pager

echo -e "${YELLOW}ℹ️ View the log with: tail -f $LOGFILE${NC}"
