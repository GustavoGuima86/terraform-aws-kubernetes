resource "aws_s3_bucket" "loki_bucket_chunk" {
  bucket        = local.bucket_loki_chunk
  force_destroy = true
}

resource "aws_s3_bucket" "loki_bucket_ruler" {
  bucket        = local.bucket_loki_ruler
  force_destroy = true
}

resource "aws_iam_policy" "loki_s3_policy" {
  name        = "loki-s3-policy"
  description = "Policy for Loki to access specific S3 buckets"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::${local.bucket_loki_chunk}",
        "arn:aws:s3:::${local.bucket_loki_chunk}/*",
        "arn:aws:s3:::${local.bucket_loki_ruler}",
        "arn:aws:s3:::${local.bucket_loki_ruler}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "loki_s3_role" {
  name = "loki-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.${local.region}.amazonaws.com/id/${var.oidc_id}:sub" = "system:serviceaccount:${var.namespace}:${local.sa_loki_name}",
            "oidc.eks.${local.region}.amazonaws.com/id/${var.oidc_id}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "loki-policy-attach" {
  role       = aws_iam_role.loki_s3_role.name
  policy_arn = aws_iam_policy.loki_s3_policy.arn
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.19.0"
  values     = [local.values_loki]
  depends_on = [helm_release.agent_operator, helm_release.rollout_operator]
}

resource "helm_release" "promtail" {
  name       = "promtail"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.15.3"

  values = [
    file("${path.module}/values/values-promtail.yaml")
  ]
  depends_on = [helm_release.loki]
}