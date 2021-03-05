# Include all settings from the root terraform.tfvars file
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../..//roots/aws/member"

  after_hook "provider" {
    commands = ["init-from-module"]
    execute  = ["cp", "${get_terragrunt_dir()}/../../tenant.tf", "."]
  }

  extra_arguments "config" {
    commands = get_terraform_commands_that_need_vars()

    required_var_files = [
      "${get_terragrunt_dir()}/tenant-local.auto.tfvars",
    ]
  }
}

inputs = yamldecode(file("${get_terragrunt_dir()}/../../tenant-global.tfvars.yaml"))
