variable "project" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "Must be 1 to 3."
  }
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "flow_log_retention_days" {
  type    = number
  default = 14
}
