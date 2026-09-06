resource "aws_s3_bucket" "velero_bucket" {
  bucket        = local.velero_bucket
  force_destroy = true
}


module "velero_s3_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.9.0"

  name = "${var.cluster_name}-velero-s3"

  attach_velero_policy         = true
  velero_s3_bucket_arns        = [aws_s3_bucket.velero_bucket.arn]
  velero_s3_bucket_path_arns   = ["${aws_s3_bucket.velero_bucket.arn}/*"]

  associations = {
    custom-association = {
      cluster_name    = var.cluster_name
      namespace       = local.velero_sa_namespace
      service_account = local.velero_sa_name
    }
  }
  depends_on = [module.eks]
}


