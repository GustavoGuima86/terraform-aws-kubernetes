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

  name = "${var.cluster_name}-loki-s3"

  attach_mountpoint_s3_csi_policy = true

  mountpoint_s3_csi_bucket_arns = [
    "arn:aws:s3:::${local.bucket_loki_chunk}",
    "arn:aws:s3:::${local.bucket_loki_ruler}",
  ]
  mountpoint_s3_csi_bucket_path_arns = [
    "arn:aws:s3:::${local.bucket_loki_chunk}/*",
    "arn:aws:s3:::${local.bucket_loki_ruler}/*",
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

resource "aws_eks_pod_identity_association" "loki" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = local.sa_loki_name

  role_arn = module.loki_s3_pod_identity.iam_role_arn

  tags = local.tags
}