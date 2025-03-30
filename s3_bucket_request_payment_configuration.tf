resource "aws_s3_bucket_request_payment_configuration" "this" {
  count  = var.requester_pays ? 1 : 0
  bucket = aws_s3_bucket.this.id
  payer  = "Requester"

  provider = aws.this
}
