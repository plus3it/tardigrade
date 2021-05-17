module "cloudtrail" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudtrail.git?ref=6.0.0"

  cloudtrail_name   = "${local.namespace}-cloudtrail"
  cloudtrail_bucket = var.cloudtrail_bucket
  tags              = local.tags
}

module "config" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=3.0.0"

  config_bucket = var.config_bucket
  tags          = local.tags
}

module "default_ebs_encryption" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-ebs-encryption.git?ref=1.0.1"
}

module "iam_account" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-account.git?ref=2.0.0"

  account_alias = local.namespace
  tags          = local.tags
}

module "guardduty" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-guardduty.git?ref=2.0.1"

  providers = {
    aws        = aws
    aws.master = aws.management
  }

  email_address                = var.email_address
  guardduty_master_detector_id = local.guardduty_detector_id
}

module "securityhub" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-security-hub.git//modules/cross-account-member?ref=2.0.0"

  providers = {
    aws               = aws
    aws.administrator = aws.management
  }

  member_email = var.email_address

  standard_subscription_arns = [
    "arn:${local.partition}:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
  ]
}
