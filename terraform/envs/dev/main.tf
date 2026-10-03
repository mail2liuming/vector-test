locals {
  repo_root = "${path.module}/../../.."

  # Admin ports are opened to the caller's own IP unless admin_cidrs is given explicitly.
  admin_cidrs = length(var.admin_cidrs) > 0 ? var.admin_cidrs : ["${chomp(data.http.my_ip[0].response_body)}/32"]
}

data "http" "my_ip" {
  count = length(var.admin_cidrs) > 0 ? 0 : 1
  url   = "https://checkip.amazonaws.com"

  lifecycle {
    postcondition {
      condition     = can(cidrhost("${chomp(self.response_body)}/32", 0))
      error_message = "Could not detect your public IP; set admin_cidrs in terraform.tfvars."
    }
  }
}

module "network" {
  source = "../../modules/network"

  project            = var.project
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
}

module "web" {
  source = "../../modules/web"

  project           = var.project
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids # nginx must be reachable directly over HTTPS
  admin_cidrs       = local.admin_cidrs
  web_ingress_cidrs = var.web_ingress_cidrs
  key_name          = aws_key_pair.admin.key_name

  linux_instance_type   = var.linux_instance_type
  linux_ami_id          = var.linux_ami_id
  enable_windows        = var.enable_windows
  windows_instance_type = var.windows_instance_type
}

# ------------------------------------------------------------- Key pair
# Bring-your-own key: only the PUBLIC key is read here, so no private key or Windows password
# ever lands in Terraform state. The key is for automation (Ansible); people log in with
# SSM Session Manager (see the ssm_* outputs).

resource "aws_key_pair" "admin" {
  key_name   = "${var.project}-admin"
  public_key = trimspace(file(pathexpand(var.public_key_path)))
}

# ---------------------------------------------------- Ansible inventory
# Contains no secrets: the Windows password is fetched by Ansible at run time.

resource "local_file" "ansible_inventory" {
  filename        = "${local.repo_root}/ansible/inventory/hosts.yml"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/inventory.yml.tftpl", {
    aws_region          = var.region
    private_key_path    = pathexpand(var.private_key_path)
    linux_ip            = module.web.linux_public_ip
    linux_dns           = module.web.linux_public_dns
    enable_windows      = var.enable_windows
    windows_ip          = var.enable_windows ? module.web.windows_public_ip : ""
    windows_dns         = var.enable_windows ? module.web.windows_public_dns : ""
    windows_instance_id = var.enable_windows ? module.web.windows_instance_id : ""
  })
}
