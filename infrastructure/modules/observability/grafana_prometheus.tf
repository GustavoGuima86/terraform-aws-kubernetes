# Generate and store Grafana admin password
resource "random_password" "password_grafana" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]<>:?"
}

# Store password in AWS SSM Parameter Store for later retrieval
resource "aws_ssm_parameter" "password_grafana" {
  name  = "Password_Grafana"
  type  = "String"
  value = random_password.password_grafana.result

  tags = {
    Description = "Grafana admin password"
  }
}
