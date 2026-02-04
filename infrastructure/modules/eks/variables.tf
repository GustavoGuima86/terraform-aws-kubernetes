# List of private subnet IDs for the EKS cluster VPC
variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs within the VPC for the EKS cluster."
}

# List of internal (intra-cluster) subnet IDs for the EKS cluster VPC
variable "intra_subnets" {
  type        = list(string)
  description = "Optional list of intra-cluster (internal) subnet IDs within the VPC for the EKS cluster."
}

# ID of the VPC where the EKS cluster will be created
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the EKS cluster will be created."
}

# Name for the EKS cluster
variable "cluster_name" {
  type        = string
  description = "The desired name for the EKS cluster."
}

# Secret ARN containing the database credentials for your application
variable "db_secret_arn" {
  type        = string
  description = "The ARN of the AWS Secrets Manager secret containing the database credentials for your application."
}

# Karpenter namespace
variable "karpenter_namespace" {
  type        = string
  default     = "karpenter"
  description = "The Kubernetes namespace where Karpenter will be installed."
}

variable "domain_name" {
  description = "The Route53 domain name to manage"
  type        = string
}