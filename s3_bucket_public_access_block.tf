resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = try(var.public_access_block.block_public_acls, true)
  block_public_policy     = try(var.public_access_block.block_public_policy, true)
  ignore_public_acls      = try(var.public_access_block.ignore_public_acls, true)
  restrict_public_buckets = try(var.public_access_block.restrict_public_buckets, true)
  depends_on = [
    aws_s3_bucket.this
  ]
  provider = aws.this
}
