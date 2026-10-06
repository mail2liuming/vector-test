# alb module

Public Application Load Balancer in front of the nginx host:

- ALB in the public subnets; security group allows 80/443 from the internet and only HTTPS out to the targets
- HTTPS listener (TLS 1.2/1.3 policy) with an ACM certificate – a self-signed cert imported by `scripts/alb-selfsigned-cert.sh`
- HTTP listener that 301-redirects to HTTPS
- HTTPS target group with a `/health` check (the ALB accepts the target's self-signed cert)
- Access logs to an S3 bucket: public access blocked, SSE-S3, versioning, TLS-only bucket policy, lifecycle (Standard-IA after 30 days, Glacier Instant Retrieval after 90, delete after 365)

```hcl
module "alb" {
  source                   = "../../modules/alb"
  project                  = "vector-test"
  vpc_id                   = module.network.vpc_id
  public_subnet_ids        = module.network.public_subnet_ids
  certificate_arn          = var.alb_certificate_arn
  target_security_group_id = module.web.linux_security_group_id
  target_instance_ids      = [module.web.linux_instance_id]
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
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_s3_bucket.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.alb_to_targets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_elb_service_account.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |
| [aws_iam_policy_document.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| certificate\_arn | ACM certificate for the HTTPS listener (self-signed cert imported with scripts/alb-selfsigned-cert.sh). | `string` | n/a | yes |
| project | Name prefix applied to every resource. | `string` | n/a | yes |
| public\_subnet\_ids | Public subnets for the ALB (at least two AZs). | `list(string)` | n/a | yes |
| target\_instance\_ids | EC2 instances to register in the target group. | `list(string)` | n/a | yes |
| target\_security\_group\_id | Security group of the targets; the ALB may only send HTTPS to it. | `string` | n/a | yes |
| vpc\_id | VPC the load balancer and target group live in. | `string` | n/a | yes |
| deletion\_protection | Protect the ALB from deletion. Off so the demo can be destroyed. | `bool` | `false` | no |
| log\_expiration\_days | Delete access logs after this many days. | `number` | `365` | no |
| log\_transition\_glacier\_days | Move access logs to S3 Glacier Instant Retrieval after this many days. | `number` | `90` | no |
| log\_transition\_ia\_days | Move access logs to S3 Standard-IA after this many days. | `number` | `30` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | ARN of the ALB. |
| dns\_name | Public DNS name of the ALB. |
| log\_bucket | S3 bucket receiving the ALB access logs. |
| security\_group\_id | Security group of the ALB (allowed into the targets on 443). |
| target\_group\_arn | HTTPS target group. |
<!-- END_TF_DOCS -->
