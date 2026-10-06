# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "cors" {
  description = <<-EOT
    Cross-Origin Resource Sharing (CORS) rules, which let web pages on other domains request objects from the bucket. An empty list creates no CORS configuration.

    Each rule takes:

    - `allowed_methods` - (Required) HTTP methods to allow: `GET`, `PUT`, `HEAD`, `POST` or `DELETE`.
    - `allowed_origins` - (Required) Origins to allow, such as `https://example.org`, or `*` for any origin.
    - `allowed_headers` - (Optional) Request headers to allow.
    - `expose_headers` - (Optional) Response headers that browsers may read.
    - `max_age_seconds` - (Optional) How long browsers may cache the preflight response.
  EOT
  type = list(object({
    allowed_headers = optional(list(string))
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default  = []
  nullable = false
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "enable_transfer_acceleration" {
  description = <<-EOT
    Turn on S3 Transfer Acceleration, which routes uploads and downloads through CloudFront edge locations. It is billed per GB transferred, and bucket names containing periods cannot use it.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "force_destroy" {
  description = <<-EOT
    Delete every object, including locked objects and old versions, when the bucket is destroyed. Without it, Terraform cannot destroy a bucket that still holds objects. Deleted objects cannot be recovered.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "lifecycle_rules" {
  description = <<-EOT
    Lifecycle rules, which expire objects or move them to cheaper storage classes over time. An empty list creates no lifecycle configuration.

    Each rule takes:

    - `rule_name` - (Required) A unique name for the rule.
    - `enabled` - (Required) Whether the rule is applied.
    - `prefix` - (Optional) Apply the rule only to keys that start with this prefix. `[[ACCOUNT_ID]]` and `[[REGION]]` are replaced with the bucket's account ID and Region, for log paths such as `AWSLogs/[[ACCOUNT_ID]]/CloudTrail/[[REGION]]/`. With no prefix and no size filter, the rule applies to the whole bucket.
    - `object_size_greater_than`, `object_size_less_than` - (Optional) Apply the rule only to objects in this size range, in bytes.
    - `abort_incomplete_multipart_upload_days` - (Optional) Delete the parts of uploads that were never completed, this many days after they started.
    - `expiration` - (Optional) Delete current objects: `days` after creation or on a `date` (`YYYY-MM-DD`), or set `expired_object_delete_marker = true` to remove delete markers with no versions behind them.
    - `transition` - (Optional) A list of moves to another storage class, each with `storage_class` and either `days` or `date`.
    - `noncurrent_version_expiration` - (Optional) Delete old versions `days` after they stop being current, keeping the newest `newer_noncurrent_versions` of them.
    - `noncurrent_version_transition` - (Optional) A list of moves of old versions to another storage class, each with `days`, `storage_class` and optional `newer_noncurrent_versions`.
  EOT
  type = list(object({
    rule_name                              = string
    enabled                                = bool
    prefix                                 = optional(string)
    object_size_greater_than               = optional(number)
    object_size_less_than                  = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
    expiration = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))
    transition = optional(list(object({
      days          = optional(number)
      date          = optional(string)
      storage_class = string
    })), [])
    noncurrent_version_expiration = optional(object({
      days                      = number
      newer_noncurrent_versions = optional(number)
    }))
    noncurrent_version_transition = optional(list(object({
      days                      = number
      storage_class             = string
      newer_noncurrent_versions = optional(number)
    })), [])
  }))
  default  = []
  nullable = false
}

variable "logging" {
  description = <<-EOT
    Server access logging: where this bucket sends a record of each request made to it. `null`, the default, turns logging off.

    - `bucket_name` - (Required) The bucket that receives the logs. It must be in the same Region and account, and its policy must let `logging.s3.amazonaws.com` write to it. See the [log bucket example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/log-bucket).
    - `prefix` - (Optional) Key prefix for the logs, without a trailing slash. Defaults to `s3`.
    - `partition_date_source` - (Optional) Which date partitions the log keys: `EventTime` (the default) or `DeliveryTime`.

    Do not send a bucket's logs to itself. Each log delivery is itself a request that gets logged, so the logs never stop growing.
  EOT
  type = object({
    bucket_name           = string
    prefix                = optional(string)
    partition_date_source = optional(string, "EventTime")
  })
  default = null

  validation {
    condition     = var.logging == null || contains(["EventTime", "DeliveryTime"], try(var.logging.partition_date_source, ""))
    error_message = "logging.partition_date_source must be \"EventTime\" or \"DeliveryTime\"."
  }
}

variable "name" {
  description = <<-EOT
    The name of the bucket. Bucket names are global across all AWS accounts: 3 to 63 characters of lowercase letters, numbers, periods and hyphens, beginning and ending with a letter or number.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.name))
    error_message = "name must be 3-63 characters of lowercase letters, numbers, periods and hyphens, and must begin and end with a letter or number."
  }
}

