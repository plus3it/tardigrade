# Include all settings from the parent terragrunt config
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//roots/aws/management"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file(find_in_parent_folders("provider.management.tf"))
}
