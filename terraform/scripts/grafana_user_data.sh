#!/bin/bash

set -euo pipefail
LOG_FILE=/var/log/grafana-init.log
exec > >(tee -a "$LOG_FILE") 2>&1

echo '[INFO] Starting Grafana installation...'

echo '[INFO] Updating system packages...'
dnf update -y

# Install necessary utilities
echo "[INFO] Installing utilities..."
dnf install -y wget jq


echo "[INFO] Adding Grafana yum repository..."
cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=Grafana OSS
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
EOF

dnf install -y grafana

# Start and enable Grafana
systemctl daemon-reexec
systemctl enable --now grafana-server

