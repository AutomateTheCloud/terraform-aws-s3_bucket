# Terraform module for Amazon S3 buckets

Creates an Amazon Simple Storage Service (S3) bucket and its configuration: encryption, versioning, lifecycle rules, access logging, the bucket policy, and optional features such as static website hosting and Object Lock.

The defaults are the settings most buckets should have. A bucket created with only the required inputs is private, rejects requests that are not made over HTTPS, encrypts every object, and has access control lists (ACLs) turned off.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Public access | Blocked | `public_access_block`, `policy.public_read` |
| ACLs | Off: the bucket owner owns every object | Not configurable |
| Encryption | SSE-S3 (`AES256`) | `server_side_encryption` |
| HTTPS-only access | On | `policy.require_encrypted_transport` |
| Versioning | Suspended | `versioning` |
| Lifecycle rules | None | `lifecycle_rules` |
| Access logging | Off | `logging` |
| Access for other accounts | None | `policy` |
| Cross-Origin Resource Sharing (CORS) | None | `cors` |
| Static website hosting | Off | `website` |
| Object Lock | Off | `object_lock` |
| Transfer Acceleration | Off | `enable_transfer_acceleration` |
| Requester Pays | Off | `requester_pays` |

## Usage

```hcl
module "s3_bucket" {
  source  = "AutomateTheCloud/s3_bucket/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Course Materials"
    environment = "Production"
  }

  name       = "example-course-materials"
  versioning = { enabled = true }
}
```

`details` and `name` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on every resource.

The module uses your default `aws` provider and creates everything in that provider's Region. To create the bucket somewhere else without configuring another provider, set `region`:

```hcl
module "s3_bucket_us_west_2" {
  source  = "AutomateTheCloud/s3_bucket/aws"
  version = "~> 1.0"

  region  = "us-west-2"
  details = { scope = "Automate the Cloud", purpose = "Backups", environment = "Production" }
  name    = "example-backups-us-west-2"
}
```

