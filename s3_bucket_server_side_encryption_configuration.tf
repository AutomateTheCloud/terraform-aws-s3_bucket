# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  region = var.region

  rule {
    # Bucket keys apply only to SSE-KMS.
    bucket_key_enabled = var.server_side_encryption.kms_enabled ? var.server_side_encryption.bucket_key_enabled : false
    apply_server_side_encryption_by_default {
      sse_algorithm = var.server_side_encryption.kms_enabled ? "aws:kms" : "AES256"
      # null with kms_enabled uses the AWS managed key, aws/s3.
      kms_master_key_id = var.server_side_encryption.kms_enabled ? var.server_side_encryption.kms_key_id : null
    }
  }
}
