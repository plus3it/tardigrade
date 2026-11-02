# Include all settings from the root terragrunt config
include "root" {
  path = find_in_parent_folders("terragrunt-root.hcl")
}

terraform {
  source = "../../../../..//roots/member"
}

dependency "management" {
  config_path = "../../../{{management_account_id}}/{{global_region}}/management"

  mock_outputs_allowed_terraform_commands = ["validate"]
  mock_outputs = {
    cloudtrail_bucket = {
      id = "mock-cloudtrail-bucket"
    }
    config_bucket = {
      id = "mock-config-bucket"
    }
  }
}

inputs = {
  cloudtrail_bucket = dependency.management.outputs.cloudtrail_bucket.id
  config_bucket     = dependency.management.outputs.config_bucket.id
}
