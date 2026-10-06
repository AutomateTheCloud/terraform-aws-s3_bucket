# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_s3_bucket" {
    defaults = { arn = "arn:aws:s3:::test-bucket" }
  }
}

variables {
  details = { scope = "Test", purpose = "Defaults", environment = "test" }
  name    = "test-bucket"
}

run "defaults_are_secure" {
  command = apply

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "Public access must be fully blocked by default."
  }
  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled."
  }
  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "Default encryption must be SSE-S3."
  }
  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this[0].policy).Statement[0].Resource == ["arn:aws:s3:::test-bucket", "arn:aws:s3:::test-bucket/*"]
    error_message = "RequireEncryptedTransport must cover the bucket and its objects."
  }
  assert {
    condition     = length(jsondecode(aws_s3_bucket_policy.this[0].policy).Statement) == 1
    error_message = "Only the TLS statement is expected by default."
  }
  assert {
    condition = alltrue([
      length(aws_s3_bucket_accelerate_configuration.this) == 0,
      length(aws_s3_bucket_cors_configuration.this) == 0,
      length(aws_s3_bucket_lifecycle_configuration.this) == 0,
      length(aws_s3_bucket_logging.this) == 0,
      length(aws_s3_bucket_object_lock_configuration.this) == 0,
      length(aws_s3_bucket_request_payment_configuration.this) == 0,
      length(aws_s3_bucket_website_configuration.this) == 0,
    ])
    error_message = "Optional resources must not be created by default."
  }
  assert {
    condition     = output.metadata.s3_bucket_website_configuration == null && output.metadata.aws.region.abbr == "use1"
    error_message = "Unexpected metadata output."
  }
}

run "details_scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "name_validated" {
  command = plan
  variables { name = "Not_A_Valid_Bucket" }
  expect_failures = [var.name]
}

run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Automate the Cloud", scope_abbr = "atc-org", purpose = "Web Site", environment = "Production" }
  }
  assert {
    condition = alltrue([
      output.metadata.details.scope.abbr == "atc-org",
      output.metadata.details.scope.machine == "atcorg",
      output.metadata.details.purpose.abbr == "web_site",
      output.metadata.details.purpose.machine == "website",
    ])
    error_message = "Unexpected abbreviations."
  }
}

run "transfer_acceleration" {
  command = plan
  variables { enable_transfer_acceleration = true }
  assert {
    condition     = aws_s3_bucket_accelerate_configuration.this[0].status == "Enabled"
    error_message = "Transfer acceleration was not enabled."
  }
}

run "requester_pays" {
  command = plan
  variables { requester_pays = true }
  assert {
    condition     = aws_s3_bucket_request_payment_configuration.this[0].payer == "Requester"
    error_message = "Requester Pays was not enabled."
  }
}
