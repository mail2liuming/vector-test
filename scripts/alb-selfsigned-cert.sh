#!/usr/bin/env bash
# Create a self-signed certificate for the ALB and import it into ACM.
# The private key stays in .secrets/ (gitignored) and never enters Terraform state.
#
# Usage: scripts/alb-selfsigned-cert.sh [region]
set -euo pipefail

REGION="${1:-ap-southeast-2}"
NAME="*.${REGION}.elb.amazonaws.com" # matches the ALB's DNS name <name>-<id>.<region>.elb.amazonaws.com
DIR="$(cd "$(dirname "$0")/.." && pwd)/.secrets"

mkdir -p "$DIR" && chmod 700 "$DIR"

openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -subj "/CN=${NAME}" \
  -addext "subjectAltName=DNS:${NAME}" \
  -keyout "$DIR/alb.key" -out "$DIR/alb.crt" 2>/dev/null
chmod 600 "$DIR/alb.key"

ARN=$(aws acm import-certificate --region "$REGION" \
  --certificate "fileb://$DIR/alb.crt" \
  --private-key "fileb://$DIR/alb.key" \
  --tags Key=Project,Value=vector-test \
  --query CertificateArn --output text)

echo "Imported into ACM. Add this to terraform/envs/dev/terraform.tfvars:"
echo
echo "alb_certificate_arn = \"${ARN}\""
