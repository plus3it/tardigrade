module "cloudtrail" {
  source = "../../vendor/.terraform/modules/cloudtrail.this"
  count  = local.is_global ? 1 : 0

  cloudtrail_name   = "${local.namespace}-cloudtrail"
  cloudtrail_bucket = var.cloudtrail_bucket
}

module "config" {
  source = "../../vendor/.terraform/modules/config.this"

  config = {
    configuration_recorder = {
      name = "${local.namespace}-config"
    }
    delivery_channel = {
      s3_bucket_name = var.config_bucket
    }
  }
}

module "default_ebs_encryption" {
  source = "../../vendor/.terraform/modules/ebs_encryption.this"
}

module "iam_account" {
  source = "../../vendor/.terraform/modules/iam_account.this"
  count  = local.is_global ? 1 : 0

  account_alias = {
    name = local.namespace
  }
}

module "guardduty" {
  source = "../../vendor/.terraform/modules/guardduty.this/modules/member"

  providers = {
    aws               = aws
    aws.administrator = aws.management
  }

  member = {
    email                      = var.email_address
    invitation_message         = "Please accept GuardDuty invitation"
    disable_email_notification = false
  }
}

module "securityhub" {
  source = "../../vendor/.terraform/modules/security_hub_member.this/modules/cross-account-member"

  providers = {
    aws               = aws
    aws.administrator = aws.management
  }

  security_hub = {
    member_email = var.email_address
    standard_subscription_arns = [
      "arn:${local.partition}:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
    ]
  }
}
