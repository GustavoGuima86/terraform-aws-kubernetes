output "awsRegion" {
  value       = var.targetRegion
  description = "main hosted aws region"
}

output "aws_account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "The AWS Account ID"
}

output "domain_name" {
  value       = var.domain_name
  description = "The base domain name"
}

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
  sensitive   = true
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

output "karpenter_controller_iam_role_arn" {
  value       = module.eks.karpenter_controller_iam_role_arn
  description = "The ARN of the IAM role for the Karpenter controller."
}
output "karpenter_node_iam_role_name" {
  value       = module.eks.karpenter_node_iam_role_name
  description = "The name of the IAM role for nodes launched by Karpenter."
}

output "karpenter_interruption_queue_name" {
  value       = module.eks.karpenter_interruption_queue_name
  description = "The name of the SQS queue for Karpenter interruption events."
}

output "karpenter_interruption_queue_url" {
  value       = module.eks.karpenter_interruption_queue_url
  description = "The URL of the SQS queue for Karpenter interruption events."
}

output "loki_service_account_role_arn" {
  value       = module.observability.loki_pod_identity_role_arn
  description = "The ARN of the IAM role for the Loki service account."
}

output "loki_service_account_name" {
  value       = module.observability.loki_service_account_name
  description = "The name of the Loki service account."
}

output "mimir_service_account_role_arn" {
  value       = module.observability.mimir_pod_identity_role_arn
  description = "The ARN of the IAM role for the Mimir service account."
}

output "mimir_service_account_name" {
  value       = module.observability.mimir_service_account_name
  description = "The name of the Mimir service account."
}

# External DNS and Certificate outputs
output "external_dns_role_arn" {
  value       = module.eks.external_dns_role_arn
  description = "The ARN of the IAM role for external-dns"
}

output "certificate_arn" {
  value       = module.dns.certificate_arn
  description = "The ARN of the ACM certificate"
}

output "acmCertificateArn" {
  value       = module.dns.certificate_arn
  description = "The ARN of the ACM certificate for ArgoCD"
}

output "hosted_zone_id" {
  value       = module.dns.hosted_zone_id
  description = "The Route53 hosted zone ID"
}

# Velero outputs
output "velero_bucket_name" {
  value       = module.eks.velero_bucket_name
  description = "The name of the Velero S3 bucket"
}

output "velero_bucket_region" {
  value       = module.eks.velero_bucket_region
  description = "The region of the Velero S3 bucket"
}

