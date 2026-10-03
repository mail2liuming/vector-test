# web module

nginx host(s) for the exercise:

- IAM role + instance profile with only `AmazonSSMManagedInstanceCore` (Session Manager access; no other AWS API access needed)
- Security group: 80/443 from `web_ingress_cidrs`; SSH (and WinRM/RDP when Windows is enabled) from `admin_cidrs` only
- Amazon Linux 2023 instance (or `linux_ami_id`, e.g. the Packer AMI): IMDSv2 required, encrypted gp3, detailed monitoring
- Optional Windows Server 2022 instance with a WinRM HTTPS listener bootstrapped by user data, for Ansible

nginx itself is installed and configured by Ansible (`ansible/`), not by this module.

```hcl
module "web" {
  source      = "../../modules/web"
  project     = "vector-test"
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.public_subnet_ids
  admin_cidrs = ["203.0.113.10/32"]
  key_name    = aws_key_pair.admin.key_name
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.6 |
| aws | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm_core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.windows](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_iam_policy_document.ec2_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ssm_parameter.al2023](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.windows2022](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| admin\_cidrs | CIDRs allowed to reach SSH (22), and WinRM (5986) / RDP (3389) when Windows is enabled. | `list(string)` | n/a | yes |
| key\_name | EC2 key pair name for SSH (Linux) and Administrator password encryption (Windows). | `string` | n/a | yes |
| project | Name prefix applied to every resource. | `string` | n/a | yes |
| subnet\_ids | Subnets for the hosts. Linux goes in the first, Windows in the second when there is one. | `list(string)` | n/a | yes |
| vpc\_id | VPC to deploy the web hosts into. | `string` | n/a | yes |
| enable\_windows | Also create a Windows Server 2022 nginx host. | `bool` | `false` | no |
| linux\_ami\_id | Optional AMI for the Linux host (e.g. the Packer build). Empty means latest Amazon Linux 2023. | `string` | `""` | no |
| linux\_instance\_type | Instance type for the Linux nginx host. | `string` | `"t3.micro"` | no |
| web\_ingress\_cidrs | CIDRs allowed to reach nginx on 80/443. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| windows\_instance\_type | Instance type for the Windows nginx host. | `string` | `"t3.medium"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| iam\_role\_arn | IAM role used by the web hosts. |
| instance\_profile\_name | Instance profile of the web hosts (reusable, e.g. for Packer builds). |
| linux\_instance\_id | Instance ID of the Linux host. |
| linux\_public\_dns | Public DNS name of the Linux host. |
| linux\_public\_ip | Public IP of the Linux host. |
| security\_group\_id | Security group attached to the web hosts. |
| windows\_instance\_id | Instance ID of the Windows host, or null. |
| windows\_public\_dns | Public DNS name of the Windows host, or null. |
| windows\_public\_ip | Public IP of the Windows host, or null. |
<!-- END_TF_DOCS -->
