output "public_instance_ids" {
  description = "List of public EC2 instance IDs"
  value       = [for instance in aws_instance.public : instance.id]
}
output "private_instance_ids" {
  description = "List of private EC2 instance IDs"
  value       = [for instance in aws_instance.private : instance.id]
}


