# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  region = var.region
  versioning_configuration {
    status = var.versioning.enabled ? "Enabled" : "Suspended"
  }
}
