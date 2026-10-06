# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # Resolve the prefix placeholders, and work out whether the filter needs an `and`
  # block: S3 accepts a single predicate directly, but two or more must be combined.
  lifecycle_rules = [
    for rule in var.lifecycle_rules : merge(rule, {
      filter_prefix = rule.prefix != null ? replace(replace(rule.prefix, "[[REGION]]", local.aws.region.name), "[[ACCOUNT_ID]]", local.aws.account.id) : null
      filter_and    = length(compact([rule.prefix, rule.object_size_greater_than == null ? null : "x", rule.object_size_less_than == null ? null : "x"])) > 1
    })
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id
  region = var.region

  dynamic "rule" {
    for_each = local.lifecycle_rules
    content {
      id     = rule.value.rule_name
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days                         = expiration.value.days
          date                         = expiration.value.date
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
          noncurrent_days           = noncurrent_version_expiration.value.days
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition
        content {
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          noncurrent_days           = noncurrent_version_transition.value.days
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition
        content {
          days          = transition.value.days
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      filter {
        # An empty prefix, the default, applies the rule to the whole bucket.
        prefix                   = rule.value.filter_and ? null : (rule.value.filter_prefix != null ? rule.value.filter_prefix : (rule.value.object_size_greater_than == null && rule.value.object_size_less_than == null ? "" : null))
        object_size_greater_than = rule.value.filter_and ? null : rule.value.object_size_greater_than
        object_size_less_than    = rule.value.filter_and ? null : rule.value.object_size_less_than

        dynamic "and" {
          for_each = rule.value.filter_and ? [1] : []
          content {
            prefix                   = rule.value.filter_prefix
            object_size_greater_than = rule.value.object_size_greater_than
            object_size_less_than    = rule.value.object_size_less_than
          }
        }
      }
    }
  }
}
