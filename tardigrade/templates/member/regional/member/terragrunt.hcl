# Include all settings from the root terragrunt config
include "root" {
  path = find_in_parent_folders("terragrunt-root.hcl")
}

terraform {
  source = "../../../../..//roots/member"
}

# Depend on the global region unit of the same root
dependency "global_region" {
  config_path  = "../../{{global_region}}/member"
  skip_outputs = true
}

dependency "management" {
  config_path = "../../../{{management_account_id}}/{{global_region}}/management"
}

inputs = {
  cloudtrail_bucket = dependency.management.outputs.cloudtrail_bucket.id
  config_bucket     = dependency.management.outputs.config_bucket.id
}
