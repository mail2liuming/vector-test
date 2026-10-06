output "admin_cidrs" {
  description = "Source CIDRs allowed to SSH / WinRM / RDP."
  value       = local.admin_cidrs
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "instance_profile_name" {
  value = module.web.instance_profile_name
}

output "linux_instance_id" {
  value = module.web.linux_instance_id
}

output "linux_public_ip" {
  value = var.enable_alb ? null : module.web.linux_public_ip
}

output "linux_private_ip" {
  value = module.web.linux_private_ip
}

output "linux_ami_id" {
  value = module.web.linux_ami_id
}

output "linux_url" {
  value = var.enable_alb ? null : "https://${module.web.linux_public_dns}"
}

output "alb_dns_name" {
  value = var.enable_alb ? module.alb[0].dns_name : null
}

output "alb_url" {
  value = var.enable_alb ? "https://${module.alb[0].dns_name}" : null
}

output "alb_target_group_arn" {
  value = var.enable_alb ? module.alb[0].target_group_arn : null
}

output "alb_log_bucket" {
  value = var.enable_alb ? module.alb[0].log_bucket : null
}

output "windows_public_ip" {
  value = module.web.windows_public_ip
}

output "windows_url" {
  value = var.enable_windows ? "https://${module.web.windows_public_dns}" : null
}

output "windows_instance_id" {
  value = module.web.windows_instance_id
}

# --- Access commands ---

output "ssm_linux_shell" {
  description = "Shell on the Linux host via SSM Session Manager (IAM-controlled, no SSH key needed)."
  value       = "aws ssm start-session --region ${var.region} --target ${module.web.linux_instance_id}"
}

output "ssm_windows_rdp_tunnel" {
  description = "Forward RDP over SSM, then connect an RDP client to localhost:13389."
  value = var.enable_windows ? join(" ", [
    "aws ssm start-session --region ${var.region} --target ${module.web.windows_instance_id}",
    "--document-name AWS-StartPortForwardingSession",
    "--parameters portNumber=3389,localPortNumber=13389",
  ]) : null
}

output "windows_password_command" {
  description = "Decrypt the Windows Administrator password locally with the automation key."
  value = var.enable_windows ? join(" ", [
    "aws ec2 get-password-data --region ${var.region} --instance-id ${module.web.windows_instance_id}",
    "--priv-launch-key ${pathexpand(var.private_key_path)} --query PasswordData --output text",
  ]) : null
}

output "ssh_command" {
  description = "Direct SSH with the automation key (admin_cidrs only; not available behind the ALB)."
  value       = var.enable_alb ? null : "ssh -i ${pathexpand(var.private_key_path)} ec2-user@${module.web.linux_public_ip}"
}
