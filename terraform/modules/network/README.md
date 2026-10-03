# network module

Two-tier VPC for EC2 workloads:

- VPC with DNS support/hostnames
- Public `/24` subnet per AZ (auto-assign public IP) routed to an Internet Gateway
- Private `/24` subnet per AZ, outbound via an optional single NAT gateway
- Free S3 gateway endpoint on both route tables
- VPC flow logs to CloudWatch (dedicated IAM role scoped to that log group)
- Default security group stripped of all rules

```hcl
module "network" {
  source             = "../../modules/network"
  project            = "vector-test"
  vpc_cidr           = "10.20.0.0/16"
  az_count           = 2
  enable_nat_gateway = false
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
| [aws_cloudwatch_log_group.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy_document.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_logs_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| project | Name prefix applied to every resource. | `string` | n/a | yes |
| az\_count | Number of availability zones to spread public and private subnets across. | `number` | `2` | no |
| enable\_nat\_gateway | Create a single NAT gateway so private subnets get outbound internet (~USD 45/month). | `bool` | `false` | no |
| flow\_log\_retention\_days | Retention for the VPC flow log group. | `number` | `14` | no |
| vpc\_cidr | CIDR block for the VPC. Subnets are carved out as /24s (public from .0, private from .10). | `string` | `"10.20.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| availability\_zones | AZs the subnets are spread across (same order as the subnet ID lists). |
| nat\_gateway\_id | NAT gateway ID, or null when enable\_nat\_gateway is false. |
| private\_route\_table\_id | Route table used by the private subnets. |
| private\_subnet\_ids | Private subnet IDs, one per AZ. |
| public\_route\_table\_id | Route table used by the public subnets. |
| public\_subnet\_ids | Public subnet IDs, one per AZ. |
| vpc\_cidr | CIDR block of the VPC. |
| vpc\_id | ID of the VPC. |
<!-- END_TF_DOCS -->
