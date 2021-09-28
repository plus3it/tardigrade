# Include all settings from the parent terragrunt config
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//roots/aws/management"
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = file(find_in_parent_folders("providers.management.tf"))
}
