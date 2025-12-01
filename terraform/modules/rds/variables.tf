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

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  
}

variable "storage_type" {
  description = "Storage type: standard, gp2, or io1"
  type        = string
   
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
   
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

variable "env" {
  description = "The environment (e.g., dev, prod)"
  type        = string    
  
}

variable "db_subnet_group_name" {
  description = "The name of the RDS subnet group"
  type        = string
  
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS subnet group"
  type        = list(string)  
}











