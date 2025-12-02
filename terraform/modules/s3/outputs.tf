output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.bucket
}

output "log_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}

output "operations_bucket_name" {
  value = aws_s3_bucket.operations_bucket.bucket
}

output "operations_bucket_arn" {
  value = aws_s3_bucket.operations_bucket.arn
}

output "replication_bucket_name" {
  value = aws_s3_bucket.replication_bucket.bucket
}

output "replication_bucket_arn" {
  value = aws_s3_bucket.replication_bucket.arn
}

output "config_bucket_name" {
  value = aws_s3_bucket.log_bucket.bucket
  
}
