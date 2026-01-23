# ==============================================================================
# Core Infrastructure Outputs
# ==============================================================================

output "aws_account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS Account ID"
}

output "domain_name" {
  value       = var.domain_name
  description = "Base domain name"
}

output "aws_region" {
  value       = var.targetRegion
  description = "AWS region"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

# ==============================================================================
# EKS Cluster Outputs
# ==============================================================================

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "eks_cluster_ca_certificate" {
  value       = module.eks.cluster_certificate_authority_data
  description = "EKS cluster CA certificate (base64 encoded)"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

# ==============================================================================
# Database Outputs
# ==============================================================================

output "db_secret_arn" {
  value       = module.rds.rds_database_secret_arn
  description = "Database secret ARN"
  sensitive   = true
}

output "db_url" {
  value       = module.rds.rds_database_url
  description = "Database URL"
}

output "db_port" {
  value       = module.rds.rds_database_port
  description = "Database port"
}

# ==============================================================================
# Karpenter Outputs
# ==============================================================================

output "karpenter_controller_iam_role_arn" {
  value       = module.eks.karpenter_controller_iam_role_arn
  description = "Karpenter controller IAM role ARN"
}

output "karpenter_node_iam_role_name" {
  value       = module.eks.karpenter_node_iam_role_name
  description = "Karpenter node IAM role name"
}

output "karpenter_interruption_queue_name" {
  value       = module.eks.karpenter_interruption_queue_name
  description = "Karpenter interruption queue name"
}

output "karpenter_interruption_queue_url" {
  value       = module.eks.karpenter_interruption_queue_url
  description = "Karpenter interruption queue URL"
}

# ==============================================================================
# Observability Outputs
# ==============================================================================

output "loki_bucket_name" {
  value       = module.observability.loki_bucket_name
  description = "Loki S3 bucket name"
}

output "loki_service_account_role_arn" {
  value       = module.observability.loki_pod_identity_role_arn
  description = "Loki service account IAM role ARN"
}

output "loki_service_account_name" {
  value       = module.observability.loki_service_account_name
  description = "Loki service account name"
}

output "mimir_bucket_name" {
  value       = module.observability.mimir_bucket_name
  description = "Mimir S3 bucket name"
}

output "mimir_service_account_role_arn" {
  value       = module.observability.mimir_pod_identity_role_arn
  description = "Mimir service account IAM role ARN"
}

output "mimir_service_account_name" {
  value       = module.observability.mimir_service_account_name
  description = "Mimir service account name"
}

# ==============================================================================
# DNS and Certificate Outputs
# ==============================================================================

output "external_dns_role_arn" {
  value       = module.eks.external_dns_role_arn
  description = "External DNS IAM role ARN"
}

output "certificate_arn" {
  value       = module.dns.certificate_arn
  description = "ACM certificate ARN"
}

output "hosted_zone_id" {
  value       = module.dns.hosted_zone_id
  description = "Route53 hosted zone ID"
}

# ==============================================================================
# Backup Outputs
# ==============================================================================

output "velero_bucket_name" {
  value       = module.eks.velero_bucket_name
  description = "Velero S3 bucket name"
}

output "velero_bucket_region" {
  value       = module.eks.velero_bucket_region
  description = "Velero S3 bucket region"
}

# ==============================================================================
# IAM Role ARNs for Service Accounts
# ==============================================================================

output "aws_lb_controller_role_arn" {
  value       = module.eks.aws_lb_controller_role_arn
  description = "AWS Load Balancer Controller IAM role ARN"
}

output "velero_service_account_role_arn" {
  value       = module.eks.velero_service_account_role_arn
  description = "Velero service account IAM role ARN"
}

output "ebs_csi_controller_role_arn" {
  value       = module.eks.ebs_csi_controller_role_arn
  description = "EBS CSI controller IAM role ARN"
}

output "secrets_csi_driver_role_arn" {
  value       = module.eks.secrets_csi_driver_role_arn
  description = "Secrets Store CSI driver IAM role ARN"
}

# ==============================================================================
# Service Account Names
# ==============================================================================

output "aws_lb_controller_sa_name" {
  value       = module.eks.aws_lb_controller_sa_name
  description = "AWS Load Balancer Controller service account name"
}

output "karpenter_sa_name" {
  value       = module.eks.karpenter_sa_name
  description = "Karpenter service account name"
}

output "external_dns_sa_name" {
  value       = module.eks.external_dns_sa_name
  description = "External DNS service account name"
}

output "velero_sa_name" {
  value       = module.eks.velero_sa_name
  description = "Velero service account name"
}

output "ebs_csi_controller_sa_name" {
  value       = module.eks.ebs_csi_controller_sa_name
  description = "EBS CSI controller service account name"
}

output "secrets_csi_driver_sa_name" {
  value       = module.eks.secrets_csi_driver_sa_name
  description = "Secrets Store CSI driver service account name"
}

