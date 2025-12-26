# VPC Configuration
variable "vpc_cidr" {
  type        = string
  description = "CIDR of the VPC"
}

variable "vpc_name" {
  type        = string
  default     = "eks-vpc"
  description = "The name of the VPC"
}
variable "cluster_name" {
  type        = string
  description = "The cluster name"
}
