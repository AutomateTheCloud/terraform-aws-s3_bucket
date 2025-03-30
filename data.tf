data "aws_kms_key" "s3_bucket" {
  count    = try(var.server_side_encryption.kms_key_id, null) != null ? 1 : 0
  key_id   = var.server_side_encryption.kms_key_id
  provider = aws.this
}

data "aws_canonical_user_id" "this" {
  provider = aws.this
}