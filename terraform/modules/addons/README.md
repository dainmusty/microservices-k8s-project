✅ EKS Addon Troubleshooting Summary
🧩 1. ArgoCD Setup & Debugging
Issues Faced:
Initial access and login password retrieval was non-obvious.

Needed manual port-forwarding to access the UI.

Key Fixes / Actions:
Used kubectl port-forward to expose ArgoCD server locally.

Retrieved admin password securely using:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
Verified deployment with:

helm list -n argocd

kubectl get svc -n argocd

kubectl get pods -n argocd

📊 2. Prometheus & Grafana Observability Stack
Issues Faced:
Port-forwarding required for UI access.

Insecure default settings (anonymous Grafana login, hardcoded credentials).

Runtime secrets fetching pattern via initContainer and aws-cli.

Fixes & Improvements:
Used Helm with existingSecret to inject Grafana admin credentials:

grafana:
  admin:
    existingSecret: grafana-admin
Enabled resource requests/limits:

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
Enabled persistent storage:

persistence:
  enabled: true
  storageClassName: gp2
  size: 5Gi
Disabled anonymous access:

grafana.ini:
  auth.anonymous:
    enabled: false
Outcome:
🔐 Secured login.

💾 Persistent dashboards.

📊 Enabled ServiceMonitor for Prometheus to scrape Grafana metrics.

☁️ 3. ALB Controller Setup
Issues Faced:
Needed to confirm ALB pods running and debug logs.

Key Checks:
Verified services with kubectl get svc -A | grep LoadBalancer.

Verified controller status with:

kubectl get pods -n kube-system | grep alb
kubectl logs -n kube-system <alb-pod>
🔩 4. EBS CSI Driver & Cluster Connectivity
Tasks:
Ensured cluster was connected using:

aws eks --region us-east-1 update-kubeconfig --name <cluster>
kubectl get nodes
kubectl cluster-info
Validated namespace and CSI driver behavior.

🔒 5. Secrets Handling & Alertmanager Slack Integration
Original Issue:
Secrets were pulled at runtime via initContainers with aws-cli — insecure and fragile.

Fix:
Pulled Slack webhook from AWS Secrets Manager using Terraform:

data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = var.slack_webhook_secret_id
}
Created Kubernetes Secret with key slack_api_url.

Outcome:
🔐 Secure deployment-time secret injection.

📫 Reliable and compliant Slack alerting.

📦 6. Modular Terraform Structure
Improvements:
Split Prometheus alert rules into a separate prometheus_rules.tf for maintainability.

Used modular values = [ file(...) ] pattern to load Helm values cleanly.

✅ Final Summary
Area	Outcome
ArgoCD	Access fixed, admin login secured, deployment verified
Grafana/Prometheus	Secured secrets, persistent storage, resource limits, alerting enhanced
ALB Controller	Verified pods, logs, service exposure
EBS CSI Driver	Cluster connection validated, namespace checks passed
Secrets Handling	Migrated to Terraform-managed secure secrets from AWS SM
Terraform Structure	Modularized alert rules and Helm values for production readiness

