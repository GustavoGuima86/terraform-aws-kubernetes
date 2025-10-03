# Enable EKS + Karpenter rollout (default: false)
variable "enable_eks_karpenter_rollout" {
  description = "Whether to deploy and configure EKS with Karpenter for automated provisioning."
  type        = bool
  default     = false
}

# Enable AWS ALB Controller rollout (default: false)
variable "enable_aws_alb_controller_rollout" {
  description = "Whether to deploy and configure the AWS ALB Controller for managing Application Load Balancers within the EKS cluster."
  type        = bool
  default     = false
}

# Target AWS Region for deployment (required)
variable "targetRegion" {
  description = "The specific AWS Region in which the EKS cluster and related resources will be provisioned."
  type        = string
}

# VPC CIDR block for the EKS cluster (optional)
variable "vpc_cidr" {
  description = "The CIDR block to be used for the VPC created for the EKS cluster. If not provided, a default CIDR will be used."
  type        = string
}

# VPC name for the EKS cluster (optional)
variable "vpc_name" {
  description = "A custom name for the VPC created for the EKS cluster. If not provided, a default name will be generated."
  type        = string
}

# EKS Cluster Version (optional)
variable "eks_version" {
  description = "The desired version of EKS to be used for the cluster. If not provided, the latest recommended version will be used."
  type        = string
}

# Environment Settings - These variables are likely specific to your project and may need adjustment

# Namespaces to be created within the EKS cluster (optional)
variable "namespaces" {
  description = "A comma-separated list of namespaces to be created within the EKS cluster."
  type        = string
}

# Namespace labeling configuration (optional)
variable "namespace_labeling" {
  description = "A key-value pair to be used as a label for all created namespaces (example: environment=staging)."
  type        = string
}

# Auth role ARN for SSO (optional)
variable "auth_role_sso" {
  description = "The ARN of the IAM role used for Single Sign-On (SSO) authentication with EKS."
  type        = string
}

# Cluster name (optional)
variable "cluster_name" {
  description = "A custom name for the EKS cluster. If not provided, a default name will be generated."
  type        = string
}

# Service name (optional)
variable "service_name" {
  description = "A custom name for the service within the EKS cluster (likely specific to your application)."
  type        = string
}

variable "observability_namespace" {
  type        = string
  default     = "monitoring"
  description = "The namespace to use for Kubernetes resources within the EKS cluster."
}

variable "loki_bucket_name" {
  type    = string
  default = "loki-bucket"
}

variable "mimir_bucket_name" {
  type    = string
  default = "mimir-bucket"
}


variable "database_configurations" {
  type = object({
    db_name        = string # the Db name
    engine         = string # The database engine, eg: postgres, mysql
    engine_version = number
    port           = number # The DB port
    instance_class = string # Define the instance type for the instances, must verify the compatibility per engine
    storage = object({
      type       = string # Define the storage type for the database
      iops       = number # Define the IOPS for the storage
      throughput = number # Define the throughput for the storage
      size       = number # Define the size of the storage
    })
    DANGEROUS_disable_deletion_protection = bool         # Define if there is deletion protection for the database
    DANGEROUS_skip_final_snapshot         = bool         # Define if when deleting the DB is needed to take a snapshot
    master_username                       = string       # The master user name
    performance_insights                  = bool         # Enable the performance insight to improve the observability
    enabled_cloudwatch_logs_exports       = list(string) # The log export
    monitoring_interval                   = number       # The interval of enhanced monitoring, if 0 enhanced disables
    backup_retention_period               = number       # Amount of the days that a backup will be retained
    backup_window                         = string       # The backup window to execute
    maintenance_window                    = string       # The maintenance window
    apply_immediately                     = bool         # Define if the changes in the database will be applied immediately or in the maintenance windows
    parameter_group_configs = object({
      family = string # The family of the parameter group
      name   = string # The name of the parameter group
    })
    multi_az            = bool # Define if the instance is allowed to be multi-az
    publicly_accessible = bool # Enable public access by assuming public ip
  })
  description = "Configuration for the database setup"
}