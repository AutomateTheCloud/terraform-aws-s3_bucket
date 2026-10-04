# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_s3_bucket" {
    defaults = { arn = "arn:aws:s3:::test-bucket", object_lock_enabled = false }
  }
}

variables {
  details = { scope = "Test", purpose = "Features", environment = "test" }
  name    = "test-bucket"
}

run "logging" {
  command = plan
  variables { logging = { bucket_name = "logs-bucket", prefix = "access" } }
  assert {
    condition     = aws_s3_bucket_logging.this[0].target_bucket == "logs-bucket" && aws_s3_bucket_logging.this[0].target_prefix == "access/"
    error_message = "Logging is misconfigured."
  }
}

# A website needs only an index document.
run "website_index_only" {
  command = plan
  variables { website = { index_document = "index.html" } }
  assert {
    condition = alltrue([
      aws_s3_bucket_website_configuration.this[0].index_document[0].suffix == "index.html",
      length(aws_s3_bucket_website_configuration.this[0].error_document) == 0,
      length(aws_s3_bucket_website_configuration.this[0].routing_rule) == 0,
    ])
    error_message = "Website is misconfigured."
  }
}

run "website_does_not_make_bucket_public" {
  command = apply
  variables { website = { index_document = "index.html" } }
  assert {
    condition     = !contains([for s in jsondecode(aws_s3_bucket_policy.this[0].policy).Statement : s.Sid], "PublicReadGetObject")
    error_message = "Website hosting must not add public read on its own."
  }
}

run "website_routing_rules" {
  command = plan
  variables {
    website = {
      index_document = "index.html"
      error_document = "404.html"
      routing_rules = [
        { condition = { key_prefix_equals = "docs/" }, redirect = { replace_key_prefix_with = "documents/" } },
        { redirect = { host_name = "example.org", protocol = "https" } },
      ]
    }
  }
  assert {
    condition     = length(aws_s3_bucket_website_configuration.this[0].routing_rule) == 2
    error_message = "Expected two routing rules."
  }
}

run "website_needs_exactly_one_mode" {
  command = plan
  variables {
    website = { index_document = "index.html", redirect_all_requests_to = { host_name = "example.org" } }
  }
  expect_failures = [var.website]
}

# Each lifecycle action becomes exactly one block, with filters built correctly.
run "lifecycle_blocks" {
  command = plan
  variables {
    lifecycle_rules = [
      {
        rule_name                     = "all"
        enabled                       = true
        expiration                    = { days = 365 }
        noncurrent_version_expiration = { days = 90, newer_noncurrent_versions = 2 }
        noncurrent_version_transition = [{ days = 30, storage_class = "GLACIER", newer_noncurrent_versions = 5 }]
      },
      {
        rule_name                = "logs"
        enabled                  = true
        prefix                   = "AWSLogs/[[ACCOUNT_ID]]/[[REGION]]/"
        object_size_greater_than = 128
        expiration               = { days = 30 }
      },
    ]
  }
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this[0].rule[0].noncurrent_version_expiration) == 1
    error_message = "Expected one noncurrent_version_expiration block."
  }
  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.this[0].rule[0].noncurrent_version_transition).newer_noncurrent_versions == 5
    error_message = "noncurrent_version_transition.newer_noncurrent_versions was not taken from its own block."
  }
  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.this[0].rule[0].filter).prefix == ""
    error_message = "A rule with no filter must apply to the whole bucket."
  }
  assert {
    condition     = one(one(aws_s3_bucket_lifecycle_configuration.this[0].rule[1].filter).and).prefix == "AWSLogs/111111111111/us-east-1/"
    error_message = "Prefix and size must be combined in an and block, with placeholders resolved."
  }
}

# Any grant creates a policy, even without the encrypted-transport rule.
run "policy_write_access_only" {
  command = apply
  variables {
    policy = { require_encrypted_transport = false, aws_account_write_access = ["222222222222"] }
  }
  assert {
    condition     = length(jsondecode(aws_s3_bucket_policy.this[0].policy).Statement) == 2
    error_message = "Expected the two write-access statements."
  }
}

run "policy_none_needed" {
  command = plan
  variables { policy = { require_encrypted_transport = false } }
  assert {
    condition     = length(aws_s3_bucket_policy.this) == 0
    error_message = "No policy should be created."
  }
}

run "policy_account_id_validated" {
  command = plan
  variables { policy = { aws_account_read_access = ["arn:aws:iam::222222222222:root"] } }
  expect_failures = [var.policy]
}

run "public_read_requires_public_access_block" {
  command = plan
  variables { policy = { public_read = true } }
  expect_failures = [var.policy]
}

