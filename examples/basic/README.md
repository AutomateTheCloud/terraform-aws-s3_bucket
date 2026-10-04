# Basic bucket

A private bucket with versioning turned on, and a lifecycle rule that deletes old versions after 30 days. Without a rule like this, every overwritten or deleted object is kept, and billed, forever.

Everything else uses the module's defaults: public access blocked, HTTPS required, SSE-S3 encryption, and ACLs off.

## Run it

```shell
terraform init
terraform apply -var 'name=<a globally unique bucket name>'
```

Remove it with `terraform destroy` and the same `-var`. Destroying fails if the bucket still holds objects, so that data is never deleted by accident.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_name"></a> [name](#input_name)

Description: Name of the bucket, which must be globally unique

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_bucket"></a> [bucket](#output_bucket)

Description: Name and ARN of the bucket
<!-- END_TF_DOCS -->
