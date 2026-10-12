output "security_group_id" {
  value = aws_security_group.web.id
}

output "iam_role_arn" {
  value = aws_iam_role.web.arn
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.web.name
}

output "linux_instance_id" {
  value = aws_instance.linux.id
}

output "linux_public_ip" {
  value = aws_instance.linux.public_ip
}

output "linux_private_ip" {
  value = aws_instance.linux.private_ip
}

output "linux_security_group_id" {
  value = var.behind_alb ? aws_security_group.alb_target[0].id : aws_security_group.web.id
}

output "linux_ami_id" {
  value = aws_instance.linux.ami
}

output "linux_public_dns" {
  value = aws_instance.linux.public_dns
}

output "windows_instance_id" {
  value = var.enable_windows ? aws_instance.windows[0].id : null
}

output "windows_public_ip" {
  value = var.enable_windows ? aws_instance.windows[0].public_ip : null
}

output "windows_public_dns" {
  value = var.enable_windows ? aws_instance.windows[0].public_dns : null
}
