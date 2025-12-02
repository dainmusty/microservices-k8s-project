output "db_access_parameter_value" {
  description = "The value of the DB access SSM parameter"
  value       = data.aws_ssm_parameter.db_access_parameter_name.value
  sensitive = true
}

output "db_secret_parameter_value" {
  description = "The value of the DB secret SSM parameter"
  value       = data.aws_ssm_parameter.db_secret_parameter_name.value
  sensitive = true
}

output "key_path_parameter_value" {
  description = "The value of the key SSM parameter"
  value       = data.aws_ssm_parameter.key_path_parameter_name.value
  sensitive = true
}

output "key_name_parameter_value" {
  description = "The value of the key name SSM parameter"
  value       = data.aws_ssm_parameter.key_name_parameter_name.value
  sensitive = true
}