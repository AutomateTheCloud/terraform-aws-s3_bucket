# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_s3_bucket_policy" "this" {
  count  = local.create_s3_bucket_policy ? 1 : 0
  bucket = aws_s3_bucket.this.id
  region = var.region
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.s3_bucket_policy_statements
  })

  # A public policy is rejected until the Public Access Block allows it.
  depends_on = [aws_s3_bucket_public_access_block.this]

  lifecycle {
    precondition {
      condition     = length(local.s3_bucket_policy_sids) == length(distinct(local.s3_bucket_policy_sids))
      error_message = "Bucket policy statement IDs (Sid) must be unique. Check policy.source_policy_documents against the module's own statements: ${join(", ", local.s3_bucket_policy_sids)}."
    }
  }
}

locals {
  s3_bucket_policy_sids = compact([for s in local.s3_bucket_policy_statements : try(s.Sid, "")])
}
