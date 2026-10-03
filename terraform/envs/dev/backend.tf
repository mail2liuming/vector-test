# Local state is used for the exercise. In a team / CI setup, enable the S3 backend below
# (one state per environment) and run `terraform init -migrate-state`.
#
# The bucket is created once, outside this stack (bootstrap), with versioning, SSE and
# public access blocked. `use_lockfile` uses S3 native locking (Terraform >= 1.10), so no
# DynamoDB table is needed.
#
# terraform {
#   backend "s3" {
#     bucket       = "vector-test-tfstate-198598516303"
#     key          = "dev/web/terraform.tfstate"
#     region       = "ap-southeast-2"
#     encrypt      = true
#     use_lockfile = true
#   }
# }
