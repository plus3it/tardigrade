# Vendor: External Module Management

This file describes how to add, upgrade, and reference external Terraform modules in tardigrade.

## What is Vendoring

Vendoring downloads external modules to `tardigrade/vendor/.terraform/modules/` so roots can reference them via relative paths. External modules can come from any source Terraform supports: public or private git repositories, or public or private Terraform registries.

This approach:

- Pins module versions explicitly in `vendor/main.tf`
- Eliminates runtime calls to Git or HTTP during `terraform init` in units
- Keeps the repository self-contained for air-gapped environments

## Add an External Module

### 1. Add a Module Reference to vendor/main.tf

Open `tardigrade/vendor/main.tf` and add a new module block. Keep the labels in alphabetical order:

Public module example:
```hcl
module "<label>" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-<name>.git?ref=<version>"
  
  # Dummy inputs to satisfy variable requirements (not actually used)
  # Add required inputs here with null or dummy values
}
```

Private git module example:
```hcl
module "<label>" {
  source = "git::https://github.com/example-org/terraform-example-module.git?ref=<version>"
  
  # Dummy inputs
}
```

The `<label>` is how the module will be referenced after vendoring. Use a descriptive label that matches the module's purpose.

For modules with required variables, provide dummy values (typically `null`) to satisfy `terraform init`. These values are not used; they exist only to make the module block valid.

### 2. Run make terraform/vendor

```bash
make terraform/vendor
```

This runs `terraform init` in `vendor/`, downloading modules to `vendor/.terraform/modules/`. It also removes unused directories (`tests`, `examples`, `.github`, `.git`) to reduce repository size.

### 3. Verify the Module Path

Check `vendor/.terraform/modules/modules.json` to see the exact path where the module was installed:

```bash
jq '.Modules[] | select(.Key == "<label>")' vendor/.terraform/modules/modules.json
```

For modules with submodules (e.g., `cloudtrail//modules/s3-bucket`), the submodule path is appended. For example, if you vendor:

```hcl
module "security_hub_member" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-security-hub.git//modules/cross-account-member?ref=5.0.0"
}
```

The path becomes `vendor/.terraform/modules/security_hub_member/modules/cross-account-member`.

### 4. Reference from Roots

From a root module (e.g., `roots/member/`), reference the vendored module:

```hcl
module "example" {
  source = "../../vendor/.terraform/modules/<label>"
  
  # actual inputs
}
```

For submodules, include the submodule path:

```hcl
module "example_submodule" {
  source = "../../vendor/.terraform/modules/<label>/modules/<submodule>"
}
```

### 5. Read the Module's Variables

Before using a vendored module in a root, read its `variables.tf` at the pinned ref. Module interfaces can change between major versions. Construct the URL:

```
https://github.com/plus3it/terraform-aws-tardigrade-<name>/blob/<version>/variables.tf
```

Or read the local file after vendoring:

```bash
cat vendor/.terraform/modules/<label>/variables.tf
```

## Private Sources

When using modules from private git repositories or private registries, configure authentication before running `make terraform/vendor`.

### Source Formats

**Git over HTTPS:**
```hcl
source = "git::https://github.com/example-org/terraform-example-module.git?ref=1.0.0"
```

**Git over SSH:**
```hcl
source = "git::ssh://git@github.com/example-org/terraform-example-module.git?ref=1.0.0"
```

**Private registry:**
```hcl
source = "registry.example.com/namespace/module"
version = "1.0.0"
```

### Authentication

Terraform uses the git client for git sources, so it respects your existing git credentials (SSH keys, git credential helpers, `.netrc` file).

For private registries, use a CLI credentials block in `~/.terraformrc` or set a `TF_TOKEN_<hostname>` environment variable (replace dots with underscores).

### CI Authentication

Configure credentials before `make terraform/vendor` runs in CI. For example, GitLab CI can write `~/.netrc` with a job token, or GitHub Actions can configure git credentials with a personal access token.

**Important:**
- Never commit tokens or credentials to the repository
- Prepare CI credential changes (adding CI variables, configuring job token permissions) for a person to review and apply

## Upgrade an External Module

### 1. Update the ref in vendor/main.tf

Change the `?ref=<version>` parameter to the new version:

```hcl
module "<label>" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-<name>.git?ref=<new_version>"
}
```

### 2. Run make terraform/vendor

```bash
make terraform/vendor
```

### 3. Check for Breaking Changes

If upgrading a major version, review the module's CHANGELOG for breaking changes. Update roots that use the module if the interface changed.

### 4. Test

Validate roots that use the upgraded module:

```bash
terraform -chdir=tardigrade/roots/<root> init -backend=false
terraform -chdir=tardigrade/roots/<root> validate
```

## Update Provider Locks

When vendoring a module that introduces a new provider or updates provider version constraints, update the lock file:

```bash
make terraform/lock
```

This locks provider versions for multiple platforms (linux_amd64, darwin_amd64, windows_amd64, linux_arm64) in `vendor/.terraform.lock.hcl`. Terragrunt copies this lock file to each unit, ensuring consistent provider versions.

## Keep Terraform Version Aligned

The `tardigrade/vendor/versions.tf` file pins the minimum Terraform version. Keep this version equal to the version in `.mise.toml` (which pins the exact version used locally and in CI):

```hcl
terraform {
  required_version = ">= 1.16"
}
```

When upgrading the Terraform version in `.mise.toml`, update `vendor/versions.tf` to match.

## Vendored Modules vs. Local Modules

Use vendored modules for:
- External public modules (`plus3it/terraform-aws-tardigrade-*`)
- Reusable third-party modules

Use local modules (`modules/<name>/`) for:
- Deployment-specific logic
- Quick prototypes before publishing

See [tardigrade/modules/AGENTS.md](../modules/AGENTS.md) for local module guidance.
