resource "aws_s3_bucket_logging" "this" {
  count  = try(var.logging.bucket_name, null) != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  target_bucket         = var.logging.bucket_name
  target_prefix         = try(var.logging.prefix, null) != null ? "${var.logging.prefix}/" : "s3/"
  expected_bucket_owner = try(var.logging.expected_bucket_owner, null)

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = try(var.logging.partition_date_source, "EventTime")
    }
  }


  provider = aws.this
}
