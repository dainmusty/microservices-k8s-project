output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_port" {
  description = "Port the database is listening on"
  value       = aws_db_instance.postgres.port
}

output "rds_subnet_group_id" {
  description = "ID of the RDS subnet group"
  value       = aws_db_subnet_group.rds_subnet_group.id
}

