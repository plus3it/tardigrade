---
title: "Structure"
permalink: /structure/
toc: true
---

# File Structure

```
tardigrade/
├── vendor/                             # External module vendoring
│   ├── main.tf                         # References to vendor subdirectories (alphabetical)
│   ├── versions.tf                     # Terraform and provider version pins
│   ├── .terraform.lock.hcl             # Provider lock file for multiple platforms
│   └── <label>/                        # One directory per external module
│       └── main.tf                     # module "this" { source = "..." }
├── modules/<name>/                     # Local reusable modules
├── roots/<root>/                       # Terraform root modules (not tied to a partition)
│   ├── .tardigrade.config.yaml         # Dependency globs for change detection
│   ├── management/                     # Management account root
│   └── member/                         # Member account root
├── templates/<type>/                   # Terragrunt unit templates for new accounts
│   ├── management/
│   │   ├── account.tfvars.yaml
│   │   └── global/<root>/              # Units for the global region
│   │       ├── terragrunt.hcl
│   │       └── terraform.tfvars
│   └── member/
│       ├── account.tfvars.yaml
│       ├── global/<root>/              # Units for the global region
│       └── regional/<root>/            # Units for non-global regions
└── stacks/<partition>/                 # Deployed units (one state file per unit)
    ├── terragrunt-root.hcl             # Root Terragrunt config for all units
    ├── providers.tf                    # Provider configuration template
    ├── globals.tfvars.yaml             # Partition-level variables
    ├── <root>.tfvars.yaml              # Root-specific variables (optional)
    └── <scope_id>/                     # Scope directories (stacks); in the AWS example: account_id
        ├── account.tfvars.yaml         # Scope-level variables (account.tfvars.yaml in the AWS example)
        └── <region>/<root>/            # Units: terragrunt.hcl + terraform.tfvars
```

## Using Another Provider or Deployment Type

The template ships an AWS account-baseline example, but tardigrade works with any Terraform provider. Here's what changes and what stays the same:

### What Changes

- **Partition directory name**: Reflects the cloud or partition. Examples: `aws`, `aws-us-gov`, `gcp`, `azure`.
- **Backend and provider configuration**: `stacks/<partition>/terragrunt-root.hcl` and `providers.tf` hold the backend and provider for that cloud. For example, a GCP deployment uses a GCS backend instead of S3.
- **Scope ID**: The scope directory is named with whatever that provider uses. An AWS account uses a 12-digit account ID; a GCP project uses the project ID string; an Azure subscription uses a subscription ID.
- **Non-regional units**: Units that aren't regional can live in a `_global/` directory instead of a named region directory.
- **Terraform root location**: A deployment of a single application may keep its Terraform root inside the unit (a `terraform/` directory) instead of in `roots/` when the root is not reused across scopes.

### What Stays Fixed

The following conventions remain the same regardless of provider:

- One root Terragrunt config per partition directory, included by every unit (the template names it `stacks/<partition>/terragrunt-root.hcl`)
- Scope ID and region derived from the path via `path_relative_to_include()`
- State key derived from `path_relative_to_include()` (format: `tfstate/<path>`)
- External modules are pinned to a version (the template vendors them in `vendor/`)
- The safety rules (no `apply`/`destroy`/`import`/`state` without human approval)

### AWS-Specific Features

The template's `make init/repo` target and template files currently target AWS. When adapting for another provider:

- Manually edit `stacks/<partition>/terragrunt-root.hcl` and `providers.tf` for the new cloud
- Replace `account.tfvars.yaml` with whatever scope-level settings the provider needs, and update the root Terragrunt config that loads it (the template loads `account.tfvars.yaml` by name; a GCP deployment might keep its project settings in a `project.hcl` file instead)
- Update or remove AWS-specific variables like `management_account_id`

## Glossary

