terraform-infra/
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
│
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── README.md
│   ├── eks/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── README.md
│   ├── ec2/
│   ├── rds/
│   ├── s3/
│   ├── iam/
│   ├── kms/
│   ├── monitoring/
│   │   ├── prometheus.tf
│   │   ├── grafana.tf
│   └── security/
│       ├── aws_config.tf
│       ├── security_group.tf
│       └── config_rules.tf
│
├── shared/
│   └── providers.tf
│
├── scripts/
│   ├── bootstrap.sh
│   ├── deploy.sh
│   └── destroy.sh
│
├── .gitignore
├── README.md
└── terragrunt.hcl (optional) 
# Question: with the structure above, would you advice i keep all bash scripts in the scripts directory? and what is best practice? 

Best Practice: Yes, keep all bash scripts under a central scripts/ directory
This is recommended for the following reasons:

💡 Why it's a good idea:

Reason	Explanation
Organization	Keeps .tf modules clean and focused on infra logic only. Bash scripts belong elsewhere.
Reusability	You might reuse grafana_userdata.sh in different environments or modules. Keeping it in scripts/ avoids duplication.
Version control clarity	Easy to see and update your automation logic (like bootstrap scripts, userdata, custom provisioning).
Security/Scan separation	You can lint, scan, or sign the script folder separately.
CI/CD friendly	Centralizing helps your pipelines (GitHub Actions, GitLab CI, etc.) pick them up easily.


# Bonus: Automate Grafana Alerts for Dashboards
Each panel can have an alert section added. Here's a JSON example to add to your dashboard definitions:




            ┌────────────────────┐
            │   Your EC2 hosts   │
            │ tagged:app_servers │
            └────────┬───────────┘
                     │ port 9100 (Node Exporter)
          ┌──────────▼───────────┐
          │    Prometheus        │
          │ Discovers & scrapes  │
          └──────────┬───────────┘
                     │
          ┌──────────▼───────────┐
          │       Grafana        │
          │   Queries Prometheus │
          │  (e.g., via PromQL)  │
          └──────────┬───────────┘
                     │
               Dashboards


✅ 4. (Optional but Recommended) Install and Configure Alertmanager
Prometheus doesn't send alerts on its own—you need Alertmanager to receive, group, and route them (email, Slack, PagerDuty, etc.).


Great question — here's a clear breakdown of best practices depending on how you're structuring your Prometheus + Terraform + Ansible setup:

✅ Best Practice for Managing Prometheus Alert Rules
🔹 Use Ansible to Manage Alert Rules (Recommended)
Why:

Separation of concerns: Terraform handles infra; Ansible handles configuration.

Idempotency: Ansible ensures rules are applied exactly and safely.

Flexibility: Easier to update rules without rebuilding infrastructure.

Version control: Ansible roles make it easier to version, reuse, and validate alert logic.

Structure:

yaml
Copy
Edit
roles/
└── prometheus/
    ├── tasks/
    │   └── main.yml       # Includes the copy + reload task
    └── files/
        └── alert.rules.yml
yaml
Copy
Edit
# tasks/main.yml
- name: Copy Prometheus alert rules
  copy:
    src: alert.rules.yml
    dest: /etc/prometheus/alert.rules.yml
    owner: prometheus
    group: prometheus
    mode: '0644'

- name: Reload Prometheus
  systemd:
    name: prometheus
    state: restarted
    daemon_reload: yes
You can also template alert.rules.yml using Jinja2 if needed.


# Use ansible to configure grafana dashboards and data sources

# Wait for Grafana to be ready
echo '[INFO] Waiting for Grafana API to become available...'
for i in {1..30}; do
  if curl -s -f http://localhost:3000/api/health | jq -e '.version' > /dev/null; then
    echo '[SUCCESS] Grafana is healthy.'
    break
  fi
  echo "[INFO] Waiting for Grafana to be healthy... ($i/30)"
  sleep 5
done



# Define region and password parameter
region="us-east-1"  # Change to your region
GRAFANA_ADMIN_PASSWORD_PARAM="/grafana/admin/password"

# Retry helper
retry() {
  local n=0
  until [ "$n" -ge 5 ]; do
    "$@" && break || {
      n=$((n+1))
      echo "[WARN] Command failed. Retrying $n..."
      sleep 3
    }
  done
}

# Get Prometheus private IP
prometheus_host=$(retry aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=prometheus" "Name=instance-state-name,Values=running" \
  --region "$region" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)
echo "[INFO] Prometheus host: $prometheus_host"

# Get Grafana admin password
GRAFANA_ADMIN_PASSWORD=$(retry aws ssm get-parameter \
  --name "$GRAFANA_ADMIN_PASSWORD_PARAM" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

# Add Prometheus data source
echo '[INFO] Configuring Prometheus data source...'
curl -s -X POST "http://admin:${GRAFANA_ADMIN_PASSWORD}@localhost:3000/api/datasources" \
  -H "Content-Type: application/json" \
  -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://'"${prometheus_host}"':9090",
        "access": "proxy",
        "basicAuth": false
      }'

# Add CloudWatch data source
curl -s -X POST "http://admin:${GRAFANA_ADMIN_PASSWORD}@localhost:3000/api/datasources" \
  -H "Content-Type: application/json" \
  -d '{
        "name": "CloudWatch",
        "type": "cloudwatch",
        "access": "proxy",
        "jsonData": {
          "defaultRegion": "'"${region}"'"
        }
      }'

