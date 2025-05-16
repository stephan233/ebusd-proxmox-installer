#!/bin/bash

set -e

CTID=100
HOSTNAME="ebusd-container"
TEMPLATE="local:vztmpl/debian-11-standard_11.7-1_amd64.tar.gz"
MEMORY=1024
STORAGE="local-lvm"
ROOTFS_SIZE="8"
BRIDGE="vmbr0"
CONFIG_DIR="/etc/ebusd"
REPO_URL="https://github.com/john30/ebusd-configuration.git"
BRANCH="vaillant"
LOGFILE="/var/log/ebusd.log"

echo "🚀 Lade Debian 11 LXC Template herunter (falls nicht vorhanden)..."
if ! pct template | grep -q "debian-11-standard"; then
  pct download $CTID local debian-11-standard_11.7-1_amd64.tar.gz
fi

echo "📦 Erstelle LXC Container mit ID $CTID..."
pct create $CTID $TEMPLATE \
  --hostname $HOSTNAME \
  --memory $MEMORY \
  --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
  --rootfs $STORAGE:$ROOTFS_SIZE \
  --features nesting=1

echo "▶️ Starte Container $CTID..."
pct start $CTID

echo "🔧 Installiere ebusd und git im Container..."
pct exec $CTID -- bash -c "apt update && apt install -y ebusd git"

# eBus LAN Adapter IP abfragen
read -rp "🔧 Bitte die IP-Adresse deines eBus LAN Adapters eingeben (z.B. 192.168.1.100): " ADAPTER_IP

echo "⚙️ Konfiguriere ebusd im Container..."

# Setze ebusd Startoptionen im Container
pct exec $CTID -- bash -c "sed -i '/^EBUSD_OPTS=/d' /etc/default/ebusd"
pct exec $CTID -- bash -c "echo 'EBUSD_OPTS=\"-d $ADAPTER_IP:23 --scanconfig --latency=50 --loglevel=info --logfile=$LOGFILE\"' >> /etc/default/ebusd"

# Erstelle Logfile und setze Rechte
pct exec $CTID -- bash -c "touch $LOGFILE && chown ebusd:ebusd $LOGFILE"

echo "📥 Lade ebusd Konfigurationsdateien aus GitHub (Branch $BRANCH) in den Container..."

TMP_DIR="/tmp/ebusd_conf_$$"

pct exec $CTID -- bash -c "apt install -y git"

# Klone Repo, kopiere Config, bereinige
pct exec $CTID -- bash -c "rm -rf $TMP_DIR"
pct exec $CTID -- bash -c "git clone --depth=1 --branch $BRANCH $REPO_URL $TMP_DIR"
pct exec $CTID -- bash -c "mkdir -p $CONFIG_DIR"
pct exec $CTID -- bash -c "cp -r $TMP_DIR/ebusd* $CONFIG_DIR/"
pct exec $CTID -- bash -c "rm -rf $TMP_DIR"
pct exec $CTID -- bash -c "chown -R ebusd:ebusd $CONFIG_DIR"

echo "🔄 Starte ebusd Dienst neu im Container..."
pct exec $CTID -- systemctl restart ebusd

echo "✅ Fertig! D
