output "rds_database_secret_arn" {
  value     = aws_db_instance.rds_instance.master_user_secret[0].secret_arn
  sensitive = true
}

output "rds_database_url" {
  value = aws_db_instance.rds_instance.address
}

output "rds_database_port" {
  value = aws_db_instance.rds_instance.port
}