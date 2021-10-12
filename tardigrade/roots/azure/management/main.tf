module "resource_group" {
  source = "../../../templates/modules/terraform_azurerm_resource_group"
  for_each = { for resource_group in local.resource_groups : resource_group.label => resource_group }
  location = each.value.location
  resource_group = each.value.name
  tags = each.value.tags
}

module "storage_account" {
  source = "../../../templates/modules/terraform_azurerm_storage_account"
  for_each = { for storage_account in local.storage_accounts : storage_account.label => storage_account }

  storage_account = substr(replace(each.value.name, "-", ""),0,24)
  resource_group = module.resource_group["core-mgmt-rg"].rg_name
  resource_group_location = module.resource_group["core-mgmt-rg"].rg_location
  tags = each.value.tags

}
/*
module "buckets" {
  source   = "git::https://github.com/plus3it/terraform-aws-tardigrade-s3-bucket.git?ref=4.3.1"
  for_each = { for bucket in local.buckets : bucket.label => bucket }

  bucket = each.value.name
  policy = each.value.policy

  lifecycle_rules     = each.value.lifecycle_rules
  public_access_block = each.value.public_access_block
  tags                = each.value.tags
  versioning          = each.value.versioning
}

module "cloudtrail" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudtrail.git?ref=6.0.0"

  cloudtrail_name   = "${local.namespace}-cloudtrail"
  cloudtrail_bucket = module.buckets["cloudtrail"].bucket.id
  tags              = local.tags
}

module "config" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=3.0.1"

  config_bucket = module.buckets["config"].bucket.id
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

module "saml_providers" {
  source   = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-identity-provider.git?ref=2.0.0"
  for_each = { for provider in var.saml_providers : provider.name => provider }

  saml_provider_name     = each.value.name
  saml_provider_metadata = each.value.metadata
}

module "securityhub" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-security-hub.git?ref=2.0.1"

  standard_subscription_arns = [
    "arn:${local.partition}:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
  ]
}

resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"
}
*/