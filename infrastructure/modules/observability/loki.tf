resource "aws_s3_bucket" "loki_bucket_chunk" {
  bucket        = local.bucket_loki_chunk
  force_destroy = true

  tags = merge(
    local.tags,
    { Name = "loki-chunk" }
  )
}

resource "aws_s3_bucket" "loki_bucket_ruler" {
  bucket        = local.bucket_loki_ruler
  force_destroy = true

  tags = merge(
    local.tags,
    { Name = "loki-ruler" }
  )
}

resource "aws_iam_policy" "loki_s3_access" {
  name        = "${var.cluster_name}-loki-s3-access"
  description = "Allow Loki to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LokiS3Access"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload"
        ]
        # Ensure these ARNs match exactly what is in your variables
        Resource = [
          "arn:aws:s3:::${local.bucket_loki_chunk}",
          "arn:aws:s3:::${local.bucket_loki_chunk}/*",
          "arn:aws:s3:::${local.bucket_loki_ruler}",
          "arn:aws:s3:::${local.bucket_loki_ruler}/*",
        ]
      }
    ]
  })

  tags = local.tags
}

module "loki_s3_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.7.0"

  name = "${var.cluster_name}-loki-s3"

  additional_policy_arns = {
    loki_s3 = aws_iam_policy.loki_s3_access.arn
  }

  associations = {
    custom-association = {
      cluster_name    = var.cluster_name
      namespace       = var.namespace
      service_account = local.sa_loki_name
    }
  }

  tags = local.tags
}