variable "parameter_path" {
  type        = string
  description = "The Path of the parameter"
}
variable "type" {
  type        = string
  default     = "SecureString"
  description = "SSM type eg, String, StringList or SecureString"
}
variable "value" {
  type    = string
  default = "Value to be stored "
}