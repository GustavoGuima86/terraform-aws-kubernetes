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
