variable "db_access_parameter_name" {
  description = "The name of the SSM parameter for DB access"
  type        = string
}

variable "db_secret_parameter_name" {
  description = "The name of the SSM parameter for DB secret"
  type        = string
}

variable "key_path_parameter_name" {
  description = "The name of the SSM parameter for the key"
  type        = string
}

variable "key_name_parameter_name" {
  description = "The name of the SSM parameter for the key name"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password for cluster monitoring dashboard"
  type        = string
}