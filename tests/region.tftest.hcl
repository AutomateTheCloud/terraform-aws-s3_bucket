# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details = { scope = "Test", purpose = "Region", environment = "test" }
  name    = "test-bucket"
}

run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = apply
  variables {
    region                       = "us-west-2"
    versioning                   = { enabled = true }
    cors                         = [{ allowed_methods = ["GET"], allowed_origins = ["*"] }]
    lifecycle_rules              = [{ rule_name = "r", enabled = true, abort_incomplete_multipart_upload_days = 7 }]
    logging                      = { bucket_name = "logs-bucket" }
    website                      = { index_document = "index.html" }
    enable_transfer_acceleration = true
    requester_pays               = true
  }
  assert {
    condition = alltrue([
      aws_s3_bucket.this.region == "us-west-2",
      aws_s3_bucket_accelerate_configuration.this[0].region == "us-west-2",
      aws_s3_bucket_cors_configuration.this[0].region == "us-west-2",
      aws_s3_bucket_lifecycle_configuration.this[0].region == "us-west-2",
      aws_s3_bucket_logging.this[0].region == "us-west-2",
      aws_s3_bucket_ownership_controls.this.region == "us-west-2",
      aws_s3_bucket_policy.this[0].region == "us-west-2",
      aws_s3_bucket_public_access_block.this.region == "us-west-2",
      aws_s3_bucket_request_payment_configuration.this[0].region == "us-west-2",
      aws_s3_bucket_server_side_encryption_configuration.this.region == "us-west-2",
      aws_s3_bucket_versioning.this.region == "us-west-2",
      aws_s3_bucket_website_configuration.this[0].region == "us-west-2",
      output.metadata.aws.region.name == "us-west-2",
    ])
    error_message = "region was not passed through to every resource."
  }
}

# Any Region plans, including ones added after this module was written.
run "region_not_in_old_tables" {
  command = plan
  variables { region = "ap-south-2" }
  assert {
    condition     = output.metadata.aws.region.abbr == "aps2"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_new_region" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command = plan
  variables { region = "us-gov-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}
