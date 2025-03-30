resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = try(var.server_side_encryption.kms_enabled, false) != false ? try(var.server_side_encryption.bucket_key_enabled, false) : false
    apply_server_side_encryption_by_default {
      sse_algorithm     = try(var.server_side_encryption.kms_enabled, false) != false ? "aws:kms" : "AES256"
      kms_master_key_id = try(data.aws_kms_key.s3_bucket[0].arn, null)
    }
  }

  provider = aws.this
}
