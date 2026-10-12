variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two subnets are required."
  }
}

variable "certificate_arn" {
  description = "ACM certificate for the HTTPS listener."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:acm:", var.certificate_arn))
    error_message = "Not an ACM ARN."
  }
}

variable "target_security_group_id" {
  type = string
}

variable "target_instance_ids" {
  type = list(string)
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "log_transition_ia_days" {
  type    = number
  default = 30
}

variable "log_transition_glacier_days" {
  type    = number
  default = 90
}

variable "log_expiration_days" {
  type    = number
  default = 365
}
