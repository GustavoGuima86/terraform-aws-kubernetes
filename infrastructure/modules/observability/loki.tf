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

module "loki_s3_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.5.0"

  name = "${var.cluster_name}-loki-s3"

  policy_statements = [
    {
      sid       = "LokiS3Access"
      effect    = "Allow"
      actions   = [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload"
      ]
      resources = [
        "arn:aws:s3:::${local.bucket_loki_chunk}",
        "arn:aws:s3:::${local.bucket_loki_chunk}/*",
        "arn:aws:s3:::${local.bucket_loki_ruler}",
        "arn:aws:s3:::${local.bucket_loki_ruler}/*",
      ]
    }
  ]
  associations = {
    custom-association = {
      cluster_name    = var.cluster_name
      namespace       = var.namespace
      service_account = local.sa_loki_name
    }
  }

  tags = local.tags
}