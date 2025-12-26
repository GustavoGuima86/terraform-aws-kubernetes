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

# Mimir Pod Identity for S3 Access
module "mimir_s3_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "${var.cluster_name}-mimir-s3"

  attach_mountpoint_s3_csi_policy = true

  mountpoint_s3_csi_bucket_arns = [
    "arn:aws:s3:::${local.bucket_mimir_chunk}",
    "arn:aws:s3:::${local.bucket_mimir_alert}",
    "arn:aws:s3:::${local.bucket_mimir_ruler}"
  ]
  mountpoint_s3_csi_bucket_path_arns = [
    "arn:aws:s3:::${local.bucket_mimir_chunk}/*",
    "arn:aws:s3:::${local.bucket_mimir_alert}/*",
    "arn:aws:s3:::${local.bucket_mimir_ruler}/*"
  ]

  trust_policy_statements = [
    {
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["pods.eks.amazonaws.com"]
        }
      ]
      actions = ["sts:AssumeRole"]
    }
  ]

  tags = local.tags
}

# Mimir Pod Identity Association
resource "aws_eks_pod_identity_association" "mimir" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = local.sa_mimir_name

  role_arn = module.mimir_s3_pod_identity.iam_role_arn

  tags = local.tags
}