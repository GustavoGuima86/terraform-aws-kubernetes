output "iam_role_arn" {
  description = "The ARN of the IAM role for external-dns"
  value       = module.external_dns_pod_identity.iam_role_arn
}

output "iam_role_name" {
  description = "The name of the IAM role for external-dns"
  value       = module.external_dns_pod_identity.iam_role_name
}

output "hosted_zone_id" {
  description = "The Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "hosted_zone_name" {
  description = "The Route53 hosted zone name"
  value       = data.aws_route53_zone.main.name
}

output "certificate_arn" {
  description = "The ARN of the ACM certificate for ArgoCD"
  value       = aws_acm_certificate.certificate.arn
}

output "domain_name" {
  description = "The full domain name for ArgoCD"
  value       = var.domain_name
}

