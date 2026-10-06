output "dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "arn" {
  description = "ARN of the ALB."
  value       = aws_lb.this.arn
}

output "security_group_id" {
  description = "Security group of the ALB (allowed into the targets on 443)."
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "HTTPS target group."
  value       = aws_lb_target_group.https.arn
}

output "log_bucket" {
  description = "S3 bucket receiving the ALB access logs."
  value       = aws_s3_bucket.alb_logs.id
}
