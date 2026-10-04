# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A bucket that receives logs, and a bucket that sends its access logs to it.
#
# The module has no "log bucket" switch. A log bucket is an ordinary bucket whose
# policy lets specific AWS services write to it, so this example writes that policy
# itself and passes it in through policy.source_policy_documents. Each grant is
# limited to this account and to the key prefix that service writes to.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for the bucket names, which must be globally unique"
  type        = string
  default     = "example"
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id      = data.aws_caller_identity.current.account_id
  log_bucket_name = "${var.name_prefix}-logs-${local.account_id}-${data.aws_region.current.region}"
  log_bucket_arn  = "arn:${data.aws_partition.current.partition}:s3:::${local.log_bucket_name}"

  details = {
    scope       = "Example"
    purpose     = "Log Bucket"
    environment = "prd"
  }
}

data "aws_iam_policy_document" "log_delivery" {
  # S3 server access logs, written under s3/ (see logging.prefix below).
  statement {
    sid       = "S3ServerAccessLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${local.log_bucket_arn}/s3/*"]
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }

  # Elastic Load Balancing access logs, for load balancers configured with the
  # prefix "elb". AWS requires the account ID in the resource path.
  statement {
    sid       = "ELBAccessLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${local.log_bucket_arn}/elb/AWSLogs/${local.account_id}/*"]
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
  }
}

module "logs" {
  source = "../../"

  details = local.details
  name    = local.log_bucket_name

  policy = {
    source_policy_documents = [data.aws_iam_policy_document.log_delivery.json]
  }

  # Log delivery from ELB and several other services supports only SSE-S3, the default.
  lifecycle_rules = [
    {
      rule_name                              = "Expire logs"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
      expiration                             = { days = 365 }
    }
  ]
}

module "app" {
  source = "../../"

  details = merge(local.details, { purpose = "Application Data" })
  name    = "${var.name_prefix}-app-${local.account_id}-${data.aws_region.current.region}"

  logging = {
    bucket_name = module.logs.metadata.s3_bucket.id
    prefix      = "s3"
  }
}

output "log_bucket" {
  value = module.logs.metadata.s3_bucket.id
}
