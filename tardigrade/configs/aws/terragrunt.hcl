inputs = merge(
  yamldecode(file(find_in_parent_folders("globals.tfvars.yaml"))),
  {
    account_id = local.account_id
    region     = local.region
    partition  = local.partition
    role_name  = local.role_name
    tags       = local.tags
  },
)

locals {
  account_id     = split("/", path_relative_to_include())[0]
  partition      = basename(get_parent_terragrunt_dir())
  backend_region = get_env("AWS_DEFAULT_REGION")
  region         = get_env("AWS_DEFAULT_REGION")
  repo_name      = basename(abspath("${get_parent_terragrunt_dir()}/../../.."))
  role_name      = "OrganizationAccountAccessRole"

  tags = {
    RepoCloneUrl     = "https://github.com/plus3it/${local.repo_name}.git"
    RepoConsoleUrl   = "https://github.com/plus3it/${local.repo_name}"
    RepoName         = local.repo_name
    TfstateBucket    = "${local.repo_name}-ci-tfstate"
    TfstateLockTable = "${local.repo_name}-ci-tfstate-lock"
  }
}

remote_state {
  backend = "s3"

  config = {
    bucket         = "${local.repo_name}-tfstate"
    dynamodb_table = "${local.repo_name}-tfstate-lock"
    encrypt        = true
    key            = "tfstate/${path_relative_to_include()}/terraform.tfstate"
    region         = local.backend_region

    dynamodb_table_tags = local.tags
    s3_bucket_tags      = local.tags
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = file("${get_parent_terragrunt_dir()}/../versions.tf")
}

terraform {
  before_hook "terraform_lock" {
    commands = ["init"]
    execute  = ["rm", "-f", ".terraform.lock.hcl"]
  }

  after_hook "terraform_lock" {
    commands = get_terraform_commands_that_need_locking()
    execute  = ["rm", "-f", "${get_terragrunt_dir()}/.terraform.lock.hcl"]
  }
}
