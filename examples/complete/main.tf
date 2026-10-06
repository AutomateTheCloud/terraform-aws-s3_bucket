# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A private bucket that uses most of the module's options together: KMS
# encryption, Object Lock, lifecycle rules, CORS, access logging, and read access
# for other accounts. Each option is explained in the module README.

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

variable "log_bucket_name" {
  description = "Existing bucket that receives this bucket's access logs. See the log-bucket example."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key that encrypts new objects"
  type        = string
}

variable "reader_account_ids" {
  description = "AWS account IDs that may read the bucket"
  type        = list(string)
  default     = []
}

module "s3_bucket" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Complete Bucket"
    environment = "Production"
    additional_tags = {
      Project = "Example Project"
    }
  }

  name = var.name

  # Optional: create the bucket in another Region than the provider's.
  # region = "us-west-2"

  versioning = { enabled = true }

  server_side_encryption = {
    kms_enabled        = true
    kms_key_id         = var.kms_key_arn
    bucket_key_enabled = true
  }

  # Objects cannot be deleted or overwritten for 30 days. Users with the
  # s3:BypassGovernanceRetention permission can override GOVERNANCE mode.
  object_lock = {
    mode = "GOVERNANCE"
    days = 30
  }

  logging = {
    bucket_name = var.log_bucket_name
    prefix      = "s3"
  }

  policy = {
    aws_account_read_access = var.reader_account_ids
  }

  cors = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://example.org"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  lifecycle_rules = [
    {
      rule_name                              = "Clean up old versions"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
      noncurrent_version_expiration          = { days = 90, newer_noncurrent_versions = 3 }
      expiration                             = { expired_object_delete_marker = true }
    },
    {
      rule_name = "Archive"
      enabled   = true
      prefix    = "archive/"
      transition = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 90, storage_class = "GLACIER" },
      ]
      expiration = { days = 730 }
    },
  ]
}

output "metadata" {
  description = "Everything the module created, and the names and tags it worked out"
  value       = module.s3_bucket.metadata
}
