# Log bucket

Two buckets: one that receives logs, and one that sends its S3 access logs to it.

The module has no switch that turns a bucket into a log bucket. A log bucket is an ordinary bucket whose policy lets particular AWS services write to it, so this example writes that policy with `aws_iam_policy_document` and passes it to the module in `policy.source_policy_documents`. It allows two services, and limits each one:

- **S3 server access logs** may write only under `s3/`, and only for buckets in this account (`aws:SourceAccount`).
- **Elastic Load Balancing access logs** may write only under `elb/AWSLogs/<this account ID>/`, as AWS recommends. Load balancers that use this bucket need the prefix `elb`.

The log bucket keeps the default SSE-S3 encryption, which Elastic Load Balancing requires, and a lifecycle rule deletes logs after a year.

To collect logs from another service, such as CloudTrail or AWS Config, add a statement with the service principal and conditions that service's documentation gives.

## Run it

```shell
terraform init
terraform apply -var 'name_prefix=<a short unique prefix>'
```

The bucket names are built from the prefix, the account ID and the Region. S3 can take a few hours to deliver the first access logs.

Remove everything with `terraform destroy` and the same `-var`. Destroying fails while either bucket holds objects; empty them first.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix)

Description: Prefix for the bucket names, which must be globally unique

Type: `string`

Default: `"example"`

### Outputs

The following outputs are exported:

#### <a name="output_log_bucket"></a> [log_bucket](#output_log_bucket)

Description: n/a
<!-- END_TF_DOCS -->
