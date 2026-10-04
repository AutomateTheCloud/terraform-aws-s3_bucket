# Complete

One private bucket that uses most of the module's options together:

- Encryption with your own AWS Key Management Service (KMS) key, with an S3 Bucket Key to reduce KMS costs.
- Versioning, and Object Lock in `GOVERNANCE` mode with 30 days of default retention.
- Access logs sent to an existing log bucket. The [log bucket example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/log-bucket) creates one.
- Read access for other AWS accounts.
- A CORS rule for one website origin.
- Lifecycle rules that delete old versions and move `archive/` to cheaper storage classes.

It is not public and does not host a website; see the [static website example](https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/tree/main/examples/static-website) for that.

## Run it

You need an existing KMS key and log bucket in the same Region.

```shell
terraform init
terraform apply \
  -var 'name=<a globally unique bucket name>' \
  -var 'log_bucket_name=<existing log bucket>' \
  -var 'kms_key_arn=<KMS key ARN>'
```

Object Lock keeps every object version for 30 days. During that time `terraform destroy` cannot delete the bucket unless the objects are removed by someone with the `s3:BypassGovernanceRetention` permission. Object Lock cannot be turned off once it is on.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_kms_key_arn"></a> [kms_key_arn](#input_kms_key_arn)

Description: ARN of the KMS key that encrypts new objects

Type: `string`

#### <a name="input_log_bucket_name"></a> [log_bucket_name](#input_log_bucket_name)

Description: Existing bucket that receives this bucket's access logs. See the log-bucket example.

Type: `string`

#### <a name="input_name"></a> [name](#input_name)

Description: Name of the bucket, which must be globally unique

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_reader_account_ids"></a> [reader_account_ids](#input_reader_account_ids)

Description: AWS account IDs that may read the bucket

Type: `list(string)`

Default: `[]`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, and the names and tags it worked out
<!-- END_TF_DOCS -->
