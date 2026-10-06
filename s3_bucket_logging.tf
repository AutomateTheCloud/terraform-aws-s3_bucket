# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket_logging" "this" {
  # Counted on the input object, not on bucket_name, so the target bucket can be
  # created in the same run.
  count  = var.logging != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  region = var.region

  target_bucket = var.logging.bucket_name
  target_prefix = var.logging.prefix != null ? "${var.logging.prefix}/" : "s3/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = var.logging.partition_date_source
    }
  }
}
