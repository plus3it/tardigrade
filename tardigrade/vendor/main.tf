# This file contains *only* module references where the source is an external module.
# Run `terraform init` in this directory to vendor those external modules to the
# local filesystem. Other modules in this project will use a source value that
# points to the vendored location, e.g. `<relative path>/vendor/.terraform/modules/<module_label>.this`.

# Please keep the module labels in alphabetical order.

module "cloudtrail" {
  source = "./cloudtrail"
}

module "config" {
  source = "./config"
}

module "ebs_encryption" {
  source = "./ebs_encryption"
}

module "guardduty" {
  source = "./guardduty"
}

module "iam_account" {
  source = "./iam_account"
}

module "iam_identity_provider" {
  source = "./iam_identity_provider"
}

module "s3_bucket" {
  source = "./s3_bucket"
}

module "security_hub" {
  source = "./security_hub"
}

module "security_hub_member" {
  source = "./security_hub_member"
}
