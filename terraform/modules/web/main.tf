# ------------------------------------------------------------------ IAM

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "${var.project}-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Session Manager access (shell without opening SSH) and SSM inventory/patching.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.project}-web-profile"
  role = aws_iam_role.web.name
}

# ------------------------------------------------------- Security group

resource "aws_security_group" "web" {
  name        = "${var.project}-web-sg"
  description = "nginx web hosts: HTTP/HTTPS from web_ingress_cidrs, admin ports from admin_cidrs"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project}-web-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = toset(var.web_ingress_cidrs)

  security_group_id = aws_security_group.web.id
  description       = "HTTPS"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# Port 80 only redirects to HTTPS.
resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.web_ingress_cidrs)

  security_group_id = aws_security_group.web.id
  description       = "HTTP (redirects to HTTPS)"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

locals {
  # WinRM/RDP are only opened when the Windows host exists.
  admin_ports = merge(
    { ssh = 22 },
    var.enable_windows ? { winrm = 5986, rdp = 3389 } : {},
  )
  admin_rules = {
    for pair in setproduct(keys(local.admin_ports), var.admin_cidrs) :
    "${pair[0]}-${pair[1]}" => { port = local.admin_ports[pair[0]], cidr = pair[1], name = pair[0] }
  }
}

resource "aws_vpc_security_group_ingress_rule" "admin" {
  for_each = local.admin_rules

  security_group_id = aws_security_group.web.id
  description       = upper(each.value.name)
  cidr_ipv4         = each.value.cidr
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "Outbound (package repos, nginx download, SSM)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ------------------------------------------------------------- Instances

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "windows2022" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

# ---------------------------------------------------------------- Linux host

resource "aws_instance" "linux" {
  ami                    = var.linux_ami_id != "" ? var.linux_ami_id : nonsensitive(data.aws_ssm_parameter.al2023.value)
  instance_type          = var.linux_instance_type
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name
  key_name               = var.key_name
  ebs_optimized          = true
  monitoring             = true # 1-minute CloudWatch metrics

  metadata_options {
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "${var.project}-nginx-linux" }

  lifecycle {
    ignore_changes = [ami] # don't replace the host when a newer AL2023 is published
  }
}

# --------------------------------------------------------------- Windows host

resource "aws_instance" "windows" {
  count = var.enable_windows ? 1 : 0

  ami                    = nonsensitive(data.aws_ssm_parameter.windows2022.value)
  instance_type          = var.windows_instance_type
  subnet_id              = var.subnet_ids[min(1, length(var.subnet_ids) - 1)] # second AZ when available
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name
  key_name               = var.key_name # Administrator password is encrypted with this key; fetched by Ansible
  ebs_optimized          = true
  monitoring             = true

  # Enable a WinRM HTTPS listener so Ansible can connect.
  user_data = file("${path.module}/templates/windows-winrm.ps1")

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = { Name = "${var.project}-nginx-windows" }

  lifecycle {
    ignore_changes = [ami]
  }
}
