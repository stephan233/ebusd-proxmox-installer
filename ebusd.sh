#!/bin/bash
set -e

CONFIG_DIR="/etc/ebusd"
REPO_URL="https://github.com/john30/ebusd-configuration.git"
BRANCH="master"
LOGFILE="/var/log/ebusd.log"

echo "Updating package lists..."
apt update

echo "Installing dependencies..."
apt install -y wget git apt-transport-https ca-certificates

# Hole neueste Version von GitHub Releases via GitHub API
echo "Fetching latest ebusd release info from GitHub..."
LATEST_URL=$(curl -s https://api.github.com/repos/john30/ebusd/releases/latest \
  | grep "browser_download_url" \
  | grep "amd64.deb" \
  | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
  echo "ERROR: Could not find latest .deb release URL."
  exit 1
fi

echo "Downloading latest ebusd package..."
wget -q --show-progress "$LATEST_URL" -O /tmp/ebusd_latest.deb

echo "Installing ebusd package..."
dpkg -i /tmp/ebusd_latest.deb || apt-get install -f -y

echo "Cleaning up..."
rm /tmp/ebusd_latest.deb

# Erstelle logfile falls nicht vorhanden
touch "$LOGFILE"
chown ebusd:ebusd "$LOGFILE"

# Konfiguriere ebusd mit Adapter-IP
echo "Please enter the IP address of your eBus LAN adapter (e.g. 192.168.1.100):"
read -rp "Adapter IP: " EBUS_ADAPTER_IP

echo "Configuring ebusd startup options..."
sed -i "s|^EBUSD_OPTS=.*|EBUSD_OPTS=\"-d $EBUS_ADAPTER_IP:23 --scanconfig --latency=50 --loglevel=info --logfile=$LOGFILE\"|" /etc/default/ebusd

echo "Cloning configuration files from $REPO_URL (branch: $BRANCH)..."
TMP_DIR=$(mktemp -d)
git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"

if [ -d "$CONFIG_DIR" ]; then
  BACKUP_DIR="${CONFIG_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
  echo "Backing up existing config to $BACKUP_DIR"
  cp -r "$CONFIG_DIR" "$BACKUP_DIR"
fi

mkdir -p "$CONFIG_DIR"
cp -r "$TMP_DIR"/ebusd* "$CONFIG_DIR/"
rm -rf "$TMP_DIR"
chown -R ebusd:ebusd "$CONFIG_DIR"

echo "Enabling and restarting ebusd service..."
systemctl enable ebusd
systemctl restart ebusd

echo "Installation complete. Check status with:"
echo "  systemctl status ebusd --no-pager"
echo "View logs with:"
echo "  tail -f $LOGFILE"
