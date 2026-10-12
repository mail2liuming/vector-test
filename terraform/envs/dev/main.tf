locals {
  repo_root = "${path.module}/../../.."

  admin_cidrs = length(var.admin_cidrs) > 0 ? var.admin_cidrs : ["${chomp(data.http.my_ip[0].response_body)}/32"]
}

data "http" "my_ip" {
  count = length(var.admin_cidrs) > 0 ? 0 : 1
  url   = "https://checkip.amazonaws.com"

  lifecycle {
    postcondition {
      condition     = can(cidrhost("${chomp(self.response_body)}/32", 0))
      error_message = "Could not detect your IP."
    }
  }
}

module "network" {
  source = "../../modules/network"

  project            = var.project
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway || var.enable_alb
}

module "web" {
  source = "../../modules/web"

  project           = var.project
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  linux_subnet_id   = var.enable_alb ? module.network.private_subnet_ids[0] : module.network.public_subnet_ids[0]
  admin_cidrs       = local.admin_cidrs
  web_ingress_cidrs = var.web_ingress_cidrs
  key_name          = aws_key_pair.admin.key_name

  linux_instance_type   = var.linux_instance_type
  linux_ami_id          = var.linux_ami_id
  enable_windows        = var.enable_windows
  windows_instance_type = var.windows_instance_type

  behind_alb            = var.enable_alb
  alb_security_group_id = var.enable_alb ? module.alb[0].security_group_id : ""
}

module "alb" {
  source = "../../modules/alb"
  count  = var.enable_alb ? 1 : 0

  project                  = var.project
  vpc_id                   = module.network.vpc_id
  public_subnet_ids        = module.network.public_subnet_ids
  certificate_arn          = var.alb_certificate_arn
  target_security_group_id = module.web.linux_security_group_id
  target_instance_ids      = [module.web.linux_instance_id]
}

resource "aws_key_pair" "admin" {
  key_name   = "${var.project}-admin"
  public_key = trimspace(file(pathexpand(var.public_key_path)))
}

resource "local_file" "ansible_inventory" {
  filename        = "${local.repo_root}/ansible/inventory/hosts.yml"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/inventory.yml.tftpl", {
    aws_region          = var.region
    private_key_path    = pathexpand(var.private_key_path)
    enable_linux        = !var.enable_alb
    linux_ip            = module.web.linux_public_ip
    linux_dns           = module.web.linux_public_dns
    enable_windows      = var.enable_windows
    windows_ip          = var.enable_windows ? module.web.windows_public_ip : ""
    windows_dns         = var.enable_windows ? module.web.windows_public_dns : ""
    windows_instance_id = var.enable_windows ? module.web.windows_instance_id : ""
  })
}
