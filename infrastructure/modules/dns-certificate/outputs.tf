output "hosted_zone_id" {
  description = "The Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "hosted_zone_name" {
  description = "The Route53 hosted zone name"
  value       = data.aws_route53_zone.main.name
}

output "argocd_certificate_arn" {
  description = "The ARN of the ACM certificate for ArgoCD"
  value       = aws_acm_certificate.certificate.arn
}