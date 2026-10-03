# Further improvements

Kept out of scope to match the brief; how each would be done in a real environment:

| Area | Current | Improvement |
|---|---|---|
| **Load balancer / TLS** | nginx serves its own self-signed cert on a public instance (what the brief asks for) | ALB in the public subnets with an ACM certificate, 80→443 redirect at the ALB, access logs to an encrypted S3 bucket with lifecycle; ALB → nginx still over HTTPS; `/health` endpoint for target-group health checks |
| **Private subnets / NAT** | Private subnets exist but are unused; NAT off (cost) | Web hosts move to private subnets behind the ALB; outbound via a NAT gateway per AZ (or interface endpoints for SSM/CloudWatch/ECR) |
| **Scaling / deployment** | Single EC2 per OS | Launch template + Auto Scaling Group (configurable size) from the Packer AMI; roll out new AMIs with instance refresh / blue-green |
| **Admin access (SSM)** | SSH / WinRM / RDP open to the deployer's IP only. The role already allows SSM and the instances register as Online | Make SSM Session Manager the only access path (no inbound admin ports, IAM-controlled, audited); Ansible over the `aws_ssm` connection; Packer with `ssh_interface = "session_manager"` |
| **SSH key** | Manually created RSA key on the deployer's machine – can be lost and isn't shared with the team | Remove the manual step: run Ansible and Packer over SSM (no SSH key at all), people use SSM / EC2 Instance Connect; if a key is still needed, keep it in Secrets Manager and have the pipeline fetch it via its IAM role; key rotation |
| **CI/CD** | Run manually from a laptop | Pipeline (e.g. GitHub Actions): on PR run fmt/validate/tflint/Checkov/ansible-lint/packer validate and post `terraform plan`; on merge `apply` behind a manual approval; AWS access via OIDC role (no stored keys); Packer built by a runner inside the VPC |
| **Terraform state** | Local state | S3 backend with encryption, versioning and native locking (commented example in `terraform/envs/dev/backend.tf`); one state per environment |
| **Environments** | `envs/dev` only | `envs/staging`, `envs/prod`; modules versioned in their own repo; Terragrunt once there are many envs/accounts |
| **Logging / monitoring** | VPC flow logs; nginx logs stay on the host; Windows nginx logs are not rotated | CloudWatch agent (baked into the AMI) shipping nginx logs, metric filters + alarms on 5xx; KMS-encrypted log groups with longer retention; Windows log rotation |
| **Windows image** | Windows configured after launch (Terraform + Ansible over WinRM) | Windows AMI via Packer with the WinRM communicator and EC2Launch sysprep |
| **Certificates** | Self-signed | ACM (public) or a private CA; automatic renewal |
| **Accounts / governance** | Single account, IAM user | AWS Organizations with separate accounts per environment, SCP guardrails, SSO for people, budgets/alerts |

# Fixes found during the real runs

Issues that only showed up when deploying to AWS, and how they were fixed:

| # | Problem | Fix | File |
|---|---|---|---|
| 1 | On Windows, `nginx -s reload` failed with `OpenEvent("Global\ngx_reload_…") failed (5: Access is denied)`: nginx runs as **SYSTEM** (scheduled task), and the Ansible WinRM login (Administrator) is not allowed to signal it | The Windows reload handler now restarts nginx through its scheduled task (stop the nginx processes, start the task, check it is running). Verified by introducing config drift: Ansible restored the config, the handler restarted nginx and the HTTPS self-test passed | `ansible/roles/nginx/handlers/main.yml` |
| 2 | Ansible deprecation warning: top-level fact variables such as `ansible_os_family` will stop being injected (removed in ansible-core 2.24) | The role reads `ansible_facts['os_family']` instead | `ansible/roles/nginx/tasks/main.yml`, `templates/servers.conf.j2`, `templates/index.html.j2` |
| 3 | Packer passed `nginx_server_names=['localhost']` as a `key=value` extra var, which Ansible treats as a **string**, not a list – the certificate SANs would have been built from single characters | Extra vars passed as JSON (`{"nginx_server_names": ["localhost"]}`) so the role gets a real list | `packer/nginx-https.pkr.hcl` |
