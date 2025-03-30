# AutomateTheCloud - AWS - S3 Bucket - Terraform Module
Terraform module to create an S3 Bucket

***

## Usage
```hcl
module "s3_bucket" {
  source    = "../"
  providers = { aws.this = aws.us-east-1 }

  details = {
    scope       = "Demo"
    purpose     = "S3 Bucket"
    environment = "prd"
    additional_tags = {
      "Project"   = "Project Name"
      "ProjectID" = "123456789"
      "Contact"   = "David Singer - david.singer@example.com"
    }
  }

  name          = "demo-bucket-123456789zz"
  force_destroy = true
  cors = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["PUT", "POST"]
      allowed_origins = ["https://s3-website-test.hashicorp.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    },
    {
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
    }
  ]
  lifecycle_rules = [
    {
      rule_name                              = "Cleanup (Non-Current)"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
      noncurrent_version_expiration          = { days = 1 }
      expiration                             = { expired_object_delete_marker = true }
    },
    {
      rule_name                              = "Cleanup (Archive)"
      enabled                                = true
      prefix                                 = "archive/"
      abort_incomplete_multipart_upload_days = 1
      transition = [
        {
          days          = 2
          storage_class = "GLACIER"
        }
      ]
      expiration = { days = 420 }
    },
    {
      rule_name                              = "Cleanup (Quarantine)"
      enabled                                = true
      prefix                                 = "quarantine/"
      abort_incomplete_multipart_upload_days = 1
      expiration                             = { days = 30 }
    }
  ]
  logging = {
    bucket = "logs-use1-012345678901"
  }
  policy = {
    require_encrypted_transport = true
    use_for_aws_account_logging = true
    aws_account_read_access = [
      "012345678901",
      "987654321098"
    ]
    aws_account_write_access = []
    aws_organization_read_access = [
      "o-abcdefghi",
    ]
    aws_organization_write_access = []
  }
  public = {
    enabled = false
  }
  public_access_block = {
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
  }
  website = {
    enabled        = true
    index_document = "index.html"
  }
  server_side_encryption = {
    bucket_key_enabled = true
    kms_enabled        = true
    # kms_key_id = "alias/key_name"
  }
  versioning = {
    enabled = true
  }
}
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `cors` | Cross Origin Resource Sharing [CORS](#input-cors) | `any` | |
| `enable_object_lock` | Enable Object Lock | `bool` | `false` |
| `enable_transfer_acceleration` | Enable S3 Transfer Acceleration | `bool` | `false` |
| `force_destroy` | S3 Bucket Force destroy flag for behavior during `terraform destroy` | `bool` | `false` |
| `lifecycle_rule` | [Lifecycle rules](#input-lifecycle-rules) |
| `logging` | [Logging](#input-logging) | `any` | |
| `name` | The name of the bucket | `string` | |
| `object_lock` | [Object Lock](#input-object-lock) | `any` | |
| `policy` | [Policy](#input-policy) | `any` | |
| `public` | [Public Settings](#input-public-settings) | `any` | |
| `public_access_block` | [Public Access Block](#input-public-access-block) | `any` | |
| `requester_pays` | Requester Pays | `bool` | `false` |
| `s3_bucket_additional_tags` | S3Bucket - Additional Tags | `map` | `{}` |
| `server_side_encryption` | [Server-Side Encryption](#input-server-side-encryption) | `any` | |
| `versioning` | [Versioning](#input-versioning) | `any` | |
| `website` | [Website](#input-website) | `any` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object server? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

### Input - CORS
- TODO: CORS

### Input - Lifecycle Rules
- Allows Configuration of multiple distinct Lifecycle Rules
- Supports: `Transition`, `Expiration`, `Non-Current Version Transition`, `Non-Current Version Expiration`
- Placeholder Support
  - When adding rules to cleanup certain resources (like CloudTrail logs), you may need to specify the Account ID or Region. You might not have that information hardcoded somewhere in your Terraform Stack and would prefer to have it figured out for you.
  - Placeholders:
    - `[[ACCOUNT_ID]]` => regex replaced with the AWS Account ID
    - `[[REGION]]` => regex replaced with the AWS Region where the S3 Bucket resides
- More info:
  - https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
  - https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
- Model:
```
[
  {
    rule_name                              = <rule_name>
    enabled                                = <true | false>
    prefix                                 = <prefix, optional>
    abort_incomplete_multipart_upload_days = <number, optional>
    transition = [
      {
        days                       = <number>
        date                       = <date, optional if not specifying days>
        storage_class              = <STANDARD | STANDARD_IA | ONEZONE_IA | INTELLIGENT_TIERING | GLACIER, | DEEP_ARCHIVE>
      },
      {...}
    ]
    expiration = {
      days                         = <number>
      date                         = <date, optional if not specifying days>
      expired_object_delete_marker = <true/false>
    }
    noncurrent_version_transition = [
      {
        days                       = <number>
        storage_class              = <STANDARD | STANDARD_IA | ONEZONE_IA | INTELLIGENT_TIERING | GLACIER, | DEEP_ARCHIVE>
      },
      {...}
    ]
    noncurrent_version_expiration = {
      days                         = <number>
    }
  },
  {...}
]
```

- Full Example:
```
[
    {
      rule_name                                  = "Cleanup (General)"
      enabled                                    = true
      abort_incomplete_multipart_upload_days     = 7
    },
    {
      rule_name                                  = "Cleanup (CloudTrail)"
      enabled                                    = true
      prefix                                     = "AWSLogs/[[ACCOUNT_ID]]/CloudTrail/"
      abort_incomplete_multipart_upload_days     = 1
      expiration                                 = { days = 365 }
      noncurrent_version_expiration              = { days = 90 }
    },
    {
      rule_name                                  = "Cleanup (CloudTrail-Digest)"
      enabled                                    = true
      prefix                                     = "AWSLogs/[[ACCOUNT_ID]]/CloudTrail-Digest/"
      abort_incomplete_multipart_upload_days     = 1
      expiration                                 = { days = 365 }
      noncurrent_version_expiration              = { days = 90 }
    },
    {
      rule_name                                  = "Cleanup (With all the Options)"
      enabled                                    = true
      prefix                                     = "with/all/the/options/"
      abort_incomplete_multipart_upload_days     = 7
      transition = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 60, storage_class = "GLACIER" }
      ]
      expiration = { days = 365 }
      noncurrent_version_transition = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 60, storage_class = "GLACIER" }
      ]
      noncurrent_version_expiration = { days = 365 }
    }
  ]
