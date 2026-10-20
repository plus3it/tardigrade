# Modules: Local Reusable Modules

This file describes when and how to create local modules in tardigrade.

## When to Use a Local Module

Create a local module in `tardigrade/modules/<name>/` when:

1. The logic is specific to this deployment and not reusable across other organizations
2. You need a quick prototype before extracting it to a public `terraform-aws-tardigrade-*` module
3. The module wraps or combines vendor modules in a deployment-specific way

For general-purpose AWS resource management that could benefit other users, create a public `plus3it/terraform-aws-tardigrade-*` module instead and vendor it via `tardigrade/vendor/main.tf`.

## Local Module Structure

A local module has the same structure as any Terraform module:

```
tardigrade/modules/<name>/
├── main.tf          # Resources and module calls
├── variables.tf     # Input variables
├── outputs.tf       # Outputs
├── versions.tf      # Terraform and provider version constraints
└── README.md        # Documentation (optional)
```

## Add a Local Module

### 1. Create the Module Directory

```bash
mkdir -p tardigrade/modules/<name>
```

### 2. Write Module Files

Create `main.tf`, `variables.tf`, and `outputs.tf` with the module logic.

If the module uses AWS providers, create `versions.tf` with minimum version constraints:

```hcl
terraform {
  required_version = ">= 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

Match the Terraform version constraint to the version in `.mise.toml`. Local modules declare only minimum version constraints (`>=`); exact terraform and provider pins live in `tardigrade/vendor/versions.tf`.

### 3. Reference from Roots

Use a relative path from the root to the module:

```hcl
module "local_example" {
  source = "../../modules/<name>"
  
  # inputs
}
```

### 4. Validate

```bash
terraform -chdir=tardigrade/modules/<name> init -backend=false
terraform -chdir=tardigrade/modules/<name> validate
```

## When to Extract to a Reusable Module

If a local module proves useful and could benefit other tardigrade deployments:

1. Create a new `terraform-<provider>-<name>` repository from repo-template (public on GitHub, or private on GitHub/GitLab)
2. Move the module code to the new repository
3. Add the module to `tardigrade/vendor/main.tf` (regardless of whether it's public or private)
4. Update roots to reference the vendored module path
5. Delete the local module

Reusable modules in separate repositories have better visibility, testing (via mockstack), and version management than local modules.
