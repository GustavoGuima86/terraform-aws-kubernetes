resource "aws_db_parameter_group" "rds_parameter_group" {

  name   = var.database_configuration.parameter_group_configs.name
  family = var.database_configuration.parameter_group_configs.family

  # Single default parameter to placeholder
  parameter {
    name  = "log_connections"
    value = 1
  }
}