```

### Input - Logging
- TODO: Logging

### Input - Policy
- TODO: Policy

### Input - Public Settings
- TODO: Public Settings Block

### Input - Public Access Block
- TODO: Public Access Block

### Input - Server-Side Encryption
- TODO: Server-Side Encryption

### Input - Versioning
- TODO: Versioning

### Input - Website
- TODO: Website

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens, if not hundreds!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `aws.account.id` | AWS Account ID |
| `aws.region.name` | AWS Region name, example: `us-east-1` |
| `aws.region.abbr` | AWS Region four letter abbreviation, example: `use1` |
| `aws.region.description` | AWS Region description, example: `US East (N. Virginia)` |
| `s3_bucket` | S3 Bucket |
| `s3_bucket_accelerate_configuration` | S3 Bucket - Accelerate Configuration |
| `s3_bucket_acl` | S3 Bucket - ACL |
| `s3_bucket_cors_configuration` | S3 Bucket - CORS Configuration |
| `s3_bucket_lifecycle_configuration` | S3 Bucket - Lifecycle Configuration |
| `s3_bucket_logging` | S3 Bucket - Logging |
| `s3_bucket_policy` | S3 Bucket - Policy |
| `s3_bucket_public_access_block` | S3 Bucket - Public Access Block |
| `s3_bucket_server_side_encryption_configuration` | S3 Bucket - Server-side Encryption Configuration |
| `s3_bucket_versioning` | S3 Bucket - Versioning |
| `s3_bucket_website_configuration` | S3 Bucket - Website Configuration |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

### KMS - Warning
I do not recommend enabling KMS on All-Purpose Generic Log Buckets (ie: for things like S3 Logs, ELB Logs, Flow Logs, etc). Not every AWS service plays nice with Log Delivery when KMS is enabled on the S3 Bucket. In fact, S3 Access logs can not be shipped to a destination bucket which is using KMS (AES256 works).

This option is great for buckets designed to capture CloudTrail logs though! CloudTrail Logs, according to the CIS Benchmarks really shouldnt be collected in your All-Purpose Log bucket anyway, as they want you to Log the S3 Delivery of the Trail to S3, which you cant do in the same bucket (well, you can, but it creates an infinite loop of log delivery, which is very, very bad)

### Logging Bucket - Warning
If the bucket you are creating will be used to store S3 action logs from other buckets, **DO NOT** configure this bucket to write logs somewhere else. Just think about it - for example, you set up 2 different log buckets and want to log S3 actions for each of those buckets. You decide to send the S3 action logs to each of the buckets. Writing an S3 action log to an S3 Bucket is a PUT action, and will be logged. This WILL create an infinite loop (*Well, almost infinite. Your credit card will max out at some point, which I suppose would stop the process when you get the bill*)

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