Because `region` is an ordinary input, one module block can create a bucket in each of several Regions with `for_each`.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the bucket belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a bucket in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the bucket, its certificate, its DNS zone and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "site_bucket" {
  source  = "AutomateTheCloud/s3_bucket/aws"
  version = "~> 1.0"

  details = local.details
  name    = "example-web-site-production"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.site_bucket.metadata.s3_bucket.arn` for the bucket's ARN, or `module.site_bucket.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`.

- [Basic bucket](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/basic): a private, versioned bucket that cleans up old versions.
- [Static website](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/static-website): a public website served directly from S3.
- [Log bucket](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/log-bucket): a bucket that AWS services deliver logs to, and a bucket that sends its access logs there.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/complete): most of the module's options in one private bucket.

## Things to know

### Letting AWS services deliver logs

The module has no "log bucket" setting. A log bucket is an ordinary bucket whose policy lets particular AWS services write to it, and which services, accounts and key prefixes to allow depends on what you are collecting. Write those grants yourself and pass them in `policy.source_policy_documents`. The [log bucket example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/log-bucket) shows grants for S3 access logs and Elastic Load Balancing, each limited to one account and one prefix.

Several services, including Elastic Load Balancing and Amazon Redshift, can deliver logs only to buckets encrypted with SSE-S3, the default.

Do not send a bucket's access logs to itself, or set two buckets to log to each other. Each log delivery is a request that is logged in turn, so the logs never stop growing.

### Public buckets and websites

Turning on `website` does not make the bucket public. Serving a website straight from S3 takes three settings together: `website`, `policy.public_read`, and a `public_access_block` that allows public policies. The [static website example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/static-website) shows all three. S3 website endpoints serve HTTP only; for HTTPS, put CloudFront in front of the bucket and keep the bucket private.

An account-level Public Access Block, if your account has one, overrides the bucket's settings, and a public policy is rejected.

### Object Lock

Object Lock stops objects from being deleted or overwritten during a retention period. It needs versioning, and it can be turned on for an existing bucket but never turned off. In `COMPLIANCE` mode, nobody can shorten a retention period or delete a locked object before it expires, including the account's root user. Try `GOVERNANCE` mode first.

### Encryption keys

To use your own AWS Key Management Service (KMS) key, pass its ARN in `server_side_encryption.kms_key_id`, not a key ID or alias name. S3 looks up a bare key ID or alias in the account of whoever writes the object, which is not always the bucket owner.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_name"></a> [name](#input_name)

Description: The name of the bucket. Bucket names are global across all AWS accounts: 3 to 63 characters of lowercase letters, numbers, periods and hyphens, beginning and ending with a letter or number.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_cors"></a> [cors](#input_cors)

Description: Cross-Origin Resource Sharing (CORS) rules, which let web pages on other domains request objects from the bucket. An empty list creates no CORS configuration.

Each rule takes:

- `allowed_methods` - (Required) HTTP methods to allow: `GET`, `PUT`, `HEAD`, `POST` or `DELETE`.
- `allowed_origins` - (Required) Origins to allow, such as `https://example.org`, or `*` for any origin.
- `allowed_headers` - (Optional) Request headers to allow.
- `expose_headers` - (Optional) Response headers that browsers may read.
- `max_age_seconds` - (Optional) How long browsers may cache the preflight response.

Type:

```hcl
list(object({
    allowed_headers = optional(list(string))
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
```

Default: `[]`

#### <a name="input_enable_transfer_acceleration"></a> [enable_transfer_acceleration](#input_enable_transfer_acceleration)

Description: Turn on S3 Transfer Acceleration, which routes uploads and downloads through CloudFront edge locations. It is billed per GB transferred, and bucket names containing periods cannot use it.

Type: `bool`

Default: `false`

#### <a name="input_force_destroy"></a> [force_destroy](#input_force_destroy)

Description: Delete every object, including locked objects and old versions, when the bucket is destroyed. Without it, Terraform cannot destroy a bucket that still holds objects. Deleted objects cannot be recovered.

Type: `bool`

Default: `false`

#### <a name="input_lifecycle_rules"></a> [lifecycle_rules](#input_lifecycle_rules)

Description: Lifecycle rules, which expire objects or move them to cheaper storage classes over time. An empty list creates no lifecycle configuration.

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

Type:

```hcl
list(object({
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
```

Default: `[]`

#### <a name="input_logging"></a> [logging](#input_logging)

Description: Server access logging: where this bucket sends a record of each request made to it. `null`, the default, turns logging off.

- `bucket_name` - (Required) The bucket that receives the logs. It must be in the same Region and account, and its policy must let `logging.s3.amazonaws.com` write to it. See the [log bucket example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/log-bucket).
- `prefix` - (Optional) Key prefix for the logs, without a trailing slash. Defaults to `s3`.
- `partition_date_source` - (Optional) Which date partitions the log keys: `EventTime` (the default) or `DeliveryTime`.

Do not send a bucket's logs to itself. Each log delivery is itself a request that gets logged, so the logs never stop growing.

Type:

```hcl
object({
    bucket_name           = string
    prefix                = optional(string)
    partition_date_source = optional(string, "EventTime")
  })
```

Default: `null`

#### <a name="input_object_lock"></a> [object_lock](#input_object_lock)

Description: S3 Object Lock, which stops objects from being deleted or overwritten for a retention period. `null`, the default, leaves it off.

Object Lock requires `versioning = { enabled = true }`. It can be turned on for an existing bucket, but never turned off: removing `object_lock` later only removes the default retention.

- `enabled` - (Optional) Defaults to `true` when `object_lock` is set.
- `mode` - (Optional) `GOVERNANCE` (the default), which users with special permission can override, or `COMPLIANCE`, which nobody can override, including the account's root user.
- `days` or `years` - (Optional) Default retention for new objects. Set one, not both. Leave both unset to lock only the objects you give a retention period.

Type:

```hcl
object({
    enabled = optional(bool, true)
    mode    = optional(string, "GOVERNANCE")
    days    = optional(number)
    years   = optional(number)
  })
```

Default: `null`

#### <a name="input_policy"></a> [policy](#input_policy)

Description: The bucket policy. A policy is created when any option below grants or denies access. The default creates one with only the encrypted-transport rule.

- `require_encrypted_transport` - (Optional) Deny every request not made over HTTPS. Defaults to `true`.
- `public_read` - (Optional) Let anyone on the internet read every object. Defaults to `false`. Requires `public_access_block` to allow public policies; see the [static website example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/static-website).
- `aws_account_read_access` - (Optional) 12-digit AWS account IDs that may list the bucket and read its objects.
- `aws_account_write_access` - (Optional) 12-digit AWS account IDs that may also write and delete objects and manage the bucket policy.
- `aws_organization_read_access`, `aws_organization_write_access` - (Optional) The same, for every account in an AWS Organization, by organization ID (`o-xxxxxxxxxx`).
- `source_policy_documents` - (Optional) JSON policy documents whose statements are added to the policy, for anything the options above do not cover, such as letting AWS services deliver logs. Statement IDs (`Sid`) must be unique across the whole policy. See the [log bucket example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/log-bucket).

Type:

```hcl
object({
    require_encrypted_transport   = optional(bool, true)
    public_read                   = optional(bool, false)
    aws_account_read_access       = optional(list(string), [])
    aws_account_write_access      = optional(list(string), [])
    aws_organization_read_access  = optional(list(string), [])
    aws_organization_write_access = optional(list(string), [])
    source_policy_documents       = optional(list(string), [])
  })
```

Default: `{}`

#### <a name="input_public_access_block"></a> [public_access_block](#input_public_access_block)

Description: The bucket's Public Access Block settings. Everything is blocked by default, which is right for almost every bucket.

- `block_public_acls` - (Optional) Reject requests that add public ACLs. Defaults to `true`.
- `block_public_policy` - (Optional) Reject bucket policies that grant public access. Defaults to `true`.
- `ignore_public_acls` - (Optional) Ignore public ACLs already present. Defaults to `true`.
- `restrict_public_buckets` - (Optional) Limit access under a public policy to AWS services and the bucket owner's account. Defaults to `true`.

An account-level Public Access Block, if the account has one, overrides these settings.

Type:

```hcl
object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
```

Default: `{}`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the bucket and its configuration in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.

Type: `string`

Default: `null`

#### <a name="input_requester_pays"></a> [requester_pays](#input_requester_pays)

Description: Make the requester, not the bucket owner, pay for requests and data transfer. Anonymous requests are then rejected.

Type: `bool`

Default: `false`

#### <a name="input_s3_bucket_additional_tags"></a> [s3_bucket_additional_tags](#input_s3_bucket_additional_tags)

Description: Tags applied to the bucket only. Tags for every resource go in `details.additional_tags`.

Type: `map(string)`

Default: `{}`

#### <a name="input_server_side_encryption"></a> [server_side_encryption](#input_server_side_encryption)

Description: Default encryption for new objects. Without changes, objects are encrypted with keys S3 manages (SSE-S3, `AES256`).

- `kms_enabled` - (Optional) Encrypt with AWS Key Management Service (SSE-KMS) instead. Defaults to `false`.
- `kms_key_id` - (Optional) ARN of the KMS key or alias to use. Requires `kms_enabled`. Without it, S3 uses the AWS managed key `aws/s3`. Use an ARN: S3 looks up a bare key ID or alias name in the account of whoever writes the object, not the bucket owner's.
- `bucket_key_enabled` - (Optional) Use an S3 Bucket Key, which cuts KMS request costs. Applies only with `kms_enabled`. Defaults to `false`.

Several AWS services, including Elastic Load Balancing and Amazon Redshift, can deliver logs only to buckets that use SSE-S3.

Type:

```hcl
object({
    kms_enabled        = optional(bool, false)
    kms_key_id         = optional(string)
    bucket_key_enabled = optional(bool, false)
  })
```

Default: `{}`

#### <a name="input_versioning"></a> [versioning](#input_versioning)

Description: Versioning, which keeps every version of every object so that overwritten and deleted objects can be recovered.

- `enabled` - (Optional) Defaults to `false`, which sets versioning to `Suspended`. Once a bucket has had versioning enabled, it can be suspended but never fully turned off.

Pair versioning with a `noncurrent_version_expiration` lifecycle rule, or old versions are kept, and billed, forever.

Type:

```hcl
object({
    enabled = optional(bool, false)
  })
```

Default: `{}`

#### <a name="input_website"></a> [website](#input_website)

Description: Static website hosting. `null`, the default, leaves it off. Set exactly one of `index_document` or `redirect_all_requests_to`.

Hosting a website does not make the bucket public. To serve it directly from S3, also set `policy.public_read`. For production sites, serving through CloudFront keeps the bucket private.

- `enabled` - (Optional) Defaults to `true` when `website` is set.
- `index_document` - The page returned for requests to a directory, such as `index.html`.
- `error_document` - (Optional) The page returned for errors, such as `404.html`.
- `redirect_all_requests_to` - Redirect every request to `host_name`, with an optional `protocol` (`http` or `https`).
- `routing_rules` - (Optional) A list of redirect rules. Each has an optional `condition` (`key_prefix_equals`, `http_error_code_returned_equals`) and a `redirect` (`host_name`, `http_redirect_code`, `protocol`, `replace_key_prefix_with`, `replace_key_with`).

Type:

```hcl
object({
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
```

Default: `null`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `s3_bucket` - The bucket's `id` (its name), `arn`, `bucket_regional_domain_name`, `bucket_domain_name`, `bucket_region`, `hosted_zone_id`, `region`, `force_destroy`, `tags` and `tags_all`.
- One entry per configuration resource, such as `s3_bucket_policy` and `s3_bucket_website_configuration`. An entry is `null` when that resource is not created.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
