---
title: "How-To Guide"
permalink: /how-to-guide/
toc: true
---

# Prerequisites

Tool versions are pinned in `.mise.toml`. Install [mise](https://mise.jdx.dev/) to ensure you're using the correct versions:

```bash
mise install
```

You'll also need AWS credentials configured through the standard AWS credential chain (AWS_PROFILE, environment variables, or CI OIDC).

# Authentication

Users have multiple options for authentication to deploy their resources, basically whatever the Terraform providers support. Generally, this falls into one of the following: login through a CLI tool, manage a config file, or use attributes in the provider config block. 

For AWS, see the [AWS provider authentication documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication). Common approaches include AWS SSO (recommended for production), IAM roles with OIDC (for CI/CD), or AWS CLI profiles.

# Quickstart: Deploy to a New Account

This quickstart assumes you're starting with the tardigrade template and want to deploy infrastructure to an AWS account.

1. **Create a new deployment repository** — See the [New Repository]({{ "/new-repository/" | relative_url }}) guide for detailed instructions, or follow the steps in [NEW_REPO.md](https://github.com/plus3it/tardigrade/blob/master/NEW_REPO.md).

2. **Add a stack** — Once you have a repository, add your first account (stack) by following the procedure in [stacks/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/stacks/AGENTS.md) under "Add a stack".

3. **Add units** — Add units (region + root combinations) for each region and baseline you want to deploy. See "Add a unit" in [stacks/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/stacks/AGENTS.md).

4. **Plan and apply** — From your unit directory, run:
  ```bash
  terragrunt plan
  ```
  Review the plan output, then apply:
  ```bash
  terragrunt apply
  ```

# Common Tasks

## Adding a Stack (New Scope)

A stack represents all infrastructure in a single scope (an AWS account, a GCP project, an Azure subscription, etc.). To add a new scope to your deployment, follow the procedure in [stacks/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/stacks/AGENTS.md) under "Add a stack".

## Adding a Unit (Region/Root)

Units are the deployment targets within an account. Each unit deploys one root module to one region. To add a new unit, follow "Add a unit" in [stacks/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/stacks/AGENTS.md).

## Changing the Baseline

The baseline infrastructure is defined in the root modules under `roots/`. To modify what gets deployed:

1. Edit the root module in `roots/<root>/` (e.g., `roots/member/` or `roots/management/`)
2. Add or remove module calls, update variables, or adjust resources
3. Run `terragrunt plan` in an affected unit to preview changes
4. Run `terragrunt apply` to deploy the changes

For adding new external modules to vendor, see [vendor/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/vendor/AGENTS.md).

## Things That Move State (Be Careful!)

The following actions modify Terraform state and require a human-approved migration plan:

- Renaming or moving a unit path (changes the state key)
- Moving `terragrunt-root.hcl` to a different depth (changes path parsing)
- Changing the state `key` or `TfstateKey` expression
- Running `terraform state` subcommands (`mv`, `rm`, `push`, `pull`)
- Running `terraform import` or `terraform destroy`

Never let an AI agent run `apply`, `destroy`, `import`, or `state` commands without human review. These should always be prepared by an agent for a person to execute.

For more safety guidelines, see the "Safety rules" section in [AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/AGENTS.md).
