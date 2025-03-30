resource "aws_s3_bucket_object_lock_configuration" "this" {
  count  = try(var.object_lock.enabled, false) ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode  = try(var.object_lock.mode, "GOVERNANCE")
      days  = try(var.object_lock.days, null)
      years = try(var.object_lock.years, null)
    }
  }

  provider = aws.this
}
