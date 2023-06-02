module "buckets" {
  source   = "git::https://github.com/plus3it/terraform-aws-tardigrade-s3-bucket.git?ref=5.0.0"
  for_each = { for bucket in local.buckets : bucket.label => bucket }

  bucket = each.value.name
  policy = each.value.policy

  lifecycle_rules     = each.value.lifecycle_rules
  public_access_block = each.value.public_access_block
  tags                = each.value.tags
  versioning          = each.value.versioning
}

module "cloudtrail" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudtrail.git?ref=6.3.0"

  cloudtrail_name   = "${local.namespace}-cloudtrail"
  cloudtrail_bucket = module.buckets["cloudtrail"].bucket.id
  tags              = local.tags
}

module "config" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=3.0.2"

  config_bucket = module.buckets["config"].bucket.id
  tags          = local.tags
}

module "default_ebs_encryption" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-ebs-encryption.git?ref=2.0.0"
}

module "iam_account" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-account.git?ref=2.0.0"

  account_alias = local.namespace
  tags          = local.tags
}

module "saml_providers" {
  source   = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-identity-provider.git?ref=2.0.0"
  for_each = { for provider in var.saml_providers : provider.name => provider }

  saml_provider_name     = each.value.name
  saml_provider_metadata = each.value.metadata
}

module "securityhub" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-security-hub.git?ref=4.1.0"

  standard_subscription_arns = [
    "arn:${local.partition}:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
  ]
}

resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"
}
