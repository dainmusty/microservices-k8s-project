# you can use the codes below to create your passwords in parameter store
eg. 1 db_user
# modules/ssm/main.tf
resource "aws_ssm_parameter" "db_user" {
  name  = var.db_user_parameter_name
  type  = var.db_user_parameter_type
  value = var.db_user_parameter_value

}

eg. 2
# SSM Parameter for Grafana Admin Password
resource "aws_ssm_parameter" "grafana_admin_password" {
  name        = "/grafana/admin/password"
  type        = "SecureString"
  value       = var.grafana_admin_password
  description = "Grafana admin password for cluster monitoring dashboard"
}
This exposes your actual password. create your password in parameter store in the console and put the value there before terraform apply

# Once created, you can use data to retrieve your passwords
# Data sources for EKS cluster info

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_ssm_parameter" "db_access_parameter_name" {
  name = var.db_access_parameter_name
}

data "aws_ssm_parameter" "db_secret_parameter_name" {
  name = var.db_secret_parameter_name
}

data "aws_ssm_parameter" "key_parameter_name" {
  name = var.key_parameter_name
}


data "aws_ssm_parameter" "key_name_parameter_name" {
  name = var.key_name_parameter_name
}

# Note: You can inject this value into the Grafana Helm chart like below:
# data "aws_ssm_parameter" "grafana_admin_password" {
#   name            = "/grafana/admin/password"
#   with_decryption = true
# }
# 
# and then set it via:
# set {
#   name  = "adminPassword"
#   value = data.aws_ssm_parameter.grafana_admin_password.value
# }


 # Use secret mgr for your grafana password, it has the ff advantages
 | Feature               | SSM Parameter Store   | Secrets Manager      |
| --------------------- | --------------------- | -------------------- |
| Cost                  | ✅ Cheaper             | ❌ Higher             |
| Encryption            | ✅ With KMS            | ✅ Built-in           |
| Versioning            | ❌ No                  | ✅ Yes                |
| Rotation              | ❌ Manual              | ✅ Automatic          |
| Best for              | Config, passwords     | DB creds, tokens     |
| Grafana dynamic fetch | 🚧 Extra setup needed | ✅ Easier integration |

Flow Summary:
Secret is stored securely in Secrets Manager.

Terraform dynamically reads it.

The secret is created as a Kubernetes secret, and Helm is told to use it.


 Two Different "Secrets"
There are two kinds of secrets involved here:

Type	Name	Purpose
AWS Secrets Manager	slack/webhook/prometheus-alertmanager	Stores the real Slack webhook securely in AWS
Kubernetes Secret	alertmanager-slack-webhook	Created by Terraform from the AWS secret so it can be mounted in the cluster


Best Practice: Create Secrets Manually and Use data to Reference Them
Do not create secrets in Terraform if you:

Want to hide sensitive values from code

Already rotate/manage secrets manually or via automation

Want to avoid Terraform state containing passwords

Instead:

Manually create the secrets in AWS Secrets Manager via console or CLI

Use data "aws_secretsmanager_secret" and data "aws_secretsmanager_secret_version" to safely read the values

This avoids:

Hardcoding sensitive values in .tf files

Having secret values end up in terraform.tfstate

Conflicts with secrets that are deleted but still in scheduled deletion

# Create grafana and slack secrets manually

1. aws secretsmanager create-secret --name grafana-user-passwd --secret-string '{"username":"admin","password":"****************"}'


2. aws secretsmanager create-secret --name slack-webhook-alertmanager --secret-string '{"url":"https://hooks.slack.com/your/webhook/url"}'



