output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The EKS cluster endpoint."
}

output "eks_cluster_ca_certificate" {
  value       = module.eks.cluster_certificate_authority_data
  description = "The base64 encoded certificate authority data for the EKS cluster."
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the EKS cluster."
}

output "loki_bucket_name" {
  value       = module.observability.loki_bucket_name
  description = "The name of the Loki S3 bucket."
}

output "mimir_bucket_name" {
  value       = module.observability.mimir_bucket_name
  description = "The name of the Mimir S3 bucket."
}

output "aws_region" {
  value       = var.targetRegion
  description = "The AWS region where the infrastructure is deployed."
}

output "db_secret_arn" {
  value       = module.rds.rds_database_secret_arn
  description = "The ARN of the database secret."
  sensitive = true
}

output "db_url" {
  value       = module.rds.rds_database_url
  description = "The database URL."
}

output "db_port" {
  value       = module.rds.rds_database_port
  description = "The database port."
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC."
}
