resource "aws_s3_bucket" "velero_bucket" {
  bucket        = local.velero_bucket
  force_destroy = true
}


module "velero_s3_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.5.0"

  attach_velero_policy       = true

  velero_s3_bucket_arns = [aws_s3_bucket.velero_bucket.arn]

  associations = {
    custom-association = {
      cluster_name    = var.cluster_name
      namespace       = "velero"
      service_account = "velero_sa"
    }
  }
}

output "velero_bucket_name" {
  description = "The name of the Velero S3 bucket."
  value       = aws_s3_bucket.velero_bucket.bucket
}

output "velero_bucket_region" {
  description = "The region of the Velero S3 bucket."
  value       = aws_s3_bucket.velero_bucket.region
}
