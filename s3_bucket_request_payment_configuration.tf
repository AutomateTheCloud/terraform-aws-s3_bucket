# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket_request_payment_configuration" "this" {
  count  = var.requester_pays ? 1 : 0
  bucket = aws_s3_bucket.this.id
  region = var.region
  payer  = "Requester"
}
