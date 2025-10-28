variable "namespace" {
  description = "The namespace where ArgoCD will be installed"
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_certificate_authority_data" {
  description = "The base64-encoded certificate authority data for the EKS cluster."
  type        = string
}

variable "cluster_endpoint" {
  description = "The API server endpoint for the EKS cluster."
  type        = string
}