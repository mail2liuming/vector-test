# Deployment

Terraform builds the AWS resources, Ansible configures nginx with HTTPS, Packer bakes an AMI.
All commands are run from the repository root unless a `cd` is shown. Region: `ap-southeast-2`.

## Prerequisites

```bash
# Tools: Terraform >= 1.6, Ansible >= 2.15, Packer >= 1.10, AWS CLI v2, OpenSSL
aws sts get-caller-identity                                   # AWS credentials work
ansible-galaxy collection install -r ansible/requirements.yml
pip install pywinrm                                           # only for the Windows host

# SSH key pair (RSA/PEM: AWS encrypts the Windows password with it)
ssh-keygen -t rsa -b 4096 -m PEM -f ~/.ssh/vector-test
```

Optional settings go in `terraform/envs/dev/terraform.tfvars` (see `terraform.tfvars.example`).
Admin ports (SSH/WinRM/RDP) are opened to your current public IP automatically.

## A. Linux EC2 with nginx over HTTPS

```bash
cd terraform/envs/dev
terraform init
terraform plan                 # 29 resources
terraform apply

cd ../../../ansible
ansible-playbook site.yml      # installs nginx, self-signed cert, HTTP→HTTPS redirect

cd ../terraform/envs/dev
IP=$(terraform output -raw linux_public_ip)
curl -kI http://$IP            # 301 → https
curl -kv https://$IP           # 200 over TLS
```

### Windows EC2 (optional)

```bash
cd terraform/envs/dev
terraform apply -var enable_windows=true            # adds the Windows host

cd ../../../ansible
ansible-playbook site.yml --limit windows           # waits for the password and WinRM (~5–10 min)

cd ../terraform/envs/dev
curl -kv https://$(terraform output -raw windows_public_ip)
```

## B. Packer AMI

```bash
cd packer
packer init .
packer build .                 # temp EC2 → same Ansible role → AMI tagged Role=nginx-https
```

## C. Linux from the Packer AMI behind an ALB

The Linux host runs from the newest Packer AMI in a private subnet (no public IP, no SSH), with a
NAT gateway for outbound traffic. An ALB in the public subnets terminates HTTPS with a self-signed
certificate imported into ACM and forwards to nginx over HTTPS. ALB access logs go to S3 with a
lifecycle policy (Standard-IA after 30 days, Glacier Instant Retrieval after 90, deleted after 365).

```bash
# 1. Certificate → ACM (once). Prints the ARN to put in terraform.tfvars.
scripts/alb-selfsigned-cert.sh
echo 'alb_certificate_arn = "arn:aws:acm:..."' >> terraform/envs/dev/terraform.tfvars

# 2. AMI (if not built yet) – see B
cd packer && packer build . && cd ..

# 3. Infrastructure
cd terraform/envs/dev
terraform init
terraform plan  -var enable_alb=true                # 50 resources
terraform apply -var enable_alb=true

# 4. Verify
ALB=$(terraform output -raw alb_dns_name)
curl -kI http://$ALB                                # 301 → https
curl -kv https://$ALB                               # 200, cert CN=*.ap-southeast-2.elb.amazonaws.com
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw alb_target_group_arn) \
  --query 'TargetHealthDescriptions[].TargetHealth.State'                     # ["healthy"]
aws s3 ls s3://$(terraform output -raw alb_log_bucket)/alb/ --recursive       # logs within ~5 min
```

The host is configured by the AMI, so Ansible is not run against it. To roll out a new AMI:
`packer build .`, then `terraform apply -var enable_alb=true -replace=module.web.aws_instance.linux`.

## Clean up

```bash
cd terraform/envs/dev
terraform destroy                                   # add the same -var flags used for apply

# Not managed by Terraform:
aws ec2 describe-images --owners self --query 'Images[].[ImageId,BlockDeviceMappings[0].Ebs.SnapshotId]'
aws ec2 deregister-image --image-id ami-...         # Packer AMI first,
aws ec2 delete-snapshot  --snapshot-id snap-...     # then its snapshot
aws acm delete-certificate --certificate-arn arn:aws:acm:...   # ALB certificate
```
