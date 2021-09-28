# Include all settings from the parent terragrunt config
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../..//roots/aws/member"
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = file(find_in_parent_folders("providers.member.tf"))
}

dependency "management" {
  config_path = "../../{management_account_id}/management"
}

inputs = {
  cloudtrail_bucket = dependency.management.outputs.cloudtrail_bucket.id
  config_bucket     = dependency.management.outputs.config_bucket.id
}
