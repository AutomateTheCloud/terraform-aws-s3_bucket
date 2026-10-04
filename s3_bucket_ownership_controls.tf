# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# ACLs are disabled. Every AWS log delivery this module grants access to works
# through the bucket policy.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  region = var.region
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
