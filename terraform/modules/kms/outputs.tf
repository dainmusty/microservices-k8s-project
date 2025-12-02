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
