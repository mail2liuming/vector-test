data "aws_caller_identity" "current" {}

# AWS account that delivers ALB access logs in this region.
data "aws_elb_service_account" "current" {}

locals {
  log_prefix = "alb"
}

# ------------------------------------------------------- Security group

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "ALB: HTTP/HTTPS from the internet, HTTPS to the targets only"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  for_each = { http = 80, https = 443 }

  security_group_id = aws_security_group.alb.id
  description       = upper(each.key)
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_targets" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTPS to the targets"
  referenced_security_group_id = var.target_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

# ------------------------------------------------------- Load balancer

resource "aws_lb" "this" {
  #checkov:skip=CKV2_AWS_28:WAF is a further improvement; not needed for the demo
  #checkov:skip=CKV_AWS_150:Deletion protection is a variable, off so the demo can be destroyed
  name                       = "${var.project}-alb"
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.public_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = local.log_prefix
    enabled = true
  }

  tags = { Name = "${var.project}-alb" }

  # The ALB checks it can write to the bucket when access logs are enabled.
  depends_on = [aws_s3_bucket_policy.alb_logs]
}

resource "aws_lb_target_group" "https" {
  name        = "${var.project}-https"
  vpc_id      = var.vpc_id
  protocol    = "HTTPS"
  port        = 443
  target_type = "instance"

  # The ALB does not validate the target's certificate, so nginx's self-signed cert is fine.
  health_check {
    protocol            = "HTTPS"
    path                = "/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "this" {
  count = length(var.target_instance_ids)

  target_group_arn = aws_lb_target_group.https.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 443
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" # TLS 1.2 / 1.3 only
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

# ------------------------------------------------- Access log bucket

resource "aws_s3_bucket" "alb_logs" {
  #checkov:skip=CKV_AWS_145:ALB access log delivery only supports SSE-S3, not KMS
  #checkov:skip=CKV_AWS_18:This is the log bucket itself; logging it would need another bucket
  #checkov:skip=CKV_AWS_144:Cross-region replication is not needed for demo access logs
  #checkov:skip=CKV2_AWS_62:No consumer for event notifications on access logs
  bucket        = "${var.project}-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # demo: terraform destroy also removes the logs
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ALB log delivery only supports SSE-S3, not KMS.
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "access-logs"
    status = "Enabled"

    filter {}

    transition {
      days          = var.log_transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.log_transition_glacier_days
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = var.log_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.alb_logs]
}

data "aws_iam_policy_document" "alb_logs" {
  statement {
    sid       = "AllowAlbLogDelivery"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb_logs.arn}/${local.log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.alb_logs.arn, "${aws_s3_bucket.alb_logs.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_logs.json

  depends_on = [aws_s3_bucket_public_access_block.alb_logs]
}
