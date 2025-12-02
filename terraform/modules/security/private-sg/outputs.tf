output "private_sg_id" {
  description = "The ID of the private security group"
  value       = aws_security_group.private_sg.id
}
