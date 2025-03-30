resource "aws_s3_bucket" "this" {
  bucket = var.name

  force_destroy = var.force_destroy

  tags = merge(
    local.tags,
    tomap({
      "Name" = var.name,
    }),
    tomap(var.s3_bucket_additional_tags),
    tomap(try(var.used_for_s3_logs, false) ? {"UsedForS3Logs" = "true"} : {})
  )
  lifecycle {
    ignore_changes = [
      lifecycle_rule,
      server_side_encryption_configuration,
      grant
    ]
  }

  object_lock_enabled = try(var.object_lock.enabled, false) ? true : null

  provider = aws.this
}
