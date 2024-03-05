variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}
variable "namespace" {
  description = "kubernetes namepspace where application is deployed to"
  type        = string
  default     = "kube-system"
}

variable "eks_open_id_connect_provider_url" {
  description = "url to the eks openid connect provider"
  type        = string
}

variable "service_account_name" {
  description = "kubernetes service account for the application"
  type        = string
  default     = "external-secrets"
}

variable "account_owner_id" {
  description = "aws account owner id"
  type        = string
}

variable "aws_region" {
  description = "aws region"
  type        = string
}

locals {
  ebs_csi_iam_role                          = join("-", [var.cluster_name, "ebs-csi"])
  ebs_csi_kms_key_name                      = join("-", [var.cluster_name, "ebs-csi"])
  eks_open_id_connect_provider_url_replaced = replace(var.eks_open_id_connect_provider_url, "https://", "")
}