output "loki_bucket_name" {
  value       = aws_s3_bucket.loki_bucket_chunk.id
  description = "Loki S3 chunk bucket name"
}

output "loki_pod_identity_role_arn" {
  value       = module.loki_s3_pod_identity.iam_role_arn
  description = "ARN of the Loki pod identity role"
}

output "loki_service_account_name" {
  value       = local.sa_loki_name
  description = "Service account name for Loki"
}

output "mimir_bucket_name" {
  value       = aws_s3_bucket.mimir_bucket_chunk.id
  description = "Mimir S3 chunk bucket name"
}

output "mimir_pod_identity_role_arn" {
  value       = module.mimir_s3_pod_identity.iam_role_arn
  description = "ARN of the Mimir pod identity role"
}

output "mimir_service_account_name" {
  value       = local.sa_mimir_name
  description = "Service account name for Mimir"
}

output "grafana_admin_password_parameter" {
  value       = aws_ssm_parameter.password_grafana.name
  description = "AWS SSM Parameter name containing Grafana admin password"
}
