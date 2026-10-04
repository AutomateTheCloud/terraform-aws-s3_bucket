# Static website

A public website served directly from S3. It takes three settings together:

- `website` turns on hosting and names the index and error pages.
- `policy.public_read` lets anyone read the bucket's objects.
- `public_access_block` allows a public bucket policy. Public ACLs stay blocked.

S3 website endpoints serve HTTP only, so this example also turns off the module's HTTPS-only rule. For a production site, keep the bucket private and serve it through CloudFront, which supports HTTPS and custom domains.

## Run it

```shell
terraform init
terraform apply -var 'name=<a globally unique bucket name>'
```

Then upload a page and open the `website_endpoint` output in a browser:

```shell
echo '<h1>Hello</h1>' > index.html
aws s3 cp index.html "s3://<bucket name>/index.html" --content-type text/html
```

If your AWS account has an account-level Public Access Block, the apply fails with an access-denied error on the bucket policy. That setting is there on purpose; turn it off only if this account is meant to host public content.

Remove everything with `aws s3 rm "s3://<bucket name>" --recursive`, then `terraform destroy`.

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

#### <a name="output_website_endpoint"></a> [website_endpoint](#output_website_endpoint)

Description: The website's URL
<!-- END_TF_DOCS -->
