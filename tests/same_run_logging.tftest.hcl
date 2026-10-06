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
mock_provider "random" {}

# logging.bucket_name can refer to a bucket created in the same run, whose name is
# not known until apply.
run "logging_target_created_in_same_run" {
  command   = plan
  providers = { aws = aws, random = random }
  module {
    source = "./tests/fixtures/same_run_logging"
  }
  assert {
    condition     = length(module.data.metadata.s3_bucket_logging[*]) == 1
    error_message = "Logging was not planned."
  }
}
