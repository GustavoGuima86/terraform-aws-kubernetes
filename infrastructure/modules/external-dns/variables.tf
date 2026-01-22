variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}


variable "namespace" {
  description = "The Kubernetes namespace for external-dns"
  type        = string
  default     = "external-dns"
}

variable "service_account_name" {
  description = "The name of the Kubernetes service account"
  type        = string
  default     = "external-dns"
}

variable "domain_name" {
  description = "The Route53 domain name to manage"
  type        = string
}