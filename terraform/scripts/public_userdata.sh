#!/bin/bash
set -euxo pipefail

echo "[INFO] Installing Docker..."

# Install Docker
dnf update -y
dnf install -y docker

# Enable and start Docker
systemctl enable --now docker

# Wait until Docker socket is ready
timeout 30 bash -c 'until docker info >/dev/null 2>&1; do sleep 1; done'

# Run containers
docker pull httpd:latest
docker run -d --name apache-web -p 8080:80 httpd:latest

docker pull nginx:latest
docker run -d --name nginx-web -p 80:80 nginx:latest

echo "[INFO] Installing Node Exporter..."

# Create a user for Node Exporter
useradd --no-create-home --shell /bin/false node_exporter || true

# Download and install Node Exporter
cd /opt/
NODE_EXPORTER_VERSION="1.8.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xvzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service
cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload and start Node Exporter
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now node_exporter

echo "[INFO] All services installed and running."
