# Templates: New Stack Starter Configurations

This file describes the template conventions used when onboarding new stacks. In the AWS account-baseline example, a stack is an AWS account.

## What are Templates

Templates provide starter configurations for creating new stacks (scopes). They live in `tardigrade/templates/<type>/` and are copied to `tardigrade/stacks/<partition>/<scope_id>/` when onboarding a stack. For AWS, this means copying to `tardigrade/stacks/<partition>/<account_id>/`.

## Template Structure

Each template type has:

```
tardigrade/templates/<type>/
├── account.tfvars.yaml          # Account-level YAML configuration
├── global/
│   └── <root>/
│       ├── terragrunt.hcl       # Terragrunt configuration for the global unit
│       └── terraform.tfvars     # Terraform variable overrides (optional)
└── regional/
    └── <root>/
        ├── terragrunt.hcl       # Terragrunt configuration for regional units
        └── terraform.tfvars     # Terraform variable overrides (optional)
```

### Template Types

In the AWS example, common template types:

- `management`: For organization management accounts (deploys CloudTrail/Config aggregation, billing resources)
- `member`: For member accounts (sends data to management account's CloudTrail/Config)

Add custom types for specialized roles (e.g., `security`, `network`, `logging`).

## Global vs. Regional

Roots that deploy both global and regional resources use `count` or conditional `for_each` to gate global-only resources: `count = local.is_global ? 1 : 0`, where `is_global = var.region == var.global_region`. Global-only resources (IAM account alias, CloudTrail multi-region trail, IAM identity providers) are created only when the unit is in the global region. Regional resources (AWS Config, GuardDuty detectors, Security Hub, EBS encryption) are created in every region.

- **Global units** (`global/<root>/`) are deployed to the partition's primary region (e.g., `us-east-1` for `aws`, `us-gov-west-1` for `aws-us-gov`). They create both global-only resources and regional resources. In GCP deployments, these may live in a `_global/` directory.

- **Regional units** (`regional/<root>/`) are deployed to other regions. They create only regional resources because `local.is_global` evaluates to false, skipping global-only modules.

Regional units typically depend on the global unit for the same root for ordering only (using `skip_outputs = true`).

For the AWS example: member stacks depend on the management stack. The management stack must be applied first so member units can reference its outputs (CloudTrail and Config bucket names). The member templates include `mock_outputs` limited to `validate`: with backend credentials, `terragrunt validate` works on a member unit before the management stack is applied. Without credentials, check unit configuration with `terragrunt hcl validate` and roots with `make terraform/validate-roots`; `plan` never uses the mocks.

## Placeholders

Templates use placeholders in file contents (not in directory names). When running `make init/repo`, these placeholders are substituted. Note: these placeholders are specific to the AWS account-baseline example.

- `{{repo_name}}` — Repository name (e.g., `acme-tardigrade`)
- `{{repo_url}}` — Web URL of the repository (e.g., `https://github.com/acme/acme-tardigrade`)
- `{{global_region}}` — Primary region for the partition (e.g., `us-east-1`)
- `{{management_account_id}}` — AWS account ID of the management account (AWS-specific)
- `{{backend_role_name}}` — IAM role name used for S3 backend access (AWS-specific, e.g., `TerraformStateRole`)

When creating a new stack, replace any remaining placeholders manually. Common placeholders to replace in the AWS example:

- Account IDs in dependency paths (e.g., `{{management_account_id}}` in a member unit's dependency on the management account)
- Region names in cross-region dependencies
- Resource names or identifiers specific to the scope

## Template Conventions

### 1. account.tfvars.yaml (or scope-level YAML)

This file contains scope-specific configuration merged into all units in the scope. In the AWS example (`account.tfvars.yaml`), at minimum it should have:

```yaml
# Name of the account -- lowercase letters, numbers, and hyphens only
account_name:

# Email address of the root account
email_address:
```

For other providers, the scope-level settings file and its contents differ, and the root Terragrunt config must load whatever file you use (for example, a GCP deployment might use a `project.hcl` file).

Add other scope-level variables as needed (e.g., `subnet_cidrs`, `vpc_id`).

### 2. terragrunt.hcl

Each unit template includes a `terragrunt.hcl` that:

```hcl
# Include all settings from the root terragrunt config
include "root" {
  path = find_in_parent_folders("terragrunt-root.hcl")
}

terraform {
  source = "../../../../..//roots/<root>"  # Adjust path depth based on global vs regional
}

# Dependencies on other units (optional)
dependency "<name>" {
  config_path = "<relative-path-to-unit>"
}

# Unit-specific inputs (optional)
inputs = {
  # key = value
}
```

Units are typically at `<partition>/<scope_id>/<region>/<root>`, which is five levels below `tardigrade/`, so the source path has five `..` segments to reach `tardigrade/roots/<root>/`.

Dependencies use relative paths. In the AWS example, for a member account's global unit depending on the management account's global unit:

```hcl
dependency "management" {
  config_path = "../../../{{management_account_id}}/{{global_region}}/management"
}
```

The `{{management_account_id}}` placeholder must be replaced when creating a new stack.

### 3. terraform.tfvars

This file is optional. Use it to override specific Terraform variable values for a unit without affecting the YAML-based configuration. Most inputs come from the merged YAML files and computed values.

## Creating a Template for a New Root

When adding a new root module:

1. Create the global template:

    ```bash
    mkdir -p tardigrade/templates/<type>/global/<root>
    ```

2. Create `terragrunt.hcl`:

    ```hcl
    include "root" {
        path = find_in_parent_folders("terragrunt-root.hcl")
    }

    terraform {
        source = "../../../../..//roots/<root>"
    }
    ```

3. Add dependencies if the root needs outputs from other units.

4. If the root deploys regional resources, create the regional template:

    ```bash
    mkdir -p tardigrade/templates/<type>/regional/<root>
    ```

5. Create the regional `terragrunt.hcl` with a dependency on the global unit:

    ```hcl
    include "root" {
        path = find_in_parent_folders("terragrunt-root.hcl")
    }

    terraform {
        source = "../../../../..//roots/<root>"
    }

    dependency "<root>_global" {
        config_path  = "../../{{global_region}}/<root>"
        skip_outputs = true
    }
    ```

## Regional Unit Dependencies

Regional units for the same root typically depend on the global unit. The dependency path is:

```hcl
dependency "<root>_global" {
  config_path  = "../../{{global_region}}/<root>"
  skip_outputs = true
}
```

`skip_outputs = true` makes it an ordering dependency only: the global unit is applied first, and its outputs aren't read. This assumes the regional unit is at `<scope_id>/<region>/<root>` and the global unit is at `<scope_id>/<global_region>/<root>`.

After substituting `{{global_region}}` via `make init/repo`, the path becomes concrete (e.g., `../../us-east-1/<root>`).
