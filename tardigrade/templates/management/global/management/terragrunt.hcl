# Include all settings from the root terragrunt config
include "root" {
  path = find_in_parent_folders("terragrunt-root.hcl")
}

terraform {
  source = "../../../../..//roots/management"
}
