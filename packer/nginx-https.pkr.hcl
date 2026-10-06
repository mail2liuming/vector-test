packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1.1"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# Optional: build inside a specific subnet (e.g. a public subnet of the Terraform VPC).
# Empty uses the account's default VPC.
variable "subnet_id" {
  type    = string
  default = ""
}

locals {
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())
}

source "amazon-ebs" "al2023_nginx" {
  region        = var.region
  instance_type = var.instance_type
  subnet_id     = var.subnet_id != "" ? var.subnet_id : null
  ami_name      = "vector-test-nginx-https-${local.timestamp}"

  associate_public_ip_address = true
  ssh_username                = "ec2-user"
  ssh_clear_authorized_keys   = true # remove Packer's temporary key from the image

  # Packer's temporary security group only allows SSH from the build machine's public IP
  # (the default would be 0.0.0.0/0).
  temporary_security_group_source_public_ip = true

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-kernel-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  imds_support = "v2.0"

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name      = "vector-test-nginx-https"
    Project   = "vector-test"
    BuiltBy   = "packer"
    Role      = "nginx-https" # Terraform finds the newest AMI by this tag
    SourceAMI = "{{ .SourceAMI }}"
  }
}

build {
  sources = ["source.amazon-ebs.al2023_nginx"]

  # Same playbook/role Terraform-created hosts use.
  provisioner "ansible" {
    playbook_file = "${path.root}/../ansible/site.yml"
    groups        = ["linux"]
    user          = "ec2-user"
    use_proxy     = false
    extra_arguments = [
      "--extra-vars", "{\"nginx_server_names\": [\"localhost\"]}", # JSON, so it is a list (key=value would be a string)
    ]
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.root}/../ansible/ansible.cfg",
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]
  }

  # Don't ship one key pair in every instance: wipe it so each instance gets a fresh
  # self-signed cert on first boot (see nginx-selfsigned-firstboot.service).
  provisioner "shell" {
    inline = [
      "sudo rm -f /etc/nginx/ssl/server.key /etc/nginx/ssl/server.crt",
      # Start every instance with clean nginx logs.
      "sudo truncate -s 0 /var/log/nginx/access.log /var/log/nginx/error.log",
      "sudo tee /etc/systemd/system/nginx-selfsigned-firstboot.service >/dev/null <<'EOF'",
      "[Unit]",
      "Description=Generate per-instance self-signed TLS cert for nginx",
      "After=cloud-init.service",
      "Before=nginx.service",
      "ConditionPathExists=!/etc/nginx/ssl/server.crt",
      "",
      "[Service]",
      "Type=oneshot",
      "ExecStart=/usr/bin/bash -c 'H=$(hostname -f); openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj \"/CN=$H\" -addext \"subjectAltName=DNS:$H,DNS:localhost\" -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.crt && chmod 600 /etc/nginx/ssl/server.key'",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo systemctl enable nginx-selfsigned-firstboot.service",
    ]
  }
}
