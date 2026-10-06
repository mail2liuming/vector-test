variable "project" {
  description = "Name prefix applied to every resource."
  type        = string
}

variable "vpc_id" {
  description = "VPC the load balancer and target group live in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB (at least two AZs)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "An ALB needs subnets in at least two availability zones."
  }
}

variable "certificate_arn" {
  description = "ACM certificate for the HTTPS listener (self-signed cert imported with scripts/alb-selfsigned-cert.sh)."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:acm:", var.certificate_arn))
    error_message = "certificate_arn must be an ACM certificate ARN. Run scripts/alb-selfsigned-cert.sh to create one."
  }
}

variable "target_security_group_id" {
  description = "Security group of the targets; the ALB may only send HTTPS to it."
  type        = string
}

variable "target_instance_ids" {
  description = "EC2 instances to register in the target group."
  type        = list(string)
}

variable "deletion_protection" {
  description = "Protect the ALB from deletion. Off so the demo can be destroyed."
  type        = bool
  default     = false
}

variable "log_transition_ia_days" {
  description = "Move access logs to S3 Standard-IA after this many days."
  type        = number
  default     = 30
}

variable "log_transition_glacier_days" {
  description = "Move access logs to S3 Glacier Instant Retrieval after this many days."
  type        = number
  default     = 90
}

variable "log_expiration_days" {
  description = "Delete access logs after this many days."
  type        = number
  default     = 365
}
