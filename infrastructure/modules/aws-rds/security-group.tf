resource "aws_security_group" "rds_sg" {
  name        = "${var.database_configuration.db_name}-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.database_configuration.port
    to_port     = var.database_configuration.port
    protocol    = "tcp"
    cidr_blocks = var.database_configuration.publicly_accessible ? ["0.0.0.0/0"] : var.subnet_private_cidrs
  }

}
