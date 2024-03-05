# Enable Karpenter rollout for automatic node provisioning in EKS cluster
variable "enable_eks_karpenter_rollout" {
  type        = bool
  description = "Whether to enable Karpenter for automatic node provisioning in the EKS cluster."
}

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

# The Kubernetes namespace to use for resources (e.g., "my-app")
variable "namespace" {
  type        = string
  description = "The namespace to use for Kubernetes resources within the EKS cluster."
}

# Optional string for labeling the namespace (e.g., "environment=prod")
variable "namespace_labeling" {
  type        = string
  description = "Optional string for labeling the Kubernetes namespace (e.g., environment=prod)."
}

# CIDR block for the VPC where the EKS cluster will be created
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC where the EKS cluster will be created."
}

# Enable rollout of the AWS ALB Ingress Controller in the EKS cluster
variable "enable_aws_alb_controller_rollout" {
  type        = string
  description = "Whether to enable the rollout of the AWS ALB Ingress Controller in the EKS cluster (true or false)."
}

# The AWS region where the EKS cluster will be created
variable "targetRegion" {
  type        = string
  description = "The AWS region where the EKS cluster will be created."
}

# Name for the EKS cluster
variable "cluster_name" {
  type        = string
  description = "The desired name for the EKS cluster."
}

# ARN of the IAM role used for SSO authentication with EKS cluster
variable "auth_role_sso" {
  type        = string
  description = "The ARN of the IAM role used for Single Sign-On (SSO) authentication with the EKS cluster."
}

# Secret ARN containing the database credentials for your application
variable "db_secret_arn" {
  type        = string
  description = "The ARN of the AWS Secrets Manager secret containing the database credentials for your application."
}

# URL of the database for your application
variable "db_url" {
  type        = string
  description = "The URL of the database for your application (e.g., hostname:port)."
}

# Port number of the database for your application
variable "db_port" {
  type        = string
  description = "The port number of the database for your application."
}
