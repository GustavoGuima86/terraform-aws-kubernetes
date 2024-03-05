module "ssm_db_url" {
  source = "../aws-ssm-generic"

  parameter_path = format("/databases/rds/%s/%s", var.database_configuration.db_name, "master_db")
  type           = "String"
  value          = aws_db_instance.rds_instance.address
}
