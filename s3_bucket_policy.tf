resource "aws_s3_bucket_policy" "this" {
  count  = local.create_s3_bucket_policy ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = jsonencode(jsondecode(data.aws_iam_policy_document.s3_bucket_policy-this[0].json))
  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_public_access_block.this
  ]
  provider = aws.this
}

data "aws_iam_policy_document" "s3_bucket_policy-this" {
  count = local.create_s3_bucket_policy ? 1 : 0

  # Require Encrypted Transport
  dynamic "statement" {
    for_each = try(var.policy.require_encrypted_transport, true) ? [1] : []
    content {
      sid    = "RequireEncryptedTransport"
      effect = "Deny"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions = [
        "s3:*"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }

  # AWS Account Read Access (share)
  dynamic "statement" {
    for_each = try(var.policy.aws_account_read_access, [])
    content {
      sid    = "AccountReadAccess1-${statement.value}"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
      actions = [
        "s3:List*"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}",
      ]
    }
  }
  dynamic "statement" {
    for_each = try(var.policy.aws_account_read_access, [])
    content {
      sid    = "AccountReadAccess2-${statement.value}"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
      actions = [
        "s3:Get*"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*",
      ]
    }
  }

  # AWS Account Write Access (share)
  dynamic "statement" {
    for_each = try(var.policy.aws_account_write_access, [])
    content {
      sid    = "AccountWriteAccess1-${statement.value}"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
      actions = [
        "s3:List*",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}",
      ]
    }
  }
  dynamic "statement" {
    for_each = try(var.policy.aws_account_write_access, [])
    content {
      sid    = "AccountWriteAccess2-${statement.value}"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
      actions = [
        "s3:*Object"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*",
      ]
    }
  }

  # AWS Organization Read Access (share)
  dynamic "statement" {
    iterator = aws_organization
    for_each = try(var.policy.aws_organization_read_access, [])
    content {
      effect = "Allow"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions = [
        "s3:List*"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}",
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [aws_organization.value]
      }
    }
  }
  dynamic "statement" {
    iterator = aws_organization
    for_each = try(var.policy.aws_organization_read_access, [])
    content {
      effect = "Allow"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions = [
        "s3:Get*"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*",
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [aws_organization.value]
      }
    }
  }

  # AWS Organization Write Access (share)
  dynamic "statement" {
    iterator = aws_organization
    for_each = try(var.policy.aws_organization_write_access, [])
    content {
      effect = "Allow"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions = [
        "s3:List*",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}",
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [aws_organization.value]
      }
    }
  }
  dynamic "statement" {
    iterator = aws_organization
    for_each = try(var.policy.aws_organization_write_access, [])
    content {
      effect = "Allow"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions = [
        "s3:*Object"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*",
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [aws_organization.value]
      }
    }
  }

  # AWS Account Logging - S3 Access
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSAccountLoggingS3"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "logging.s3.amazonaws.com"
        ]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
    }
  }

  # AWS Account Logging - ELB
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSAccountLoggingELB"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${local.aws_account-elb}:root"
        ]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
    }
  }

  # AWS Account Logging - Redshift
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSAccountLoggingRedshift1"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${local.aws_account-redshift}:root"
        ]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
    }
  }
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSAccountLoggingRedshift2"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${local.aws_account-redshift}:root"
        ]
      }
      actions = [
        "s3:GetBucketAcl"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}"
      ]
    }
  }

  # AWS Account Logging - CloudTrail
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSAccountLoggingCloudTrail1"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "cloudtrail.amazonaws.com"
        ]
      }
      actions = [
        "s3:GetBucketAcl"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}"
      ]
    }
  }
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSAccountLoggingCloudTrail2"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "cloudtrail.amazonaws.com"
        ]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }
  }

  # AWS Account Logging - AWS Config
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSAccountLoggingAWSConfig1"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "config.amazonaws.com"
        ]
      }
      actions = [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}"
      ]
    }
  }
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSAccountLoggingAWSConfig2"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "config.amazonaws.com"
        ]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }
  }

  # AWS Account Logging - AWSLogDeliveryACLCheck
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSLogDeliveryACLCheck"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "delivery.logs.amazonaws.com"
        ]
      }
      actions = [
        "s3:GetBucketAcl"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}"
      ]
    }
  }

  # AWS Account Logging - AWSLogDeliveryWrite
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "AWSLogDeliveryWrite"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "delivery.logs.amazonaws.com"
        ]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }
  }

  # AWS Billing Reports
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_billing_reports, false) ? [1] : []
    content {
      sid    = "AWSBillingReports"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "bcm-data-exports.amazonaws.com",
          "billingreports.amazonaws.com"
        ]
      }
      actions = [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}",
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
    }
  }

  # GuardDuty
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "GuardDuty1"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "guardduty.amazonaws.com"
        ]
      }
      actions = [
        "s3:GetBucketLocation"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}"
      ]
    }
  }
  dynamic "statement" {
    for_each = try(var.policy.use_for_aws_account_logging, false) ? [1] : []
    content {
      sid    = "GuardDuty2"
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = [
          "guardduty.amazonaws.com"
        ]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
    }
  }

  # Website
  dynamic "statement" {
    for_each = try(var.website.enabled, false) || try(var.public.enabled, false) ? [1] : []
    content {
      sid    = "PublicReadGetObject"
      effect = "Allow"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions = [
        "s3:GetObject"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*",
      ]
    }
  }
  provider = aws.this
}