# Function to POST dashboards
post_dashboard() {
  local json="$1"
  echo "$json" | curl -s -X POST "http://admin:${GRAFANA_ADMIN_PASSWORD}@localhost:3000/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -d @-
}

# Post EC2 Dashboard
post_dashboard "$(cat <<EOF
{
  "dashboard": {
    "id": null,
    "uid": "ec2-dashboard",
    "title": "EC2 Monitoring",
    "timezone": "browser",
    "schemaVersion": 18,
    "version": 1,
    "panels": [
      {
        "type": "graph",
        "title": "CPU Utilization",
        "datasource": "CloudWatch",
        "targets": [{
          "region": "${region}",
          "namespace": "AWS/EC2",
          "metricName": "CPUUtilization",
          "statistics": ["Average"],
          "period": 300,
          "refId": "A"
        }],
        "gridPos": { "x": 0, "y": 0, "w": 24, "h": 8 }
      }
    ]
  },
  "overwrite": true
}
EOF
)"

# Post RDS Dashboard
post_dashboard "$(cat <<EOF
{
  "dashboard": {
    "id": null,
    "uid": "rds-dashboard",
    "title": "RDS Monitoring",
    "timezone": "browser",
    "schemaVersion": 18,
    "version": 1,
    "panels": [
      {
        "type": "graph",
        "title": "Database Connections",
        "datasource": "CloudWatch",
        "targets": [{
          "region": "${region}",
          "namespace": "AWS/RDS",
          "metricName": "DatabaseConnections",
          "statistics": ["Average"],
          "period": 300,
          "refId": "A"
        }],
        "gridPos": { "x": 0, "y": 0, "w": 24, "h": 8 }
      }
    ]
  },
  "overwrite": true
}
EOF
)"

# Post VPC Dashboard
post_dashboard "$(cat <<EOF
{
  "dashboard": {
    "id": null,
    "uid": "vpc-dashboard",
    "title": "VPC Flow Logs",
    "timezone": "browser",
    "schemaVersion": 18,
    "version": 1,
    "panels": [
      {
        "type": "stat",
        "title": "VPC Accepted Bytes",
        "datasource": "CloudWatch",
        "targets": [{
          "region": "${region}",
          "namespace": "AWS/VPC",
          "metricName": "Bytes",
          "dimensions": { "TrafficType": "ACCEPT" },
          "statistics": ["Sum"],
          "period": 300,
          "refId": "A"
        }],
        "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 }
      },
      {
        "type": "stat",
        "title": "VPC Rejected Bytes",
        "datasource": "CloudWatch",
        "targets": [{
          "region": "${region}",
          "namespace": "AWS/VPC",
          "metricName": "Bytes",
          "dimensions": { "TrafficType": "REJECT" },
          "statistics": ["Sum"],
          "period": 300,
          "refId": "B"
        }],
        "gridPos": { "x": 12, "y": 0, "w": 12, "h": 8 }
      }
    ]
  },
  "overwrite": true
}
EOF
)"

# Post App Metrics Dashboard
post_dashboard "$(cat <<EOF
{
  "dashboard": {
    "id": null,
    "uid": "app-metrics",
    "title": "App Metrics (Prometheus)",
    "timezone": "browser",
    "schemaVersion": 18,
    "version": 1,
    "panels": [
      {
        "type": "graph",
        "title": "HTTP Requests Per Second",
        "datasource": "Prometheus",
        "targets": [{
          "expr": "rate(http_requests_total[1m])",
          "legendFormat": "req/sec",
          "refId": "A"
        }],
        "gridPos": { "x": 0, "y": 0, "w": 24, "h": 8 }
      }
    ]
  },
  "overwrite": true
}
EOF
)"

# Import Kubernetes dashboards
echo '[INFO] Importing Kubernetes Dashboards...'
curl -s -X POST "http://admin:${GRAFANA_ADMIN_PASSWORD}@localhost:3000/api/dashboards/import" \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": { "id": 17119, "uid": null, "title": "Kubernetes EKS Cluster (Prometheus)", "tags": [], "timezone": "browser", "schemaVersion": 16, "version": 0 },
    "overwrite": true,
    "inputs": [{ "name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus" }]
  }'

curl -s -X POST "http://admin:${GRAFANA_ADMIN_PASSWORD}@localhost:3000/api/dashboards/import" \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": { "id": 16028, "uid": null, "title": "Kubernetes EKS Cluster (CloudWatch)", "tags": [], "timezone": "browser", "schemaVersion": 16, "version": 0 },
    "overwrite": true,
    "inputs": [{ "name": "DS_CLOUDWATCH", "type": "datasource", "pluginId": "cloudwatch", "value": "CloudWatch" }]
  }'

echo '[INFO] Grafana setup completed successfully.'
