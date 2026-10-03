output "security_group_id" {
  description = "Security group attached to the web hosts."
  value       = aws_security_group.web.id
}

output "iam_role_arn" {
  description = "IAM role used by the web hosts."
  value       = aws_iam_role.web.arn
}

output "instance_profile_name" {
  description = "Instance profile of the web hosts (reusable, e.g. for Packer builds)."
  value       = aws_iam_instance_profile.web.name
}

output "linux_instance_id" {
  description = "Instance ID of the Linux host."
  value       = aws_instance.linux.id
}

output "linux_public_ip" {
  description = "Public IP of the Linux host."
  value       = aws_instance.linux.public_ip
}

output "linux_public_dns" {
  description = "Public DNS name of the Linux host."
  value       = aws_instance.linux.public_dns
}

output "windows_instance_id" {
  description = "Instance ID of the Windows host, or null."
  value       = var.enable_windows ? aws_instance.windows[0].id : null
}

output "windows_public_ip" {
  description = "Public IP of the Windows host, or null."
  value       = var.enable_windows ? aws_instance.windows[0].public_ip : null
}

output "windows_public_dns" {
  description = "Public DNS name of the Windows host, or null."
  value       = var.enable_windows ? aws_instance.windows[0].public_dns : null
}
