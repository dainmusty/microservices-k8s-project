terraform plan -target=module.eks.aws_cloudformation_stack.eks_cluster_stack
terraform apply -target=module.eks.aws_cloudformation_stack.eks_cluster_stack --auto-approve
aws eks update-kubeconfig --region us-east-1 --name effulgencetech-dev
Phase 2: All Resources

terraform apply --auto-approve
Delete Resources

terraform destroy --auto-approve
terraform destroy -target=module.iam --auto-approve
Testing Cluster Access

aws eks update-kubeconfig --region us-east-1 --name effulgencetech-dev


Repo Structure for ArgoCD
gnpc-terraform-infra-k8s-web-app/
│
├── .github/
│   └── workflows/
│       └── ci.yaml                  # GitHub Actions workflow
│
├── k8s/
│   ├── fonapp/                      # This is the path ArgoCD needs to see
│   │   ├── frontend.yml             # Frontend deployment + service
│   │   ├── backend.yml              # Backend deployment + service
│   │   └── ingress.yml              # Ingress definition
│
│   └── dev/
│       └── fonapp-argocd-app.yaml   # ArgoCD Application YAML (declares the app)
│
├── terraform/
│   └── ...                          # Your infra code if any
│
├── README.md
└── other files...

# Terraform essential commands and notes
terraform init

terraform plan

terraform apply --auto-approve

terraform destroy --auto-approve

terraform reconfigure
# 📘 Production-Ready Grafana & Prometheus Setup with Secure Secrets and Alerting

This document outlines the modular setup and best practices applied in configuring Grafana and Prometheus using Terraform, Helm, and Kubernetes for a secure and maintainable observability stack.

---

## 🟩 1. `grafana-admin` Secret Handling Module

### ✅ Before
- Used an `initContainer` with `amazonlinux` and `aws-cli` to fetch secrets at runtime.
- Embedded IAM dependencies and runtime logic, increasing security risks.

### ✅ Now (Best Practice)
- Terraform reads secrets from AWS Secrets Manager.
- Creates a Kubernetes `Secret` (`grafana-admin`) with keys: `admin-user`, `admin-password`.
- Helm references the secret using `admin.existingSecret`.

```yaml
grafana:
  admin:
    existingSecret: grafana-admin
```

### ✅ Benefits
- 🔐 Secure: No AWS CLI or IAM dependency inside the pod.
- 🧹 Simplified deployment with fewer runtime risks.
- 📦 Helm-standard way of injecting secrets.

---

## 🟨 2. Alertmanager Slack Notification Module

### ✅ Improvements
- Terraform reads the Slack webhook from AWS Secrets Manager:
```hcl
data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = var.slack_webhook_secret_id
}
```

- Creates a Kubernetes Secret for Alertmanager with the correct key `slack_api_url`.

### ✅ Benefits
- 📫 Reliable Slack alerting.
- 🔒 Secure handling of secrets at deploy time, not runtime.

---

## 🟦 3. Grafana Helm Release Module

### ✅ Enhancements
```yaml
grafana:
  serviceAccount:
    create: false
    name: grafana

  service:
    type: LoadBalancer

  admin:
    existingSecret: grafana-admin

  grafana.ini:
    auth.anonymous:
      enabled: false

  serviceMonitor:
    enabled: true
```

### ✅ Benefits
- 🔐 Authentication enforced.
- 📡 Metrics available to Prometheus.
- 📊 Better production readiness.

---

## 🟧 4. Kubernetes Resource Requests Module

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### ✅ Why it Matters
- 🚦 Ensures stability and fair resource usage in Kubernetes.

---

## 🟥 5. Persistence Volume Module

```yaml
persistence:
  enabled: true
  storageClassName: gp2
  size: 5Gi
```

### ✅ Benefits
- 💾 Dashboards and configurations survive restarts.
- 🧠 Stateful Grafana setup.

---

