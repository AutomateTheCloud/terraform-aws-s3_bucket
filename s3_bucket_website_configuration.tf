resource "aws_s3_bucket_website_configuration" "this" {
  count  = try(var.website.enabled, false) ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = try(var.website.index_document, null)
  }

  error_document {
    key = try(var.website.error_document, null)
  }

  routing_rule {
    condition {
      http_error_code_returned_equals = try(var.website.routing_rule.condition.http_error_code_returned_equals, null)
      key_prefix_equals               = try(var.website.routing_rule.condition.key_prefix_equals, null)
    }
    redirect {
      host_name               = try(var.website.routing_rule.redirect.hostname, null)
      http_redirect_code      = try(var.website.routing_rule.redirect.http_redirect_code, null)
      protocol                = try(var.website.routing_rule.redirect.protocol, null)
      replace_key_prefix_with = try(var.website.routing_rule.redirect.replace_key_prefix_with, null)
      replace_key_with        = try(var.website.routing_rule.redirect.replace_key_with, null)
    }
  }

  provider = aws.this
}
