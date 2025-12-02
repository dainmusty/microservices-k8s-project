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

# Once the created, you can use data to retrieve your passwords
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

