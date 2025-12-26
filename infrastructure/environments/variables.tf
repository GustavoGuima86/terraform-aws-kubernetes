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
# Cluster name (optional)
variable "cluster_name" {
  description = "A custom name for the EKS cluster. If not provided, a default name will be generated."
  type        = string
}

variable "observability_namespace" {
  type        = string
  default     = "monitoring"
  description = "The namespace to use for observability stack resources."
}

variable "loki_bucket_name" {
  type        = string
  default     = "loki-bucket"
  description = "Base name for Loki S3 buckets"
}

variable "mimir_bucket_name" {
  type        = string
  default     = "mimir-bucket"
  description = "Base name for Mimir S3 buckets"
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

variable "aws_region" {
  description = "The AWS region where resources are located."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
