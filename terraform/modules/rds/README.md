# Terraform essential commands and notes
terraform init

terraform plan

terraform apply --auto-approve

terraform destroy --auto-approve

terraform reconfigure

# Generate a terraform plan and apply targeting only specified infrastructure:
# terraform plan -target=aws_vpc.network -target=aws_efs_file_system.efs_setup

# terraform apply -target=aws_vpc.network -target=aws_efs_file_system.efs_setup


# follow the steps below if you want to use ssm as a child module to dynamically encrypt your db username and password with the kms child module

# root module
module "rds" {
  source = "../../modules/rds"
  identifier = "gnpc-dev-db"
  db_engine = "postgres"
  db_engine_version = "14.6"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  db_name = "mydb"
  username = module.ssm.db_username_ssm_parameter_name
  password = module.ssm.db_password_ssm_parameter_name
  vpc_security_group_ids = [module.security_group.private_sg_id]
  db_subnet_group_name = module.vpc.vpc_private_subnets[0]
  multi_az = false
  storage_type = "gp2"
  backup_retention_period = 7
  skip_final_snapshot = true
  publicly_accessible = false
  db_tags = {
    Name        = "rds-instance"
    Environment = "Dev"
    Owner       = "Musty"
  }
  
  depends_on = [module.ssm]

# main.tf
  resource "aws_ssm_parameter" "db_username" {
  name   = var.db_username_parameter_name
  type   = var.parameter_type
  value  = var.db_username
  key_id = var.kms_key_id
}
 
resource "aws_ssm_parameter" "db_password" {
  name   = var.db_password_parameter_name
  type   = var.parameter_type
  value  = var.db_password
  key_id = var.kms_key_id    #key_id - (Optional) KMS key ID or ARN for encrypting a SecureString.
}

# output.tf
output "db_username_ssm_parameter_arn" {
  description = "The ARN of the SSM parameter storing the database username"
  value       = aws_ssm_parameter.db_username.arn
}
 
output "db_password_ssm_parameter_arn" {
  description = "The ARN of the SSM parameter storing the database password"
  value       = aws_ssm_parameter.db_password.arn
}
 
output "db_username_ssm_parameter_name" {
  description = "The name of the SSM parameter storing the database username"
  value       = aws_ssm_parameter.db_username.name
}
 
output "db_password_ssm_parameter_name" {
  description = "The name of the SSM parameter storing the database password"
  value       = aws_ssm_parameter.db_password.name
} 

# variables.tf
variable "db_engine" {
  description = "The database engine to use"
  type        = string
  
}

variable "db_engine_version" {
  description = "The version of the database engine"
  type        = string
   
}

variable "instance_class" {
  description = "The instance type of the RDS"
  type        = string
   
}

variable "allocated_storage" {
  description = "The amount of storage (in GB)"
  type        = number
  
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
}

variable "username" {
  description = "Master username for the DB"
  type        = string
}

variable "password" {
  description = "Master password for the DB"
  type        = string
  sensitive   = true
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "storage_type" {
  description = "Storage type: standard, gp2, or io1"
  type        = string
   
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "identifier" {
  description = "The RDS instance identifier"
  type        = string
}
variable "skip_final_snapshot" {
  description = "Whether to skip creating a final DB snapshot on deletion"
  type        = bool
}

variable "publicly_accessible" {
  description = "Whether the DB should have a public IP address"
  type        = bool
}

variable "db_tags" {
  description = "Tags to apply to the RDS instance"
  type        = map(string)
  default     = {}
  
}

# kms (main.tf)
resource "aws_kms_key" "kms_key_dev" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
}

resource "aws_kms_alias" "kms_alias_dev" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.kms_key_dev.id
}


# outputs.tf
output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.kms_key_dev.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.kms_key_dev.id
}

output "kms_alias_name" {
  description = "The name of the KMS alias"
  value       = aws_kms_alias.kms_alias_dev.name
}

# variables.tf
variable "description" {
  description = "Description of the KMS key"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Number of days before the KMS key is deleted"
  type        = number
  
}

variable "enable_key_rotation" {
  description = "Enable automatic key rotation"
  type        = bool
  
}

variable "alias" {
  description = "Alias name for the KMS key"
  type        = string
}


# tfvars
# tfvars for rds db
db_password = "password"
db_username = "username"

# variables.tf
variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}


# ssm variables.tf
variable "db_username_parameter_name" {
  description = "The name of the SSM parameter for the database username"
  type        = string
  default     = "/prod/db/username"
}
 
variable "db_password_parameter_name" {
  description = "The name of the SSM parameter for the database password"
  type        = string
  default     = "/prod/db/password"
}
 
variable "db_username" {
  description = "The value of the database username"
  type        = string
}
 
variable "db_password" {
  description = "The value of the database password"
  type        = string
}
 
variable "kms_key_id" {
  description = "The ARN of the KMS key used to encrypt the SSM parameters"
  type        = string
}
 
variable "parameter_type" {
  description = "The type of the SSM parameter (e.g., String, SecureString, StringList)"
  type        = string
  default     = "SecureString"
}


