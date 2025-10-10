resource "aws_s3_bucket" "mimir_bucket_chunk" {
  bucket        = local.bucket_mimir_chunk
  force_destroy = true
}

resource "aws_s3_bucket" "mimir_bucket_ruler" {
  bucket        = local.bucket_mimir_ruler
  force_destroy = true
}

resource "aws_s3_bucket" "mimir_bucket_alert" {
  bucket        = local.bucket_mimir_alert
  force_destroy = true
}

resource "helm_release" "mimir" {
  name       = local.mimir_name
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "mimir-distributed"
  version    = "5.5.1"
  values     = [local.values_mimir]
  depends_on = [helm_release.agent_operator, helm_release.rollout_operator]
}

module "mimir_s3_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "mimir-s3"

  attach_mountpoint_s3_csi_policy    = false

  mountpoint_s3_csi_bucket_arns      = [
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

}

resource "aws_eks_pod_identity_association" "mimir" {
  cluster_name = var.cluster_name
  namespace       = var.namespace
  service_account = local.sa_mimir_name

  role_arn = module.mimir_s3_pod_identity.iam_role_arn
}