run "public_read" {
  command = apply
  variables {
    policy              = { public_read = true }
    public_access_block = { block_public_policy = false, restrict_public_buckets = false }
  }
  assert {
    condition     = contains([for s in jsondecode(aws_s3_bucket_policy.this[0].policy).Statement : s.Sid], "PublicReadGetObject")
    error_message = "Expected the public read statement."
  }
}

run "source_policy_documents" {
  command = apply
  variables {
    policy = {
      source_policy_documents = [jsonencode({
        Version = "2012-10-17"
        # Statements of different shapes, as aws_iam_policy_document produces.
        Statement = [
          {
            Sid       = "S3ServerAccessLogs"
            Effect    = "Allow"
            Principal = { Service = "logging.s3.amazonaws.com" }
            Action    = "s3:PutObject"
            Resource  = "arn:aws:s3:::test-bucket/s3/*"
            Condition = { StringEquals = { "aws:SourceAccount" = "111111111111" } }
          },
          {
            Sid       = "ELBAccessLogs"
            Effect    = "Allow"
            Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
            Action    = ["s3:PutObject"]
            Resource  = "arn:aws:s3:::test-bucket/elb/AWSLogs/111111111111/*"
          },
        ]
      })]
    }
  }
  assert {
    condition     = [for s in jsondecode(aws_s3_bucket_policy.this[0].policy).Statement : s.Sid] == ["RequireEncryptedTransport", "S3ServerAccessLogs", "ELBAccessLogs"]
    error_message = "Statements from source_policy_documents must be added after the module's own."
  }
}

run "source_policy_documents_alone_create_a_policy" {
  command = plan
  variables {
    policy = {
      require_encrypted_transport = false
      source_policy_documents     = [jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "logging.s3.amazonaws.com" }, Action = "s3:PutObject", Resource = "arn:aws:s3:::test-bucket/*" }] })]
    }
  }
  assert {
    condition     = length(aws_s3_bucket_policy.this) == 1
    error_message = "A source policy document alone must create a policy."
  }
}

run "source_policy_documents_must_be_policies" {
  command = plan
  variables { policy = { source_policy_documents = ["{\"not\": \"a policy\"}"] } }
  expect_failures = [var.policy]
}

run "source_policy_documents_duplicate_sid" {
  command = plan
  variables {
    policy = {
      source_policy_documents = [jsonencode({ Version = "2012-10-17", Statement = [{ Sid = "RequireEncryptedTransport", Effect = "Allow", Principal = "*", Action = "s3:GetObject", Resource = "arn:aws:s3:::test-bucket/*" }] })]
    }
  }
  expect_failures = [aws_s3_bucket_policy.this]
}

run "object_lock_requires_versioning" {
  command = plan
  variables { object_lock = { days = 5 } }
  expect_failures = [var.object_lock]
}

run "object_lock_with_retention" {
  command = plan
  variables {
    versioning  = { enabled = true }
    object_lock = { mode = "COMPLIANCE", days = 5 }
  }
  assert {
    condition     = aws_s3_bucket_object_lock_configuration.this[0].object_lock_enabled == "Enabled" && aws_s3_bucket_object_lock_configuration.this[0].rule[0].default_retention[0].mode == "COMPLIANCE"
    error_message = "Object Lock is misconfigured."
  }
}

# Object Lock must not be set on the bucket resource, where changing it would
# replace the bucket.
run "object_lock_does_not_touch_bucket" {
  command = apply
  variables {
    versioning  = { enabled = true }
    object_lock = { days = 1 }
  }
  assert {
    condition     = !aws_s3_bucket.this.object_lock_enabled
    error_message = "object_lock_enabled must not be set on the bucket."
  }
}

run "object_lock_without_retention" {
  command = plan
  variables {
    versioning  = { enabled = true }
    object_lock = {}
  }
  assert {
    condition     = aws_s3_bucket_object_lock_configuration.this[0].object_lock_enabled == "Enabled" && length(aws_s3_bucket_object_lock_configuration.this[0].rule) == 0
    error_message = "Object Lock without default retention must be enabled with no rule."
  }
}

run "kms_key_requires_kms_enabled" {
  command = plan
  variables { server_side_encryption = { kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/abc" } }
  expect_failures = [var.server_side_encryption]
}

run "kms_key_must_be_arn" {
  command = plan
  variables { server_side_encryption = { kms_enabled = true, kms_key_id = "alias/my-key" } }
  expect_failures = [var.server_side_encryption]
}

run "kms" {
  command = plan
  variables {
    server_side_encryption = { kms_enabled = true, bucket_key_enabled = true, kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/abc" }
  }
  assert {
    condition = alltrue([
      one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms",
      one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).kms_master_key_id == "arn:aws:kms:us-east-1:111111111111:key/abc",
      one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled,
    ])
    error_message = "KMS encryption is misconfigured."
  }
}
