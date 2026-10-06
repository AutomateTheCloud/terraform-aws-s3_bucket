# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `s3_bucket` - The bucket's `id` (its name), `arn`, `bucket_regional_domain_name`, `bucket_domain_name`, `bucket_region`, `hosted_zone_id`, `region`, `force_destroy`, `tags` and `tags_all`.
    - One entry per configuration resource, such as `s3_bucket_policy` and `s3_bucket_website_configuration`. An entry is `null` when that resource is not created.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource. Resources that are not created are null.
    s3_bucket                                      = local.output_resources.s3_bucket
    s3_bucket_accelerate_configuration             = local.output_resources.s3_bucket_accelerate_configuration
    s3_bucket_cors_configuration                   = local.output_resources.s3_bucket_cors_configuration
    s3_bucket_lifecycle_configuration              = local.output_resources.s3_bucket_lifecycle_configuration
    s3_bucket_logging                              = local.output_resources.s3_bucket_logging
    s3_bucket_object_lock_configuration            = local.output_resources.s3_bucket_object_lock_configuration
    s3_bucket_ownership_controls                   = local.output_resources.s3_bucket_ownership_controls
    s3_bucket_policy                               = local.output_resources.s3_bucket_policy
    s3_bucket_public_access_block                  = local.output_resources.s3_bucket_public_access_block
    s3_bucket_request_payment_configuration        = local.output_resources.s3_bucket_request_payment_configuration
    s3_bucket_server_side_encryption_configuration = local.output_resources.s3_bucket_server_side_encryption_configuration
    s3_bucket_versioning                           = local.output_resources.s3_bucket_versioning
    s3_bucket_website_configuration                = local.output_resources.s3_bucket_website_configuration
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource, or
  # iterating over it, would also reference its deprecated attributes, and every
  # caller's plan would print deprecation warnings.
  output_resources = {
    # The bucket's other attributes are its old inline settings, which this module
    # manages through separate resources.
    s3_bucket = {
      arn                         = aws_s3_bucket.this.arn
      bucket                      = aws_s3_bucket.this.bucket
      bucket_domain_name          = aws_s3_bucket.this.bucket_domain_name
      bucket_region               = aws_s3_bucket.this.bucket_region
      bucket_regional_domain_name = aws_s3_bucket.this.bucket_regional_domain_name
      force_destroy               = aws_s3_bucket.this.force_destroy
      hosted_zone_id              = aws_s3_bucket.this.hosted_zone_id
      id                          = aws_s3_bucket.this.id
      region                      = aws_s3_bucket.this.region
      tags                        = aws_s3_bucket.this.tags
      tags_all                    = aws_s3_bucket.this.tags_all
    }

    # The configuration resources, each without its deprecated attributes
    # (expected_bucket_owner, and id on the lifecycle configuration) and without
    # the sensitive Object Lock token. null when the resource is not created.
    s3_bucket_accelerate_configuration = length(aws_s3_bucket_accelerate_configuration.this) == 0 ? null : {
      bucket = aws_s3_bucket_accelerate_configuration.this[0].bucket
      id     = aws_s3_bucket_accelerate_configuration.this[0].id
      region = aws_s3_bucket_accelerate_configuration.this[0].region
      status = aws_s3_bucket_accelerate_configuration.this[0].status
    }

    s3_bucket_cors_configuration = length(aws_s3_bucket_cors_configuration.this) == 0 ? null : {
      bucket    = aws_s3_bucket_cors_configuration.this[0].bucket
      cors_rule = aws_s3_bucket_cors_configuration.this[0].cors_rule
      id        = aws_s3_bucket_cors_configuration.this[0].id
      region    = aws_s3_bucket_cors_configuration.this[0].region
    }

    s3_bucket_lifecycle_configuration = length(aws_s3_bucket_lifecycle_configuration.this) == 0 ? null : {
      bucket = aws_s3_bucket_lifecycle_configuration.this[0].bucket
      region = aws_s3_bucket_lifecycle_configuration.this[0].region
      # Each rule without its deprecated prefix attribute; prefixes are in filter.
      rule = [for rule in aws_s3_bucket_lifecycle_configuration.this[0].rule : {
        abort_incomplete_multipart_upload = rule.abort_incomplete_multipart_upload
        expiration                        = rule.expiration
        filter                            = rule.filter
        id                                = rule.id
        noncurrent_version_expiration     = rule.noncurrent_version_expiration
        noncurrent_version_transition     = rule.noncurrent_version_transition
        status                            = rule.status
        transition                        = rule.transition
      }]
      transition_default_minimum_object_size = aws_s3_bucket_lifecycle_configuration.this[0].transition_default_minimum_object_size
    }

    s3_bucket_logging = length(aws_s3_bucket_logging.this) == 0 ? null : {
      bucket                   = aws_s3_bucket_logging.this[0].bucket
      id                       = aws_s3_bucket_logging.this[0].id
      region                   = aws_s3_bucket_logging.this[0].region
      target_bucket            = aws_s3_bucket_logging.this[0].target_bucket
      target_grant             = aws_s3_bucket_logging.this[0].target_grant
      target_object_key_format = aws_s3_bucket_logging.this[0].target_object_key_format
      target_prefix            = aws_s3_bucket_logging.this[0].target_prefix
    }

    s3_bucket_object_lock_configuration = length(aws_s3_bucket_object_lock_configuration.this) == 0 ? null : {
      bucket              = aws_s3_bucket_object_lock_configuration.this[0].bucket
      id                  = aws_s3_bucket_object_lock_configuration.this[0].id
      object_lock_enabled = aws_s3_bucket_object_lock_configuration.this[0].object_lock_enabled
      region              = aws_s3_bucket_object_lock_configuration.this[0].region
      rule                = aws_s3_bucket_object_lock_configuration.this[0].rule
    }

    s3_bucket_ownership_controls = {
      bucket = aws_s3_bucket_ownership_controls.this.bucket
      id     = aws_s3_bucket_ownership_controls.this.id
      region = aws_s3_bucket_ownership_controls.this.region
      rule   = aws_s3_bucket_ownership_controls.this.rule
    }

    s3_bucket_policy = length(aws_s3_bucket_policy.this) == 0 ? null : {
      bucket = aws_s3_bucket_policy.this[0].bucket
      id     = aws_s3_bucket_policy.this[0].id
      policy = aws_s3_bucket_policy.this[0].policy
      region = aws_s3_bucket_policy.this[0].region
    }

    s3_bucket_public_access_block = {
      block_public_acls       = aws_s3_bucket_public_access_block.this.block_public_acls
      block_public_policy     = aws_s3_bucket_public_access_block.this.block_public_policy
      bucket                  = aws_s3_bucket_public_access_block.this.bucket
      id                      = aws_s3_bucket_public_access_block.this.id
      ignore_public_acls      = aws_s3_bucket_public_access_block.this.ignore_public_acls
      region                  = aws_s3_bucket_public_access_block.this.region
      restrict_public_buckets = aws_s3_bucket_public_access_block.this.restrict_public_buckets
    }

    s3_bucket_request_payment_configuration = length(aws_s3_bucket_request_payment_configuration.this) == 0 ? null : {
      bucket = aws_s3_bucket_request_payment_configuration.this[0].bucket
      id     = aws_s3_bucket_request_payment_configuration.this[0].id
      payer  = aws_s3_bucket_request_payment_configuration.this[0].payer
      region = aws_s3_bucket_request_payment_configuration.this[0].region
    }

    s3_bucket_server_side_encryption_configuration = {
      bucket = aws_s3_bucket_server_side_encryption_configuration.this.bucket
      id     = aws_s3_bucket_server_side_encryption_configuration.this.id
      region = aws_s3_bucket_server_side_encryption_configuration.this.region
      rule   = aws_s3_bucket_server_side_encryption_configuration.this.rule
    }

    s3_bucket_versioning = {
      bucket                   = aws_s3_bucket_versioning.this.bucket
      id                       = aws_s3_bucket_versioning.this.id
      mfa                      = aws_s3_bucket_versioning.this.mfa
      region                   = aws_s3_bucket_versioning.this.region
      versioning_configuration = aws_s3_bucket_versioning.this.versioning_configuration
    }

    s3_bucket_website_configuration = length(aws_s3_bucket_website_configuration.this) == 0 ? null : {
      bucket                   = aws_s3_bucket_website_configuration.this[0].bucket
      error_document           = aws_s3_bucket_website_configuration.this[0].error_document
      id                       = aws_s3_bucket_website_configuration.this[0].id
      index_document           = aws_s3_bucket_website_configuration.this[0].index_document
      redirect_all_requests_to = aws_s3_bucket_website_configuration.this[0].redirect_all_requests_to
      region                   = aws_s3_bucket_website_configuration.this[0].region
      routing_rule             = aws_s3_bucket_website_configuration.this[0].routing_rule
      routing_rules            = aws_s3_bucket_website_configuration.this[0].routing_rules
      website_domain           = aws_s3_bucket_website_configuration.this[0].website_domain
      website_endpoint         = aws_s3_bucket_website_configuration.this[0].website_endpoint
    }
  }
}
