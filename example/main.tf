terraform {
  required_version = "~> 1.11.0"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

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
  object_lock = {
    enabled        = true
    days = 5
    # years = 1
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

output "metadata" {
  description = "Metadata"
  value       = module.s3_bucket.metadata
}
