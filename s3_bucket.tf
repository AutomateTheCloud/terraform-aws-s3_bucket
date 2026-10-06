# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket" "this" {
  bucket = var.name
  region = var.region

  force_destroy = var.force_destroy

  tags = merge(
    local.tags,
    { "Name" = var.name },
    var.s3_bucket_additional_tags
  )

  # These arguments are managed by their own aws_s3_bucket_* resources.
  lifecycle {
    ignore_changes = [
      lifecycle_rule,
      server_side_encryption_configuration,
      grant
    ]
  }

  # Object Lock is turned on by aws_s3_bucket_object_lock_configuration, not here.
  # Setting object_lock_enabled on this resource would replace the bucket when it changes.
}
