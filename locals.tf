# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  bucket_arn = aws_s3_bucket.this.arn

  object_lock_enabled = try(var.object_lock.enabled, false)
  website_enabled     = try(var.website.enabled, false)

  # Every statement the policy can contain, each switched on by an input. A policy is
  # created only when at least one statement is switched on.
  s3_bucket_policy_statements = concat(
    # Require Encrypted Transport
    [for s in [{
      Sid       = "RequireEncryptedTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [local.bucket_arn, "${local.bucket_arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }] : s if var.policy.require_encrypted_transport],

    # AWS Account Read Access (share)
    flatten([for account in var.policy.aws_account_read_access : [
      {
        Sid       = "AccountReadAccess1-${account}"
        Effect    = "Allow"
        Principal = { AWS = account }
        Action    = "s3:List*"
        Resource  = local.bucket_arn
      },
      {
        Sid       = "AccountReadAccess2-${account}"
        Effect    = "Allow"
        Principal = { AWS = account }
        Action    = "s3:Get*"
        Resource  = "${local.bucket_arn}/*"
      },
    ]]),

    # AWS Account Write Access (share)
    flatten([for account in var.policy.aws_account_write_access : [
      {
        Sid       = "AccountWriteAccess1-${account}"
        Effect    = "Allow"
        Principal = { AWS = account }
        Action    = ["s3:List*", "s3:GetBucketPolicy", "s3:PutBucketPolicy", "s3:GetBucketLocation"]
        Resource  = local.bucket_arn
      },
      {
        Sid       = "AccountWriteAccess2-${account}"
        Effect    = "Allow"
        Principal = { AWS = account }
        Action    = ["s3:*Object", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
        Resource  = "${local.bucket_arn}/*"
      },
    ]]),

    # AWS Organization Read Access (share)
    flatten([for org in var.policy.aws_organization_read_access : [
      {
        Sid       = "OrganizationReadAccess1-${org}"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:List*"
        Resource  = local.bucket_arn
        Condition = { StringEquals = { "aws:PrincipalOrgID" = org } }
      },
      {
        Sid       = "OrganizationReadAccess2-${org}"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:Get*"
        Resource  = "${local.bucket_arn}/*"
        Condition = { StringEquals = { "aws:PrincipalOrgID" = org } }
      },
    ]]),

    # AWS Organization Write Access (share)
    flatten([for org in var.policy.aws_organization_write_access : [
      {
        Sid       = "OrganizationWriteAccess1-${org}"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:List*", "s3:GetBucketPolicy", "s3:PutBucketPolicy", "s3:GetBucketLocation"]
        Resource  = local.bucket_arn
        Condition = { StringEquals = { "aws:PrincipalOrgID" = org } }
      },
      {
        Sid       = "OrganizationWriteAccess2-${org}"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:*Object", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
        Resource  = "${local.bucket_arn}/*"
        Condition = { StringEquals = { "aws:PrincipalOrgID" = org } }
      },
    ]]),

    # Public Read
    [for s in [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${local.bucket_arn}/*"
    }] : s if var.policy.public_read],

    # Statements from the caller's own policy documents
    flatten([for doc in var.policy.source_policy_documents : jsondecode(doc).Statement]),
  )

  # Decided from the inputs alone, so the count is known at plan time.
  create_s3_bucket_policy = anytrue([
    var.policy.require_encrypted_transport,
    var.policy.public_read,
    length(var.policy.aws_account_read_access) > 0,
    length(var.policy.aws_account_write_access) > 0,
    length(var.policy.aws_organization_read_access) > 0,
    length(var.policy.aws_organization_write_access) > 0,
    length(var.policy.source_policy_documents) > 0,
  ])
}
