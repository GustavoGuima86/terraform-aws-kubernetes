# Mimir S3 Storage Buckets
resource "aws_s3_bucket" "mimir_bucket_chunk" {
  bucket        = local.bucket_mimir_chunk
  force_destroy = true

  tags = merge(
    local.tags,
    { Name = "mimir-chunk" }
  )
}

resource "aws_s3_bucket" "mimir_bucket_ruler" {
  bucket        = local.bucket_mimir_ruler
  force_destroy = true

  tags = merge(
    local.tags,
    { Name = "mimir-ruler" }
  )
}

resource "aws_s3_bucket" "mimir_bucket_alert" {
  bucket        = local.bucket_mimir_alert
  force_destroy = true

  tags = merge(
    local.tags,
    { Name = "mimir-alert" }
  )
}

resource "aws_iam_policy" "mimir_s3_access" {
  name        = "${var.cluster_name}-mimir-s3-access"
  description = "Allow Mimir to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MimirS3Access"
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
          "arn:aws:s3:::${local.bucket_mimir_chunk}",
          "arn:aws:s3:::${local.bucket_mimir_alert}",
          "arn:aws:s3:::${local.bucket_mimir_ruler}",
          "arn:aws:s3:::${local.bucket_mimir_chunk}/*",
          "arn:aws:s3:::${local.bucket_mimir_alert}/*",
          "arn:aws:s3:::${local.bucket_mimir_ruler}/*"
        ]
      }
    ]
  })

  tags = local.tags
}

module "mimir_s3_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.7.0"

  name = "${var.cluster_name}-mimir-s3"

  additional_policy_arns = {
    mimir_s3 = aws_iam_policy.mimir_s3_access.arn
  }

  associations = {
    custom-association = {
      cluster_name    = var.cluster_name
      namespace       = var.namespace
      service_account = local.sa_mimir_name
    }
  }

  tags = local.tags
}