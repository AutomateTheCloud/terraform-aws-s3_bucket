# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A public static website served directly from S3 over HTTP.
#
# S3 website endpoints do not support HTTPS. For a production site, keep the bucket
# private and serve it through CloudFront instead; this example shows the simplest
# working setup.

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

module "website" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Static Website"
    environment = "Development"
  }

  name = var.name

  website = {
    index_document = "index.html"
    error_document = "404.html"
  }

  # Website endpoints are HTTP only, so the default HTTPS-only rule would block
  # every visitor.
  policy = {
    require_encrypted_transport = false
    public_read                 = true
  }

  # A public policy is rejected unless these two settings allow it. Public ACLs
  # stay blocked.
  public_access_block = {
    block_public_policy     = false
    restrict_public_buckets = false
  }
}

output "website_endpoint" {
  description = "The website's URL"
  value       = "http://${module.website.metadata.s3_bucket_website_configuration.website_endpoint}"
}
