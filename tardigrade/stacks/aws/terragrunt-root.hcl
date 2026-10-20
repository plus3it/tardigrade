remote_state {
  backend = "s3"

  config = {
    assume_role = local.session_name != null ? {
      role_arn     = "arn:${local.partition}:iam::{{management_account_id}}:role/{{backend_role_name}}"
      session_name = local.session_name
      } : {
      role_arn = "arn:${local.partition}:iam::{{management_account_id}}:role/{{backend_role_name}}"
    }

    bucket         = local.backend_bucket
    dynamodb_table = local.backend_lock_table
    encrypt        = true
    key            = "tfstate/${path_relative_to_include()}/terraform.tfstate"
    region         = local.global_region

    dynamodb_table_tags = local.tags
    s3_bucket_tags      = local.tags
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = file("${get_parent_terragrunt_dir()}/providers.tf")
}

terraform {
  include_in_copy = [
    "vendor/.terraform"
  ]

  after_hook "terraform_lock" {
    commands = concat(get_terraform_commands_that_need_locking(), ["init"])
    execute  = ["rm", "-f", "${get_terragrunt_dir()}/.terraform.lock.hcl"]
  }
}

generate "terraform_lock" {
  path      = ".terraform.lock.hcl"
  if_exists = "overwrite"
  contents  = file("${get_parent_terragrunt_dir()}/../../vendor/.terraform.lock.hcl")
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = file("${get_parent_terragrunt_dir()}/../../vendor/versions.tf")
}

locals {
  stack_dependency_globs  = try(yamldecode(file("${get_original_terragrunt_dir()}/.tardigrade.config.yaml")).dependency_globs, [])
  source_name             = basename(get_original_terragrunt_dir())
  source_dependency_globs = try(yamldecode(file("${get_repo_root()}/tardigrade/roots/${local.source_name}/.tardigrade.config.yaml")).dependency_globs, [])
  read_dependencies       = [for dependency_glob in distinct(concat(local.source_dependency_globs, local.stack_dependency_globs)) : mark_glob_as_read("${get_repo_root()}/tardigrade/${dependency_glob}")]

  session_name  = can(get_env("AWS_ROLE_SESSION_NAME")) ? get_env("AWS_ROLE_SESSION_NAME") : null
  global_region = "{{global_region}}"

  # Parse path_relative_to_include() to extract: account_id, region, root
  # Path format: <account_id>/<region>/<root>
  path_parts = split("/", path_relative_to_include())
  account_id = local.path_parts[0]
  region     = local.path_parts[1]

  # Partition is derived from the parent directory name
  partition = basename(get_parent_terragrunt_dir())

  # Backend bucket and lock table names
  backend_bucket     = "{{repo_name}}-tfstate"
  backend_lock_table = "{{repo_name}}-tfstate-lock"

  tags = {
    RepoCloneUrl     = "{{repo_url}}.git"
    RepoConsoleUrl   = "{{repo_url}}"
    RepoName         = "{{repo_name}}"
    TfstateBucket    = local.backend_bucket
    TfstateKey       = "tfstate/${path_relative_to_include()}/terraform.tfstate"
    TfstateLockTable = local.backend_lock_table
  }

  global_vars = yamldecode(file(find_in_parent_folders("globals.tfvars.yaml")))

  account_vars = yamldecode(file(find_in_parent_folders("account.tfvars.yaml")))

  # Try to load root-specific tfvars.yaml if it exists (e.g., management.tfvars.yaml)
  root_name = basename(get_terragrunt_dir())
  root_vars = fileexists("${get_parent_terragrunt_dir()}/${local.root_name}.tfvars.yaml") ? yamldecode(file("${get_parent_terragrunt_dir()}/${local.root_name}.tfvars.yaml")) : {}
}

inputs = merge(
  local.global_vars,
  local.root_vars,
  local.account_vars,
  {
    account_id   = local.account_id
    region       = local.region
    partition    = local.partition
    session_name = local.session_name
    default_tags = local.tags
  },
)
