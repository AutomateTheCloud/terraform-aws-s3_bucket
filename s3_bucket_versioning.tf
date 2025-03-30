resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status     = try(var.versioning.enabled, false) ? "Enabled" : "Suspended"
    mfa_delete = try(var.versioning.mfa_delete, false) ? "Enabled" : null
  }
  provider = aws.this
}
