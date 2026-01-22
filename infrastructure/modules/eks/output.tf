output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Eks cluster name"
}

output "oidc_id" {
  value       = local.oidc_id
  description = "The OIDC ID extracted from the issuer URL."
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "The ARN of the IAM OIDC provider associated with the EKS cluster."
}

output "eks_oidc_provider_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "The URL of the IAM OIDC provider associated with the EKS cluster."
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "The base64-encoded certificate authority data for the EKS cluster."
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The API server endpoint for the EKS cluster."
}

output "karpenter_controller_iam_role_arn" {
  value       = module.karpenter.iam_role_arn
  description = "The ARN of the IAM role for the Karpenter controller."
}

output "karpenter_node_iam_role_arn" {
  value       = module.karpenter.node_iam_role_arn
  description = "The ARN of the IAM role for the nodes launched by Karpenter."
}

output "karpenter_node_iam_role_name" {
  value       = module.karpenter.node_iam_role_name
  description = "The name of the IAM role for the nodes launched by Karpenter."
}

output "karpenter_interruption_queue_name" {
  value       = module.karpenter.queue_name
  description = "The name of the SQS queue for Karpenter interruption events."
}

output "karpenter_interruption_queue_url" {
  value       = module.karpenter.queue_arn
  description = "The URL of the SQS queue for Karpenter interruption events."
}

output "velero_bucket_name" {
  description = "The name of the Velero S3 bucket."
  value       = aws_s3_bucket.velero_bucket.bucket
}

output "velero_bucket_region" {
  description = "The region of the Velero S3 bucket."
  value       = aws_s3_bucket.velero_bucket.region
}

output "external_dns_role_arn" {
  description = "The ARN of the IAM role for external-dns"
  value       = module.external_dns_pod_identity.iam_role_arn
}

output "iam_role_name" {
  description = "The name of the IAM role for external-dns"
  value       = module.external_dns_pod_identity.iam_role_name
}