# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket_accelerate_configuration" "this" {
  count  = var.enable_transfer_acceleration ? 1 : 0
  bucket = aws_s3_bucket.this.id
  region = var.region

  status = "Enabled"
}
