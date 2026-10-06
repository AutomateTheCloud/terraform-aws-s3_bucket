# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket_object_lock_configuration" "this" {
  # Turns Object Lock on, for new and existing buckets. It cannot be turned off again;
  # removing this resource only removes the default retention.
  count  = local.object_lock_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id
  region = var.region

  object_lock_enabled = "Enabled"

  dynamic "rule" {
    for_each = var.object_lock.days != null || var.object_lock.years != null ? [1] : []
    content {
      default_retention {
        mode  = var.object_lock.mode
        days  = var.object_lock.days
        years = var.object_lock.years
      }
    }
  }

  # Object Lock requires versioning to be enabled first.
  depends_on = [aws_s3_bucket_versioning.this]
}
