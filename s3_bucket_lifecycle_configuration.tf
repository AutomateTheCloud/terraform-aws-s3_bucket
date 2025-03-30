resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = try(length(var.lifecycle_rules), 0) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    iterator = rule
    for_each = var.lifecycle_rules
    content {
      id     = try(rule.value.rule_name, null)
      status = try(rule.value.enabled, false) ? "Enabled" : "Disabled"

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_incomplete_multipart_upload_days, null) != null ? [1] : []
        content {
          days_after_initiation = try(rule.value.abort_incomplete_multipart_upload_days, null)
        }
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration, [])
        content {
          days                         = try(rule.value.expiration.days, null) != null ? rule.value.expiration.days : null
          date                         = try(rule.value.expiration.date, null) != null ? rule.value.expiration.date : null
          expired_object_delete_marker = try(rule.value.expiration.expired_object_delete_marker, null) != null ? rule.value.expiration.expired_object_delete_marker : null
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration, [])
        content {
          newer_noncurrent_versions = try(rule.value.noncurrent_version_expiration.newer_noncurrent_versions, null)
          noncurrent_days           = try(rule.value.noncurrent_version_expiration.days, null)
        }
      }

      dynamic "noncurrent_version_transition" {
        iterator = noncurrent_version_transition
        for_each = try(rule.value.noncurrent_version_transition, [])
        content {
          newer_noncurrent_versions = try(rule.value.noncurrent_version_expiration.newer_noncurrent_versions, null)
          noncurrent_days           = noncurrent_version_transition.value.days
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "transition" {
        iterator = transition
        for_each = (try(rule.value.transition, []))
        content {
          days          = try(transition.value.days, null) != null ? transition.value.days : null
          date          = try(transition.value.date, null) != null ? transition.value.date : null
          storage_class = transition.value.storage_class
        }
      }

      filter {
        prefix                   = try(rule.value.prefix, null) != null ? replace(replace(rule.value.prefix, "/\\[\\[REGION\\]\\]/", local.aws.region.name), "/\\[\\[ACCOUNT_ID\\]\\]/", local.aws.account.id) : ""
        object_size_greater_than = try(rule.value.object_size_greater_than, null)
        object_size_less_than    = try(rule.value.object_size_less_than, null)
      }

    }
  }

  provider = aws.this
}
