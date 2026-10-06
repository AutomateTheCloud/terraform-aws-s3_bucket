# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A log bucket and a bucket that logs to it, created in the same run. The log
# bucket's name is not known until apply.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
variable "suffix" {
  type    = string
  default = "test"
}

resource "random_id" "this" {
  byte_length = 4
}

module "logs" {
  source = "../../.."

  details = { scope = "Test", purpose = "Logs", environment = "test" }
  name    = "logs-${var.suffix}-${random_id.this.hex}"
}

module "data" {
  source = "../../.."

  details = { scope = "Test", purpose = "Data", environment = "test" }
  name    = "data-${var.suffix}"
  logging = { bucket_name = module.logs.metadata.s3_bucket.id }
}
