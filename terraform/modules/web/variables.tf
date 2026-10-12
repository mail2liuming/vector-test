variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Public subnets for the Windows host."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet is required."
  }
}

variable "linux_subnet_id" {
  type = string
}

variable "behind_alb" {
  description = "Private subnet, Packer AMI, HTTPS from the ALB only."
  type        = bool
  default     = false
}

variable "alb_security_group_id" {
  description = "Required when behind_alb is true."
  type        = string
  default     = ""
}

variable "admin_cidrs" {
  type = list(string)
}

variable "web_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "key_name" {
  type = string
}

variable "linux_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "linux_ami_id" {
  description = "Default: Packer AMI with behind_alb, else latest Amazon Linux 2023."
  type        = string
  default     = ""
}

variable "enable_windows" {
  type    = bool
  default = false
}

variable "windows_instance_type" {
  type    = string
  default = "t3.medium"
}
