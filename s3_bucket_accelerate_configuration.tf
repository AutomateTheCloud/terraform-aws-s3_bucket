resource "aws_s3_bucket_accelerate_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  status = var.enable_transfer_acceleration ? "Enabled" : "Suspended"

  provider = aws.this
}
