# vector-test

nginx over HTTPS on AWS (`ap-southeast-2`) with Terraform, Ansible and Packer.

## Setup

```bash
ansible-galaxy collection install -r ansible/requirements.yml
pip install pywinrm                                   # only for Windows
ssh-keygen -t rsa -b 4096 -m PEM -f ~/.ssh/vector-test
```

## Linux EC2

```bash
cd terraform/envs/dev && terraform init && terraform apply
cd ../../../ansible && ansible-playbook site.yml
```

Add Windows: `terraform apply -var enable_windows=true`, then `ansible-playbook site.yml --limit windows`.

## Packer AMI + ALB

```bash
scripts/alb-selfsigned-cert.sh                        # copy the printed ARN into terraform/envs/dev/terraform.tfvars
cd packer && packer init . && packer build . && cd ..
cd terraform/envs/dev && terraform apply -var enable_alb=true
```

## Check

```bash
curl -kv $(terraform output -raw linux_url)           # or alb_url / windows_url
```

## Clean up

```bash
terraform destroy                                     # same -var flags as apply
```
