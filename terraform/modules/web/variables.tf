variable "project" {
  description = "Name prefix applied to every resource."
  type        = string
}

variable "vpc_id" {
  description = "VPC to deploy the web hosts into."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets for the Windows host (second one when available)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID is required."
  }
}

variable "linux_subnet_id" {
  description = "Subnet for the Linux host: a public subnet, or a private one when behind_alb is true."
  type        = string
}

variable "behind_alb" {
  description = "Run the Linux host from the Packer AMI in a private subnet, reachable only from the ALB."
  type        = bool
  default     = false
}

variable "alb_security_group_id" {
  description = "Security group of the ALB (required when behind_alb is true)."
  type        = string
  default     = ""
}

variable "admin_cidrs" {
  description = "CIDRs allowed to reach SSH (22), and WinRM (5986) / RDP (3389) when Windows is enabled."
  type        = list(string)
}

variable "web_ingress_cidrs" {
  description = "CIDRs allowed to reach nginx on 80/443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "EC2 key pair name for SSH (Linux) and Administrator password encryption (Windows)."
  type        = string
}

variable "linux_instance_type" {
  description = "Instance type for the Linux nginx host."
  type        = string
  default     = "t3.micro"
}

variable "linux_ami_id" {
  description = "Optional AMI for the Linux host. Empty: newest Packer AMI (tag Role=nginx-https) when behind_alb, else latest Amazon Linux 2023."
  type        = string
  default     = ""
}

variable "enable_windows" {
  description = "Also create a Windows Server 2022 nginx host."
  type        = bool
  default     = false
}

variable "windows_instance_type" {
  description = "Instance type for the Windows nginx host."
  type        = string
  default     = "t3.medium"
}
