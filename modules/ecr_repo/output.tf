output "ecr_repo" {
  description = "ecr repo URL"
  value       = aws_ecr_repository.ecr_repository.repository_url
}