locals {
  create_s3_bucket_policy = try(var.policy.require_encrypted_transport, true) || try(length(var.policy.aws_account_read_access), 0) > 0 || try(var.policy.use_for_aws_account_logging, false) || try(var.website.enabled, false) ? true : false

  aws_account-elb      = local.aws_account_lookup.elb["${data.aws_region.this.name}"]
  aws_account-redshift = local.aws_account_lookup.redshift["${data.aws_region.this.name}"]

  aws_account_lookup = {
    elb = {
      af-south-1     = "098369216593"
      ap-east-1      = "754344448648"
      ap-northeast-1 = "582318560864"
      ap-northeast-2 = "600734575887"
      ap-northeast-3 = "383597477331"
      ap-south-1     = "718504428378"
      ap-southeast-1 = "114774131450"
      ap-southeast-2 = "783225319266"
      ca-central-1   = "985666609251"
      cn-north-1     = "638102146993"
      cn-northwest-1 = "037604701340"
      eu-central-1   = "054676820928"
      eu-north-1     = "897822967062"
      eu-south-1     = "635631232127"
      eu-west-1      = "156460612806"
      eu-west-2      = "652711504416"
      eu-west-3      = "009996457667"
      me-south-1     = "076674570225"
      sa-east-1      = "507241528517"
      us-east-1      = "127311923021"
      us-east-2      = "033677994240"
      us-gov-east-1  = "190560391635"
      us-gov-west-1  = "048591011584"
      us-west-1      = "027434742980"
      us-west-2      = "797873946194"
    }
    redshift = {
      af-south-1     = "365689465814"
      ap-east-1      = "313564881002"
      ap-northeast-1 = "404641285394"
      ap-northeast-2 = "760740231472"
      ap-northeast-3 = "090321488786"
      ap-south-1     = "865932855811"
      ap-southeast-1 = "361669875840"
      ap-southeast-2 = "762762565011"
      ca-central-1   = "907379612154"
      eu-central-1   = "053454850223"
      eu-north-1     = "729911121831"
      eu-south-1     = "945612479654"
      eu-west-1      = "210876761215"
      eu-west-2      = "307160386991"
      eu-west-3      = "915173422425"
      me-south-1     = "013126148197"
      sa-east-1      = "075028567923"
      us-east-1      = "193672423079"
      us-east-2      = "391106570357"
      us-west-1      = "262260360010"
      us-west-2      = "902366379725"
    }
  }
}
