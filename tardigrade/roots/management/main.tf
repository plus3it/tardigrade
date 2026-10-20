module "buckets" {
  source   = "../../vendor/.terraform/modules/s3_bucket"
  for_each = { for bucket in local.buckets : bucket.label => bucket }

  bucket = each.value.name
  policy = each.value.policy

  lifecycle_rules     = each.value.lifecycle_rules
  public_access_block = each.value.public_access_block
  versioning          = each.value.versioning
}

module "cloudtrail" {
  source = "../../vendor/.terraform/modules/cloudtrail"

  cloudtrail_name   = "${local.namespace}-cloudtrail"
  cloudtrail_bucket = module.buckets["cloudtrail"].bucket.id
}

module "config" {
  source = "../../vendor/.terraform/modules/config"

  config = {
    configuration_recorder = {
      name = "${local.namespace}-config"
    }
    delivery_channel = {
      s3_bucket_name = module.buckets["config"].bucket.id
    }
  }
}

module "default_ebs_encryption" {
  source = "../../vendor/.terraform/modules/ebs_encryption"
}

module "iam_account" {
  source = "../../vendor/.terraform/modules/iam_account"

  account_alias = {
    name = local.namespace
  }
}

module "saml_providers" {
  source   = "../../vendor/.terraform/modules/iam_identity_provider"
  for_each = { for provider in var.saml_providers : provider.name => provider }

  iam_identity_provider = {
    saml = {
      provider_name     = each.value.name
      metadata_document = each.value.metadata
    }
  }
}

module "securityhub" {
  source = "../../vendor/.terraform/modules/security_hub"

  security_hub = {
    standard_subscription_arns = [
      "arn:${local.partition}:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
    ]
  }
}

resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"
}