variable "object_lock" {
  description = <<-EOT
    S3 Object Lock, which stops objects from being deleted or overwritten for a retention period. `null`, the default, leaves it off.

    Object Lock requires `versioning = { enabled = true }`. It can be turned on for an existing bucket, but never turned off: removing `object_lock` later only removes the default retention.

    - `enabled` - (Optional) Defaults to `true` when `object_lock` is set.
    - `mode` - (Optional) `GOVERNANCE` (the default), which users with special permission can override, or `COMPLIANCE`, which nobody can override, including the account's root user.
    - `days` or `years` - (Optional) Default retention for new objects. Set one, not both. Leave both unset to lock only the objects you give a retention period.
  EOT
  type = object({
    enabled = optional(bool, true)
    mode    = optional(string, "GOVERNANCE")
    days    = optional(number)
    years   = optional(number)
  })
  default = null

  validation {
    condition     = var.object_lock == null || contains(["GOVERNANCE", "COMPLIANCE"], try(var.object_lock.mode, ""))
    error_message = "object_lock.mode must be \"GOVERNANCE\" or \"COMPLIANCE\"."
  }

  validation {
    condition     = var.object_lock == null || try(var.object_lock.days, null) == null || try(var.object_lock.years, null) == null
    error_message = "object_lock: set days or years, not both."
  }

  validation {
    condition     = !try(var.object_lock.enabled, false) || var.versioning.enabled
    error_message = "object_lock requires versioning = { enabled = true }."
  }
}

variable "policy" {
  description = <<-EOT
    The bucket policy. A policy is created when any option below grants or denies access. The default creates one with only the encrypted-transport rule.

    - `require_encrypted_transport` - (Optional) Deny every request not made over HTTPS. Defaults to `true`.
    - `public_read` - (Optional) Let anyone on the internet read every object. Defaults to `false`. Requires `public_access_block` to allow public policies; see the [static website example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/static-website).
    - `aws_account_read_access` - (Optional) 12-digit AWS account IDs that may list the bucket and read its objects.
    - `aws_account_write_access` - (Optional) 12-digit AWS account IDs that may also write and delete objects and manage the bucket policy.
    - `aws_organization_read_access`, `aws_organization_write_access` - (Optional) The same, for every account in an AWS Organization, by organization ID (`o-xxxxxxxxxx`).
    - `source_policy_documents` - (Optional) JSON policy documents whose statements are added to the policy, for anything the options above do not cover, such as letting AWS services deliver logs. Statement IDs (`Sid`) must be unique across the whole policy. See the [log bucket example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/log-bucket).
  EOT
  type = object({
    require_encrypted_transport   = optional(bool, true)
    public_read                   = optional(bool, false)
    aws_account_read_access       = optional(list(string), [])
    aws_account_write_access      = optional(list(string), [])
    aws_organization_read_access  = optional(list(string), [])
    aws_organization_write_access = optional(list(string), [])
    source_policy_documents       = optional(list(string), [])
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for doc in var.policy.source_policy_documents : can(jsondecode(doc).Statement[0])])
    error_message = "Each of policy.source_policy_documents must be a JSON policy document with a non-empty Statement list."
  }

  validation {
    condition = alltrue([
      for id in concat(var.policy.aws_account_read_access, var.policy.aws_account_write_access) : can(regex("^[0-9]{12}$", id))
    ])
    error_message = "policy.aws_account_read_access and aws_account_write_access must contain 12-digit AWS account IDs."
  }

  validation {
    condition = alltrue([
      for id in concat(var.policy.aws_organization_read_access, var.policy.aws_organization_write_access) : can(regex("^o-[a-z0-9]{10,32}$", id))
    ])
    error_message = "policy.aws_organization_read_access and aws_organization_write_access must contain AWS Organization IDs (o-xxxxxxxxxx)."
  }

  validation {
    condition     = !var.policy.public_read || (!var.public_access_block.block_public_policy && !var.public_access_block.restrict_public_buckets)
    error_message = "policy.public_read requires public_access_block.block_public_policy = false and public_access_block.restrict_public_buckets = false."
  }
}

