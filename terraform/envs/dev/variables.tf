variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "project" {
  type    = string
  default = "vector-test"
}

variable "environment" {
  type    = string
  default = "dev"
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

variable "admin_cidrs" {
  description = "Default: your current public IP."
  type        = list(string)
  default     = []
}

variable "web_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "public_key_path" {
  description = "RSA key, needed to decrypt the Windows password."
  type        = string
  default     = "~/.ssh/vector-test.pub"

  validation {
    condition     = can(regex("^ssh-rsa ", file(pathexpand(var.public_key_path))))
    error_message = "RSA public key not found."
  }
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/vector-test"
}

variable "linux_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "linux_ami_id" {
  description = "Default: Packer AMI with enable_alb, else latest Amazon Linux 2023."
  type        = string
  default     = ""
}

variable "enable_alb" {
  description = "Linux from the Packer AMI in a private subnet behind an ALB."
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "Required when enable_alb is true."
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
