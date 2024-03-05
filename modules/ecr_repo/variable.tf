# variables.tf

variable "service_name" {
  type        = string
  description = "(Required) Name of the repository. {project_family}/{environment}/{name}."
}


variable "expiration_after_days" {
  type        = number
  description = "(Optional) Delete images older than X days."
  default     = 0
}