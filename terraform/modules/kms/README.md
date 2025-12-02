
# modules/kms/main.tf
resource "aws_kms_key" "ssm_key" {
  description             = "KMS key for encrypting SSM parameters"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

output "key_arn" {
  value = aws_kms_key.ssm_key.arn
}


module "kms" {
  source = "./modules/kms"
}

module "ssm" {
  source            = "./modules/ssm"
  parameter_name    = "/infra/keys/private_key_path"
  parameter_value   = "C:/Users/..."
  type              = "SecureString"
  kms_key_id        = module.kms.key_arn
}


# modules/ssm/variables.tf
variable "parameter_name" {
  type = string
}
variable "parameter_value" {
  type = string
}
variable "type" {
  type    = string
  default = "String"
}
variable "kms_key_id" {
  type    = string
  default = null
}



module "kms" {
  source = "../../modules/kms"
  description = "KMS key for GNPC Dev"
  deletion_window_in_days = 7
  enable_key_rotation = true
  alias = "gnpc-dev-kms-key"
  }

