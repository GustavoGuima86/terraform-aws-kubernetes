variable "database_configuration" {
  type = object({
    db_name        = string # the Db name
    engine         = string # The database engine, eg: postgres, mysql
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

  default = {
    db_name        = "cashlinkDB"
    engine         = "postgres"
    port           = 5432
    instance_class = ""
    storage = {
      type       = "gp3"
      iops       = 3000
      throughput = 125
      size       = 20
    }
    DANGEROUS_disable_deletion_protection = true
    DANGEROUS_skip_final_snapshot         = false
    master_username                       = "cashlink_user"
    master_password                       = ""
    performance_insights                  = false
    enabled_cloudwatch_logs_exports       = []
    monitoring_interval                   = 0
    backup_retention_period               = 7
    backup_window                         = ""
    maintenance_window                    = ""
    apply_immediately                     = false
    parameter_group_configs = {
      family = "postgres16"
      name   = "cashlinkPG"
    }
    multi_az            = false
    publicly_accessible = false
    database_config     = []
  }

  description = "Configuration for the database setup"
}

variable "public_subnet_ids" {
  # A list of IDs for the public subnets in your VPC. These subnets have internet gateway access and can be used to host resources that need to be accessed from the public internet.
  type        = list(string)
  description = "IDs of the public subnets in the VPC"
}

variable "private_subnet_ids" {
  # A list of IDs for the private subnets in your VPC. These subnets do not have internet gateway access and are typically used to host resources that do not need to be accessed from the public internet.
  type        = list(string)
  description = "IDs of the private subnets in the VPC"
}

variable "subnet_private_cidrs" {
  # A list of CIDR blocks for the subnets in your VPC. Each element in the list should correspond to a public or private subnet ID in the respective lists.
  type        = list(string)
  description = "CIDR blocks for the subnets in the VPC"
}

variable "vpc_id" {
  # The ID of the VPC in which to create the subnets.
  type        = string
  description = "ID of the VPC where the subnets will be created"
}
