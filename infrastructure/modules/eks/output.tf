# ==============================================================================
# EKS Cluster Outputs
# ==============================================================================

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "oidc_id" {
  value       = local.oidc_id
  description = "OIDC provider ID"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "EKS OIDC provider ARN"
}

output "eks_oidc_provider_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "EKS OIDC provider URL"
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "EKS cluster CA certificate (base64 encoded)"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster API endpoint"
}

# ==============================================================================
# Karpenter Outputs
# ==============================================================================

output "karpenter_controller_iam_role_arn" {
  value       = module.karpenter.iam_role_arn
  description = "Karpenter controller IAM role ARN"
}

output "karpenter_node_iam_role_arn" {
  value       = module.karpenter.node_iam_role_arn
  description = "Karpenter node IAM role ARN"
}

output "karpenter_node_iam_role_name" {
  value       = module.karpenter.node_iam_role_name
  description = "Karpenter node IAM role name"
}

output "karpenter_interruption_queue_name" {
  value       = module.karpenter.queue_name
  description = "Karpenter interruption queue name"
}

output "karpenter_interruption_queue_url" {
  value       = module.karpenter.queue_arn
  description = "Karpenter interruption queue URL"
}

# ==============================================================================
# Backup Outputs
# ==============================================================================

output "velero_bucket_name" {
  description = "Velero S3 bucket name"
  value       = aws_s3_bucket.velero_bucket.bucket
}

output "velero_bucket_region" {
  description = "Velero S3 bucket region"
  value       = aws_s3_bucket.velero_bucket.region
}

# ==============================================================================
# DNS Outputs
# ==============================================================================

output "external_dns_role_arn" {
  description = "External DNS IAM role ARN"
  value       = module.external_dns_pod_identity.iam_role_arn
}

output "iam_role_name" {
  description = "External DNS IAM role name"
  value       = module.external_dns_pod_identity.iam_role_name
}

# ==============================================================================
# IAM Role ARNs
# ==============================================================================

output "aws_lb_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = module.aws_lb_controller_pod_identity.iam_role_arn
}

output "velero_service_account_role_arn" {
  description = "Velero service account IAM role ARN"
  value       = module.velero_s3_pod_identity.iam_role_arn
}

output "ebs_csi_controller_role_arn" {
  description = "EBS CSI controller IAM role ARN"
  value       = module.aws_ebs_csi_pod_identity.iam_role_arn
}

output "secrets_csi_driver_role_arn" {
  description = "Secrets Store CSI driver IAM role ARN"
  value       = module.aws_ebs_csi_pod_identity_secret.iam_role_arn
}

# ==============================================================================
# Service Account Names
# ==============================================================================

output "aws_lb_controller_sa_name" {
  description = "AWS Load Balancer Controller service account name"
  value       = local.aws_lb_controller_sa_name
}

output "karpenter_sa_name" {
  description = "Karpenter service account name"
  value       = local.karpenter_sa_name
}

output "external_dns_sa_name" {
  description = "External DNS service account name"
  value       = local.external_dns_sa_name
}

output "velero_sa_name" {
  description = "Velero service account name"
  value       = local.velero_sa_name
}

output "falco_role_arn" {
  description = "Falco IAM role ARN"
  value       = module.falco_pod_identity.iam_role_arn
}

output "falco_sa_name" {
  description = "Falco service account name"
  value       = local.falco_sa_name
}

output "opencost_role_arn" {
  description = "OpenCost IAM role ARN"
  value       = module.opencost_pod_identity.iam_role_arn
}

output "opencost_sa_name" {
  description = "OpenCost service account name"
  value       = local.opencost_sa_name
}

output "ebs_csi_controller_sa_name" {
  description = "EBS CSI controller service account name"
  value       = local.ebs_csi_controller_sa_name
}

output "secrets_csi_driver_sa_name" {
  description = "Secrets Store CSI driver service account name"
  value       = local.secrets_csi_driver_sa_name
}