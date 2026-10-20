# Templates: New Account Starter Configurations

This file describes the template conventions used when onboarding new AWS accounts.

## What are Templates

Templates provide starter configurations for creating new stacks (accounts). They live in `tardigrade/templates/<type>/` and are copied to `tardigrade/stacks/<partition>/<account_id>/` when onboarding an account.

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

Common template types:

- `management`: For organization management accounts (deploys CloudTrail/Config aggregation, billing resources)
- `member`: For member accounts (sends data to management account's CloudTrail/Config)

Add custom types for specialized account roles (e.g., `security`, `network`, `logging`).

## Global vs. Regional

- **Global units** (`global/<root>/`) deploy resources that exist once per account, typically in the partition's primary region (e.g., `us-east-1` for `aws`, `us-gov-west-1` for `aws-us-gov`). Examples: IAM roles, S3 buckets for central logging.

- **Regional units** (`regional/<root>/`) deploy resources that exist in multiple regions. Examples: GuardDuty detectors, Config recorders, VPCs.

Regional units typically depend on the global unit for the same root to reference outputs like S3 bucket names.

## Placeholders

Templates use placeholders in file contents (not in directory names). When running `make init/repo`, these placeholders are substituted:

- `{{repo_name}}` — Repository name (e.g., `acme-tardigrade`)
- `{{repo_url}}` — Web URL of the repository (e.g., `https://github.com/acme/acme-tardigrade`)
- `{{global_region}}` — Primary region for the partition (e.g., `us-east-1`)
- `{{management_account_id}}` — AWS account ID of the management account
- `{{backend_role_name}}` — IAM role name used for S3 backend access (e.g., `TerraformStateRole`)

When creating a new stack, replace any remaining placeholders manually. Common placeholders to replace:

- Account IDs in dependency paths (e.g., `{{management_account_id}}` in a member unit's dependency on the management account)
- Region names in cross-region dependencies
- Resource names or identifiers specific to the account

## Template Conventions

### 1. account.tfvars.yaml

This file contains account-specific configuration merged into all units in the account. At minimum, it should have:

```yaml
# Name of the account -- lowercase letters, numbers, and hyphens only
account_name:

# Email address of the root account
email_address:
```

Add other account-level variables as needed (e.g., `subnet_cidrs`, `vpc_id`).

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

Global units are typically 6 levels deep (`<partition>/<account>/<region>/<root>`), so the source path has six `..` segments to reach the repository root. Regional units have the same depth.

Dependencies use relative paths. For a member account's global unit depending on the management account's global unit:

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
        config_path = "../../{{global_region}}/<root>"
    }
    ```

## Regional Unit Dependencies

Regional units for the same root typically depend on the global unit. The dependency path is:

```hcl
dependency "<root>_global" {
  config_path = "../../{{global_region}}/<root>"
}
```

This assumes the regional unit is at `<account>/<region>/<root>` and the global unit is at `<account>/<global_region>/<root>`.

After substituting `{{global_region}}` via `make init/repo`, the path becomes concrete (e.g., `../../us-east-1/<root>`).
