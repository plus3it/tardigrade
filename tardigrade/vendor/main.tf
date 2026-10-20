# This file contains *only* module references where the source is an external module.
# Run `terraform init` in this directory to vendor those external modules to the
# local filesystem. Other modules in this project will use a source value that
# points to the vendored location, e.g. `<relative path>/vendor/.terraform/modules/<module_label>`.

# Please keep the module labels in alphabetical order.

module "cloudtrail" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudtrail.git?ref=6.3.0"

  cloudtrail_name   = null
  cloudtrail_bucket = null
}

module "config" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=4.2.1"
}

module "ebs_encryption" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-ebs-encryption.git?ref=2.0.0"
}

module "guardduty" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-guardduty.git?ref=3.1.1"
}

module "iam_account" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-account.git?ref=3.0.0"
}

module "iam_identity_provider" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-identity-provider.git?ref=3.0.0"

  iam_identity_provider = null
}

module "s3_bucket" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-s3-bucket.git?ref=5.1.0"
}

module "security_hub" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-security-hub.git?ref=5.0.0"
}

module "security_hub_member" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-security-hub.git//modules/cross-account-member?ref=5.0.0"

  providers = {
    aws               = aws
    aws.administrator = aws
  }
}