variable "public_access_block" {
  description = <<-EOT
    The bucket's Public Access Block settings. Everything is blocked by default, which is right for almost every bucket.

    - `block_public_acls` - (Optional) Reject requests that add public ACLs. Defaults to `true`.
    - `block_public_policy` - (Optional) Reject bucket policies that grant public access. Defaults to `true`.
    - `ignore_public_acls` - (Optional) Ignore public ACLs already present. Defaults to `true`.
    - `restrict_public_buckets` - (Optional) Limit access under a public policy to AWS services and the bucket owner's account. Defaults to `true`.

    An account-level Public Access Block, if the account has one, overrides these settings.
  EOT
  type = object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the bucket and its configuration in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}

variable "requester_pays" {
  description = <<-EOT
    Make the requester, not the bucket owner, pay for requests and data transfer. Anonymous requests are then rejected.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "s3_bucket_additional_tags" {
  description = <<-EOT
    Tags applied to the bucket only. Tags for every resource go in `details.additional_tags`.
  EOT
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "server_side_encryption" {
  description = <<-EOT
    Default encryption for new objects. Without changes, objects are encrypted with keys S3 manages (SSE-S3, `AES256`).

    - `kms_enabled` - (Optional) Encrypt with AWS Key Management Service (SSE-KMS) instead. Defaults to `false`.
    - `kms_key_id` - (Optional) ARN of the KMS key or alias to use. Requires `kms_enabled`. Without it, S3 uses the AWS managed key `aws/s3`. Use an ARN: S3 looks up a bare key ID or alias name in the account of whoever writes the object, not the bucket owner's.
    - `bucket_key_enabled` - (Optional) Use an S3 Bucket Key, which cuts KMS request costs. Applies only with `kms_enabled`. Defaults to `false`.

    Several AWS services, including Elastic Load Balancing and Amazon Redshift, can deliver logs only to buckets that use SSE-S3.
  EOT
  type = object({
    kms_enabled        = optional(bool, false)
    kms_key_id         = optional(string)
    bucket_key_enabled = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.server_side_encryption.kms_key_id == null || var.server_side_encryption.kms_enabled
    error_message = "server_side_encryption.kms_key_id requires kms_enabled = true."
  }

  validation {
    condition     = var.server_side_encryption.kms_key_id == null || startswith(coalesce(var.server_side_encryption.kms_key_id, "-"), "arn:")
    error_message = "server_side_encryption.kms_key_id must be a key ARN or alias ARN. S3 resolves a bare key ID or alias name in the account of whoever writes the object, not the bucket owner."
  }
}

variable "versioning" {
  description = <<-EOT
    Versioning, which keeps every version of every object so that overwritten and deleted objects can be recovered.

    - `enabled` - (Optional) Defaults to `false`, which sets versioning to `Suspended`. Once a bucket has had versioning enabled, it can be suspended but never fully turned off.

    Pair versioning with a `noncurrent_version_expiration` lifecycle rule, or old versions are kept, and billed, forever.
  EOT
  type = object({
    enabled = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "website" {
  description = <<-EOT
    Static website hosting. `null`, the default, leaves it off. Set exactly one of `index_document` or `redirect_all_requests_to`.

    Hosting a website does not make the bucket public. To serve it directly from S3, also set `policy.public_read`. For production sites, serving through CloudFront keeps the bucket private.

    - `enabled` - (Optional) Defaults to `true` when `website` is set.
    - `index_document` - The page returned for requests to a directory, such as `index.html`.
    - `error_document` - (Optional) The page returned for errors, such as `404.html`.
    - `redirect_all_requests_to` - Redirect every request to `host_name`, with an optional `protocol` (`http` or `https`).
    - `routing_rules` - (Optional) A list of redirect rules. Each has an optional `condition` (`key_prefix_equals`, `http_error_code_returned_equals`) and a `redirect` (`host_name`, `http_redirect_code`, `protocol`, `replace_key_prefix_with`, `replace_key_with`).
  EOT
  type = object({
    enabled        = optional(bool, true)
    index_document = optional(string)
    error_document = optional(string)
    redirect_all_requests_to = optional(object({
      host_name = string
      protocol  = optional(string)
    }))
    routing_rules = optional(list(object({
      condition = optional(object({
        http_error_code_returned_equals = optional(string)
        key_prefix_equals               = optional(string)
      }))
      redirect = object({
        host_name               = optional(string)
        http_redirect_code      = optional(string)
        protocol                = optional(string)
        replace_key_prefix_with = optional(string)
        replace_key_with        = optional(string)
      })
    })), [])
  })
  default = null

  validation {
    condition     = var.website == null || ((try(var.website.index_document, null) != null) != (try(var.website.redirect_all_requests_to, null) != null))
    error_message = "website: set exactly one of index_document or redirect_all_requests_to."
  }
}
