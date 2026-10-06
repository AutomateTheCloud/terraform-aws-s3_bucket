# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A private bucket with versioning, and a lifecycle rule that keeps old versions
# from accumulating forever. This is a sensible starting point for most buckets.

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

variable "name" {
  description = "Name of the bucket, which must be globally unique"
  type        = string
}

module "s3_bucket" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic Bucket"
    environment = "Development"
  }

  name       = var.name
  versioning = { enabled = true }

  lifecycle_rules = [
    {
      rule_name                              = "Clean up old versions"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
      noncurrent_version_expiration          = { days = 30 }
      expiration                             = { expired_object_delete_marker = true }
    }
  ]
}

output "bucket" {
  description = "Name and ARN of the bucket"
  value = {
    name = module.s3_bucket.metadata.s3_bucket.id
    arn  = module.s3_bucket.metadata.s3_bucket.arn
  }
}
