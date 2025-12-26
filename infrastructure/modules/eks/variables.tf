# Desired version of Kubernetes for the EKS cluster (e.g., 1.24)
variable "eks_version" {
  type        = number
  description = "The desired version of Kubernetes for the EKS cluster."
}

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

variable "aws_region" {
  description = "The AWS region where resources are located."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}