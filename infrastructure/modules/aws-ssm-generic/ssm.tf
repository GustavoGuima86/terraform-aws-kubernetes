resource "aws_ssm_parameter" "ssm_parameter" {
  name            = var.parameter_path
  type            = var.type
  value           = var.value
  allowed_pattern = ".+"
}