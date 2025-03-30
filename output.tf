output "metadata" {
  description = "Metadata"
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

    s3_bucket                                      = try(aws_s3_bucket.this, null)
    s3_bucket_accelerate_configuration             = try(aws_s3_bucket_accelerate_configuration.this, null)
    s3_bucket_cors_configuration                   = try(aws_s3_bucket_cors_configuration.this[0], null)
    s3_bucket_lifecycle_configuration              = try(aws_s3_bucket_lifecycle_configuration.this[0], null)
    s3_bucket_logging                              = try(aws_s3_bucket_logging.this[0], null)
    s3_bucket_ownership_controls                   = try(aws_s3_bucket_ownership_controls.this, null)
    s3_bucket_policy                               = try(aws_s3_bucket_policy.this[0], null)
    s3_bucket_public_access_block                  = try(aws_s3_bucket_public_access_block.this, null)
    s3_bucket_server_side_encryption_configuration = try(aws_s3_bucket_server_side_encryption_configuration.this, null)
    s3_bucket_versioning                           = try(aws_s3_bucket_versioning.this, null)
    s3_bucket_website_configuration                = try(aws_s3_bucket_website_configuration.this[0], null)
  }
}
