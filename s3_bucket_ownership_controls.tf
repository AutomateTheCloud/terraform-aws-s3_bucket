resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = try(var.policy.use_for_aws_account_logging, false) ? "BucketOwnerPreferred" : "BucketOwnerEnforced"
  }
  provider = aws.this
}
