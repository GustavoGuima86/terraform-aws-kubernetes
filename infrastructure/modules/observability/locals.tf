locals {
  # S3 Bucket Names
  bucket_loki_chunk = "${var.loki_bucket_name}-chunk-${data.aws_caller_identity.current.account_id}"
  bucket_loki_ruler = "${var.loki_bucket_name}-ruler-${data.aws_caller_identity.current.account_id}"

  bucket_mimir_chunk = "${var.mimir_bucket_name}-chunk-${data.aws_caller_identity.current.account_id}"
  bucket_mimir_ruler = "${var.mimir_bucket_name}-ruler-${data.aws_caller_identity.current.account_id}"
  bucket_mimir_alert = "${var.mimir_bucket_name}-alert-${data.aws_caller_identity.current.account_id}"

  # Service Account Names
  sa_loki_name  = "loki-sa"
  sa_mimir_name = "mimir-sa"

  # Common Tags
  tags = {
    ManagedBy   = "Terraform"
    Environment = "observability"
  }
}