- **Unit**: A directory containing `terragrunt.hcl`. One unit has one state file. Path: `stacks/<partition>/<scope_id>/<region>/<root>/`
- **Stack**: A scope directory and all its units: `stacks/<partition>/<scope_id>/`. The scope is whatever the provider deploys into: an AWS account, a GCP project, an Azure subscription, and so on. "Add a stack" means onboarding a new scope (for AWS, an account). Note: this is NOT a `terragrunt.stack.hcl` file or a Spacelift stack. A deployment may also use terragrunt.stack.hcl files; when it does, say "Terragrunt stack file" for those.
- **Root**: A Terraform root module in `roots/<root>/`, deployed by units.
- **Module**: A local reusable module in `modules/<name>/`.
- **External module**: A reusable module from any external source (public or private git repositories, public or private Terraform registries). Plus3 IT public modules use the `plus3it/terraform-aws-tardigrade-*` naming convention and are created from the [repo-template](https://github.com/plus3it/repo-template).
- **Vendor**: One subdirectory per external module. `vendor/<label>/main.tf` holds a single `module "this"` with the pinned source; `vendor/main.tf` only lists references to these directories. Roots use `vendor/.terraform/modules/<label>.this`.
- **Dependency globs**: Each root's `.tardigrade.config.yaml` lists globs (`vendor/<label>/**`, `modules/<name>/**`) for its dependencies. Change detection uses these to determine which units need replanning.
- **Partition**: The cloud or partition directory (e.g., `aws`, `aws-us-gov`, `gcp`). In the AWS example: an AWS partition (`aws` for commercial, `aws-us-gov` for GovCloud, `aws-cn` for China).

## Layer Details

### vendor/

The `vendor/` directory pins external Terraform modules and providers. Each external module gets its own subdirectory with a `main.tf` file containing `module "this" { source = "..." }`. The root `vendor/main.tf` only lists references to these subdirectories (alphabetical order).

Run `make terraform/vendor` to download modules to `vendor/.terraform/modules/`. Roots reference them via paths like `../../vendor/.terraform/modules/<label>.this`.

This structure enables granular change detection: only units whose roots list `vendor/<label>/**` in their dependency globs are affected when that module changes.

For procedures on adding external modules, see [vendor/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/vendor/AGENTS.md).

### modules/

Local reusable modules that are specific to this deployment. For guidelines on creating modules, see the [create-a-module]({{ "/create-a-module/" | relative_url }}) guide.

### roots/

Terraform root modules that define what gets deployed. Roots are not tied to a specific partition. Each root module typically combines multiple vendor and local modules into a deployable baseline.

Roots do not have a `providers.tf` file because providers are generated by Terragrunt. To validate all roots, run `make terraform/validate-roots`, which temporarily copies the provider configuration into each root, runs `terraform init -backend=false` and `terraform validate`, then cleans up.

For procedures on adding roots, see [roots/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/roots/AGENTS.md).

### templates/

Template files for creating new units (scope + region combinations). Templates are organized by type (management, member in the AWS example). The `global/` subdirectory contains units for the global region; `regional/` contains units for other regions.

When creating a new stack, copy the appropriate template directory into `stacks/<partition>/<scope_id>/`.

For template conventions, see [templates/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/templates/AGENTS.md).

### stacks/

Deployed units organized by partition, scope, and region. Each unit directory contains `terragrunt.hcl` and `terraform.tfvars`.

#### terragrunt-root.hcl Behavior

The `stacks/<partition>/terragrunt-root.hcl` file provides common configuration for all units in the partition:

**Path parsing**: Extracts scope ID (e.g., `account_id` for AWS), `region`, and `root` from the unit path relative to the partition directory (`path_relative_to_include()`). The partition name itself comes from `basename(get_parent_terragrunt_dir())`.

**State key**: Derived from the unit path relative to `stacks/<partition>` using `path_relative_to_include()`. Format: `tfstate/<scope_id>/<region>/<root>/terraform.tfstate`

**Generated files** (overwritten on every Terragrunt run):
- `backend.tf` — Backend configuration (S3 in the AWS example)
- `providers.tf` — Provider configuration copied from `stacks/<partition>/providers.tf`
- `versions.tf` — Copied from `vendor/versions.tf`
- `.terraform.lock.hcl` — Copied from `vendor/.terraform.lock.hcl`

**Input merge order** (later values override earlier):
1. `globals.tfvars.yaml` (partition-level)
2. `<root>.tfvars.yaml` (root-specific, optional)
3. Scope-level YAML (e.g., `account.tfvars.yaml` for AWS)
4. Computed values: scope ID, `region`, `partition`, and other computed variables

Units outside the global region should depend on the global-region unit for the same root (defined in the unit's `terragrunt.hcl` `dependency` block).

For procedures on managing stacks and units, see [stacks/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/stacks/AGENTS.md).

## Change Detection

Each root includes a `.tardigrade.config.yaml` file listing its `dependency_globs` — glob patterns (relative to `tardigrade/`) for vendored modules, local modules, and data files the root depends on. Examples: `vendor/cloudtrail/**`, `modules/okta/**`.

The `terragrunt-root.hcl` file calls `mark_glob_as_read()` on these patterns. When you run `terragrunt find --filter "[<base>...HEAD]"`, Terragrunt identifies which units need replanning based on the files changed between commits.

This is a core Terragrunt mechanism (not CI-specific). It ensures that:
- Updating `vendor/cloudtrail/**` only affects units whose roots list it in their dependency globs
- CI pipelines or Gruntwork Pipelines run plans only for affected units
- Developers can quickly identify blast radius before applying changes

Units may add their own `.tardigrade.config.yaml` with additional globs for unit-specific dependencies.
