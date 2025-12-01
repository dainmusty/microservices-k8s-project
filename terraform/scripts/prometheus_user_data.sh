#!/bin/bash

set -euo pipefail

echo "[INFO] Installing Prometheus on Amazon Linux..."

# Install dependencies
yum install -y wget tar

# Create Prometheus user and directories
useradd --no-create-home --shell /bin/false prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Download Prometheus
PROM_VERSION="2.52.0"
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64

# Move Prometheus binaries and set ownership
cp prometheus promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Copy consoles and libraries, set ownership
cp -r consoles console_libraries /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus

# Write Prometheus configuration with EC2 service discovery
cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'app_servers'
    ec2_sd_configs:
      - region: us-east-1
        port: 9100
        filters:
          - name: "tag:Name"
            values: ["app_servers"]
    relabel_configs:
      - source_labels: [__meta_ec2_public_ip]   # change to private_ip when you are in a corperate network or production environment
        target_label: instance
      - source_labels: [__meta_ec2_public_ip]
        target_label: __address__
        replacement: \$1:9100
EOF

# Set ownership of the Prometheus config file
chown prometheus:prometheus /etc/prometheus/prometheus.yml


# Create Prometheus systemd service
cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus/ \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start Prometheus
systemctl daemon-reload
systemctl enable --now prometheus

echo "[INFO] Prometheus installed and running."


