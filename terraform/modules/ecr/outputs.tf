output "repository_url" {
  value = aws_ecr_repository.dev_containers_repo.repository_url
}

output "arn" {
  value = aws_ecr_repository.dev_containers_repo.arn
}
