# Vendor: External Module Management

This file describes how to add, upgrade, and reference external Terraform modules in tardigrade.

## What is Vendoring

Vendoring downloads external modules to `tardigrade/vendor/.terraform/modules/` so roots can reference them via relative paths. External modules can come from any source Terraform supports: public or private git repositories, or public or private Terraform registries.

Each external module is vendored in its own directory under `vendor/<label>/`, containing a single `module "this"` block with the pinned source. The `vendor/main.tf` file only lists references to these directories.

This approach:

- Pins module versions explicitly in per-directory `vendor/<label>/main.tf` files
- Avoids fetching the vendored modules themselves at unit init; nested remote modules and providers are still downloaded.
- Enables granular change detection: only units whose roots list `vendor/<label>/**` are affected by updates to that module. Changes to `vendor/versions.tf` and `vendor/.terraform.lock.hcl` affect all units.

## Add an External Module

### 1. Create a Vendor Directory

Create `tardigrade/vendor/<label>/main.tf` containing a single `module "this"` block with the pinned source. Use a descriptive label that matches the module's purpose:

Public module example:
```hcl
module "this" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-<name>.git?ref=<version>"
  
  # Dummy inputs to satisfy variable requirements (not actually used)
  # Add required inputs here with null or dummy values
}
```

Private git module example:
```hcl
module "this" {
  source = "git::https://github.com/example-org/terraform-example-module.git?ref=<version>"
  
  # Dummy inputs
}
```

For modules with required variables, provide dummy values (typically `null`) to satisfy `terraform init`. These values are not used; they exist only to make the module block valid.

For modules with submodules, include the submodule path in the source:

```hcl
module "this" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-<name>.git//modules/<submodule>?ref=<version>"
  
  # Include any required providers block
  providers = {
    aws               = aws
    aws.administrator = aws
  }
}
```

### 2. Add Module Entry to vendor/main.tf

Open `tardigrade/vendor/main.tf` and add a reference to the new directory. Keep the labels in alphabetical order:

```hcl
module "<label>" {
  source = "./<label>"
}
```

### 3. Run make terraform/vendor

```bash
make terraform/vendor
```

This runs `terraform init` in `vendor/`, downloading modules to `vendor/.terraform/modules/`. It also removes unused directories (`tests`, `examples`, `.github`, `.git`) to reduce repository size.

### 4. Verify the Module Path

Check `tardigrade/vendor/.terraform/modules/modules.json` to see the exact path where the module was installed:

```bash
jq '.Modules[] | select(.Key == "<label>.this")' tardigrade/vendor/.terraform/modules/modules.json
```

The vendored module is accessible at `tardigrade/vendor/.terraform/modules/<label>.this`. For modules with submodules, the Dir field in modules.json shows the exact path (e.g., `.terraform/modules/<label>.this/modules/<submodule>`).

### 5. Reference from Roots

From a root module (e.g., `roots/member/`), reference the vendored module using the `.this` suffix:

```hcl
module "example" {
  source = "../../vendor/.terraform/modules/<label>.this"
  
  # actual inputs
}
```

For submodules, append the submodule path:

```hcl
module "example_submodule" {
  source = "../../vendor/.terraform/modules/<label>.this/modules/<submodule>"
}
```

### 6. Update Root's Dependency Globs

Add `vendor/<label>/**` to the `dependency_globs` list in `tardigrade/roots/<root>/.tardigrade.config.yaml`:

```yaml
dependency_globs:
  - vendor/<label>/**
  # other dependencies...
```

This ensures that units using this root are re-planned when the vendored module changes.

### 7. Read the Module's Variables

Before using a vendored module in a root, read its `variables.tf` at the pinned ref. Module interfaces can change between major versions. Construct the URL:

```
https://github.com/plus3it/terraform-aws-tardigrade-<name>/blob/<version>/variables.tf
```

Or read the local file after vendoring:

```bash
cat tardigrade/vendor/.terraform/modules/<label>.this/variables.tf
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

### 1. Update the ref in vendor/<label>/main.tf

Open `tardigrade/vendor/<label>/main.tf` and change the `?ref=<version>` parameter to the new version:

```hcl
module "this" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-<name>.git?ref=<new_version>"
}
```

Because each external module has its own directory, only units of roots that list `vendor/<label>/**` in their dependency globs will be affected by this change.

### 2. Run make terraform/vendor

```bash
make terraform/vendor
```

### 3. Check for Breaking Changes

If upgrading a major version, review the module's CHANGELOG for breaking changes. Update roots that use the module if the interface changed.

### 4. Test

Validate roots that use the upgraded module:

```bash
make terraform/validate-roots
```

## Update Provider Locks

When vendoring a module that introduces a new provider or updates provider version constraints, update the lock file:

```bash
make terraform/lock
```

This locks provider versions for multiple platforms (linux_amd64, darwin_amd64, windows_amd64, linux_arm64) in `vendor/.terraform.lock.hcl`. Terragrunt copies this lock file to each unit, ensuring consistent provider versions.

## Keep Terraform Version Aligned

The `tardigrade/vendor/versions.tf` file pins the exact Terraform version used locally and in CI. Keep this version equal to the version in `.mise.toml`:

```hcl
terraform {
  required_version = "<version>" # terraform-version
}
```

The `# terraform-version` marker lets the Makefile grep for this version. When upgrading the Terraform version in `.mise.toml`, update `vendor/versions.tf` to match.

## Vendored Modules vs. Local Modules

Use vendored modules for:
- External public modules (`plus3it/terraform-aws-tardigrade-*`)
- Reusable third-party modules

Use local modules (`modules/<name>/`) for:
- Deployment-specific logic
- Quick prototypes before publishing

See `modules.md`, in the same directory, for local module guidance.

## Dependency Updates

On GitHub, Dependabot (configured in `.github/dependabot.yml`) proposes pull requests for pin updates. On other hosts, Renovate (configured in `renovate.json`) proposes updates. Mergify (GitHub only) can auto-merge Dependabot PRs based on rules in `.mergify.yml`.
