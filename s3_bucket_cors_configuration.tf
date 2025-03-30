resource "aws_s3_bucket_cors_configuration" "this" {
  count  = try(length(var.cors), 0) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    iterator = cors_rule
    for_each = var.cors
    content {
      allowed_headers = try(cors_rule.value.allowed_headers, null)
      allowed_methods = try(cors_rule.value.allowed_methods, null)
      allowed_origins = try(cors_rule.value.allowed_origins, null)
      expose_headers  = try(cors_rule.value.expose_headers, null)
      max_age_seconds = try(cors_rule.value.max_age_seconds, null)
    }
  }

  provider = aws.this
}
