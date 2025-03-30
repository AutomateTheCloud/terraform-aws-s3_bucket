resource "aws_s3_bucket_acl" "this" {
  count  = try(var.policy.use_for_aws_account_logging, false) ? 1 : 0
  bucket = aws_s3_bucket.this.id

  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.this.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "READ_ACP"
    }

    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "WRITE"
    }

    owner {
      id = data.aws_canonical_user_id.this.id
    }
  }

  depends_on = [aws_s3_bucket_ownership_controls.this]

  provider = aws.this
}
