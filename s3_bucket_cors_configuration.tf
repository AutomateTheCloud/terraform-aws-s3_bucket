# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket_cors_configuration" "this" {
  count  = length(var.cors) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id
  region = var.region

  dynamic "cors_rule" {
    for_each = var.cors
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}
