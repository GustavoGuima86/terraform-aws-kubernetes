variable "cluster_name" {
  type        = string
  description = "EKS cluster name for Pod Identity association"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for observability tools"
}

variable "loki_bucket_name" {
  type        = string
  description = "Base name for Loki S3 buckets (account ID will be appended)"
}

variable "mimir_bucket_name" {
  type        = string
  description = "Base name for Mimir S3 buckets (account ID will be appended)"
}