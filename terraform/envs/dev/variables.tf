variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-southeast-2"
}

variable "project" {
  description = "Name prefix applied to every resource."
  type        = string
  default     = "vector-test"
}

variable "environment" {
  description = "Environment name, applied as a tag."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

variable "enable_nat_gateway" {
  description = "Create a single NAT gateway so private subnets get outbound internet. Off by default to save cost (~USD 45/month)."
  type        = bool
  default     = false
}

variable "admin_cidrs" {
  description = "CIDRs allowed to reach SSH (22), WinRM (5986) and RDP (3389). Empty = auto-detect the public IP of the machine running Terraform (/32)."
  type        = list(string)
  default     = []
}

variable "web_ingress_cidrs" {
  description = "CIDRs allowed to reach nginx on 80/443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "public_key_path" {
  description = "Public half of the automation key pair (RSA, so AWS can encrypt the Windows password). Create with: ssh-keygen -t rsa -b 4096 -m PEM -f ~/.ssh/vector-test"
  type        = string
  default     = "~/.ssh/vector-test.pub"

  validation {
    condition     = can(regex("^ssh-rsa ", file(pathexpand(var.public_key_path))))
    error_message = "public_key_path must point to an existing RSA public key (ssh-rsa ...). Run: ssh-keygen -t rsa -b 4096 -m PEM -f ~/.ssh/vector-test"
  }
}

variable "private_key_path" {
  description = "Path to the matching private key. Terraform never reads it; it is only written into the Ansible inventory."
  type        = string
  default     = "~/.ssh/vector-test"
}

variable "linux_instance_type" {
  description = "Instance type for the Linux nginx host."
  type        = string
  default     = "t3.micro"
}

variable "linux_ami_id" {
  description = "Optional AMI for the Linux host (e.g. the one built by Packer). Empty means latest Amazon Linux 2023."
  type        = string
  default     = ""
}

variable "enable_windows" {
  description = "Also create the Windows Server 2022 nginx host (bonus). Off by default: verify Linux first, then set true."
  type        = bool
  default     = false
}

variable "windows_instance_type" {
  description = "Instance type for the Windows nginx host."
  type        = string
  default     = "t3.medium"
}