## 🟪 6. Optional Enhancements

| Enhancement                      | Purpose                                 | Benefit                         |
|----------------------------------|-----------------------------------------|----------------------------------|
| Make admin username configurable | Pull from secret instead of hardcoding | Reusable across environments    |
| Add disk, pod, RDS alerts        | Extend Prometheus alert coverage       | Full observability              |
| Add pre-built dashboards         | Automatically load dashboards          | Fast operational insights       |

---

## 🧠 Summary

✅ Secure Secrets (Grafana + Alertmanager)  
✅ Best Practice Helm Usage (`existingSecret`)  
✅ Scalable, Production-Ready Config  
✅ Minimal Runtime Dependencies

## 📘 Additional Operational Notes

### 🏗️ Terraform Workflow (Two-Phase)
**Phase 1: Cluster Only**
```bash
terraform plan -target=module.eks.aws_cloudformation_stack.eks_cluster_stack
terraform apply -target=module.eks.aws_cloudformation_stack.eks_cluster_stack --auto-approve
aws eks update-kubeconfig --region us-east-1 --name effulgencetech-dev
```

**Phase 2: All Resources**
```bash
terraform apply --auto-approve
```

**Delete Resources**
```bash
terraform destroy --auto-approve
terraform destroy -target=module.iam --auto-approve
```

**Testing Cluster Access**
```bash
aws eks update-kubeconfig --region us-east-1 --name effulgencetech-dev
```

---

### 🚀 ArgoCD Access and Management

**Check ArgoCD Pods**
```bash
kubectl get pods -n argocd
```

**Port-forward for Local Access**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**Expose ArgoCD via ALB**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl expose deployment argocd-server --type=LoadBalancer --name=argocd-server --port=80 --target-port=8080 -n argocd
kubectl get ingress -n argocd
```

**Initial Admin Password**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

### 📊 Grafana & Prometheus Access

**Port-forward Grafana**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

**Port-forward Prometheus**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090
```

**Grafana Troubleshooting**
```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get secret grafana-admin -n monitoring -o yaml
helm get all kube-prometheus-stack -n monitoring
```

---

### ⚙️ AWS Load Balancer Controller IRSA Example
IAM trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/<OIDC_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/<OIDC_ID>:sub": "system:serviceaccount:kube-system:alb_controller",
          "oidc.eks.us-east-1.amazonaws.com/id/<OIDC_ID>:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

---

### 📦 TFLint Best Practices

**Install TFLint**
```bash
# Linux
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# macOS
brew install tflint

# Windows
choco install tflint
```

**Enable AWS Plugin**
`.tflint.hcl`:
```hcl
plugin "aws" {
  enabled = true
  version = "0.39.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```
Then run:
```bash
tflint --init
```

---

### 🔐 IAM Principal Use Cases

| Value                          | Use Case                         |
|-------------------------------|----------------------------------|
| ["ec2.amazonaws.com"]         | Standard EKS worker nodes        |
| ["ssm.amazonaws.com"]         | SSM-managed nodes                |
| ["eks.amazonaws.com"]         | EKS service (rare)               |
| ["ec2.amazonaws.com", ...]    | Advanced multi-service scenarios |

**Permissions Boundary**
- `null` = No permission boundary
- `"arn:..."` = Explicitly applied boundary

---

### ❗ Terraform Variable Errors and Best Practices

**Common Error**
```text
Error: The root module input variable "region"/"cluster_name" is not set
```

**Root Cause**
- Declaring variables in child modules doesn't propagate values to the root.
- You must define or pass these variables explicitly in the root module.

**Solution Options**
1. Set default values in `variables.tf` in the root module.
2. Pass variables with `-var` or a `.tfvars` file.
3. Use `terraform.tfvars` or `main.tf` to supply inputs.

**Best Practice for providers.tf**
- Should be in the **root module**.
- Child modules should not define providers, unless they need different configurations.

---



