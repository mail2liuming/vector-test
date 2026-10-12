output "dns_name" {
  value = aws_lb.this.dns_name
}

output "arn" {
  value = aws_lb.this.arn
}

output "security_group_id" {
  value = aws_security_group.alb.id
}

output "target_group_arn" {
  value = aws_lb_target_group.https.arn
}

output "log_bucket" {
  value = aws_s3_bucket.alb_logs.id
}
