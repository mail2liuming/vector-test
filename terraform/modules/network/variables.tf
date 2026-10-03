variable "project" {
  description = "Name prefix applied to every resource."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Subnets are carved out as /24s (public from .0, private from .10)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread public and private subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

variable "enable_nat_gateway" {
  description = "Create a single NAT gateway so private subnets get outbound internet (~USD 45/month)."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention for the VPC flow log group."
  type        = number
  default     = 14
}
