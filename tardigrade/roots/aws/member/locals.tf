locals {
  account_id            = data.aws_caller_identity.this.account_id
  account_id_management = data.aws_caller_identity.management.account_id
  partition             = data.aws_partition.this.partition
  guardduty_detector_id = data.aws_guardduty_detector.management.id

  account_name = lower(replace(var.account_name, "_", "-"))
  namespace    = lower(replace("${var.namespace}-${var.account_name}", "_", "-"))
  tags         = merge(var.tags, local.mandatory_tags)

  mandatory_tags = {
    TardigradeManaged = "true"
  }
}

data "aws_partition" "this" {}

data "aws_caller_identity" "this" {}

data "aws_caller_identity" "management" {
  provider = aws.management
}

data "aws_guardduty_detector" "management" {
  provider = aws.management
}
