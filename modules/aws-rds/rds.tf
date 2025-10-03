resource "aws_db_instance" "rds_instance" {
  identifier                  = var.database_configuration.db_name
  db_name                     = var.database_configuration.db_name
  port                        = var.database_configuration.port
  engine                      = var.database_configuration.engine
  engine_version = var.database_configuration.engine_version
  instance_class              = var.database_configuration.instance_class
  username                    = var.database_configuration.master_username
  manage_master_user_password = true

  allocated_storage  = var.database_configuration.storage.size
  storage_type       = var.database_configuration.storage.type
  iops               = var.database_configuration.storage.size >= 400 ? var.database_configuration.storage.iops : null
  storage_throughput = var.database_configuration.storage.size >= 400 ? var.database_configuration.storage.throughput : null

  performance_insights_enabled    = var.database_configuration.performance_insights
  monitoring_interval             = var.database_configuration.monitoring_interval
  monitoring_role_arn             = aws_iam_role.rds_enhanced_monitoring.arn
  enabled_cloudwatch_logs_exports = var.database_configuration.enabled_cloudwatch_logs_exports

  deletion_protection = var.database_configuration.DANGEROUS_disable_deletion_protection
  skip_final_snapshot = var.database_configuration.DANGEROUS_skip_final_snapshot

  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  apply_immediately       = var.database_configuration.apply_immediately
  backup_retention_period = var.database_configuration.backup_retention_period
  backup_window           = var.database_configuration.backup_window
  maintenance_window      = var.database_configuration.maintenance_window

  multi_az            = var.database_configuration.multi_az
  publicly_accessible = var.database_configuration.publicly_accessible

  parameter_group_name = aws_db_parameter_group.rds_parameter_group.name
}

resource "aws_db_subnet_group" "rds_subnets" {
  subnet_ids = var.database_configuration.publicly_accessible ? var.public_subnet_ids : var.private_subnet_ids

}