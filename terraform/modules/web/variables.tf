variable "project" {
  description = "Name prefix applied to every resource."
  type        = string
}

variable "vpc_id" {
  description = "VPC to deploy the web hosts into."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the hosts. Linux goes in the first, Windows in the second when there is one."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID is required."
  }
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
  description = "Optional AMI for the Linux host (e.g. the Packer build). Empty means latest Amazon Linux 2023."
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
