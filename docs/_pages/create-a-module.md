---
title: "Creating a Module"
permalink: /create-a-module/
toc: true
---

# Overview

Tardigrade uses two types of modules:

1. **Local modules** — Deployment-specific modules in `tardigrade/modules/`
2. **External modules** — Reusable modules from any external source

External modules can come from:
- Public Plus3 IT `plus3it/terraform-aws-tardigrade-*` modules
- Other public git repositories or the Terraform Registry
- Private git repositories
- Private Terraform registries

External modules are pinned and vendored the same way regardless of source. See [vendor/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/vendor/AGENTS.md) for vendoring procedures.

This guide covers local modules and how to create reusable modules.

# Local Modules

Local modules are stored in `tardigrade/modules/<name>/` and are specific to your deployment.

## When to Use Local Modules

Use local modules when:
- The logic is specific to your deployment and won't be reused elsewhere
- You're prototyping a module before publishing it
- The module wraps deployment-specific business logic

## Creating a Local Module

1. Create a directory under `tardigrade/modules/<name>/`
2. Add standard Terraform files: `main.tf`, `variables.tf`, `outputs.tf`
3. Reference the module from a root module using a relative path:
  ```hcl
  module "example" {
    source = "../../modules/example"
    
    # module inputs
  }
  ```

For detailed procedures, see [modules/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/modules/AGENTS.md).

# Reusable Modules

Reusable modules are separate repositories that can be shared across tardigrade deployments. They may be public or private.

## When to Create a Reusable Module

Create a reusable module when:
- The module provides general-purpose infrastructure (e.g., S3 bucket, VPC, IAM role)
- You want to share the module across multiple tardigrade deployments
- The module implements a common security baseline or compliance control

## Creating a Reusable Module

Reusable modules are separate repositories created from the [repo-template](https://github.com/plus3it/repo-template). The repository can be public or private, hosted on GitHub, GitLab, or another git host.

1. **Use the template**:
    - For public modules on GitHub: visit [https://github.com/plus3it/repo-template](https://github.com/plus3it/repo-template), click "Use this template" → "Create a new repository"
    - For private modules: clone repo-template to your organization's GitHub or GitLab
    - Name it `terraform-<provider>-<name>` (e.g., `terraform-aws-vpc`). Plus3 IT public modules use the `terraform-aws-tardigrade-<service>` naming convention.

2. **Edit AGENTS.md**: Fill in the "Repository-specific" section with the module's purpose and layout

3. **Follow module conventions**:
    - Root module files: `main.tf`, `variables.tf`, `outputs.tf`
    - `migrations.tf` for `moved` blocks when refactoring resources
    - README with usage examples (auto-generated tables — see below)
    - Test scenarios in `tests/<scenario>/`

### Module Conventions

#### Testing

Tests use [mockstack](https://github.com/plus3it/mockstack) to simulate AWS services:

- Each test scenario lives in `tests/<scenario>/`
- The scenario contains `main.tf` that uses the module
- If tests require prerequisite resources (e.g., a VPC), create a `prereq/` subdirectory with Terraform files
- Run tests the same way CI does: `make mockstack/up`, `make mockstack/pytest`, then `make mockstack/clean` (requires Docker)

Tests use moto by default. Set `USE_LOCALSTACK` (for example, `USE_LOCALSTACK := true` in the Makefile) only if a test needs LocalStack. `ONLY_MOTO` is obsolete and has no effect; if a Makefile still sets it, it can be removed.

#### Documentation

The README is partially generated:

- Run `make docs/generate` to regenerate the tables between `<!-- BEGIN TFDOCS -->` and `<!-- END TFDOCS -->` markers
- Never edit the generated tables manually
- Keep usage examples and descriptions above the marker

#### Migrations

When refactoring resources (adding `count`, `for_each`, or renaming), add `moved` blocks to `migrations.tf`:

```hcl
moved {
  from = aws_s3_bucket.this
  to   = aws_s3_bucket.this[0]
}
```

This allows users to upgrade the module without destroying and recreating resources.

#### Versioning

Use [bump2version](https://github.com/c4urself/bump2version):

```bash
make bumpversion/patch   # 1.2.3 → 1.2.4 (bug fixes)
make bumpversion/minor   # 1.2.3 → 1.3.0 (new features)
make bumpversion/major   # 1.2.3 → 2.0.0 (breaking changes)
```

Update `CHANGELOG.md` following [Keep a Changelog](http://keepachangelog.com/) format.

#### Release Process and CI/CD

The release process depends on where the repository is hosted:

**GitHub repositories:**
1. Create a PR with the version bump and CHANGELOG update
2. Merge the PR to the default branch (main or master)
3. The `.github/workflows/release.yml` workflow (from [plus3it/actions-workflows](https://github.com/plus3it/actions-workflows)) creates a GitHub Release and tag automatically
4. Dependabot (`.github/dependabot.yml`) opens dependency update PRs, and Mergify (`.mergify.yml`) auto-merges them

**Other hosts (e.g., GitLab):**
1. Create an MR with the version bump and CHANGELOG update
2. Merge the MR to the default branch
3. The host's CI pipeline (`.gitlab-ci.yml`) runs tests and creates a release tag. GitLab uses [reusable CI components](https://docs.gitlab.com/ee/ci/components/) for common workflows
4. Renovate (`renovate.json`) opens dependency update merge requests

For more details on module conventions, see [terraform-aws-tardigrade-acm/AGENTS.md](https://github.com/plus3it/terraform-aws-tardigrade-acm/blob/master/AGENTS.md).

## Private Module Sources and Authentication

When using modules from private git repositories or private registries, you must configure authentication where `make terraform/vendor` runs (locally and in CI).

### Git Sources

**HTTPS format:**
```hcl
module "example" {
  source = "git::https://github.com/example-org/terraform-example-module.git?ref=1.0.0"
}
```

**SSH format:**
```hcl
module "example" {
  source = "git::ssh://git@github.com/example-org/terraform-example-module.git?ref=1.0.0"
}
```

Terraform uses the git client to clone module sources, so it respects your existing git credentials:
- **SSH keys** (with `git::ssh://` sources)
- **Git credential helpers** (configured via `git config credential.helper`)
- **`.netrc` file** (for HTTPS sources)

### Private Registry Sources

For private Terraform registries, use a CLI credentials block or environment variable:

**CLI credentials** (in `~/.terraformrc` or `%APPDATA%\terraform.rc`):
```hcl
credentials "registry.example.com" {
  token = "your-api-token"
}
```

**Environment variable:**
```bash
export TF_TOKEN_registry_example_com="your-api-token"
```

Replace dots in the hostname with underscores for the environment variable name.

### Authentication in CI

Authentication must be configured before running `make terraform/vendor` in CI pipelines.

**GitLab example** (using job tokens):
```yaml
before_script:
  - echo -e "machine gitlab.com\nlogin gitlab-ci-token\npassword ${CI_JOB_TOKEN}" > ~/.netrc
  - make terraform/vendor
```

Note: For `CI_JOB_TOKEN` to access a private project on GitLab, that project must allow the calling project in its "CI/CD → Job token permissions" settings.

**GitHub Actions example** (using a token with read access, such as a fine-grained personal access token or a GitHub App token):
```yaml
- name: Configure git credentials
  run: |
    git config --global url."https://x-access-token:${{ secrets.GH_TOKEN }}@github.com/".insteadOf "https://github.com/"
- name: Vendor modules
  run: make terraform/vendor
```

The token needs read access to the private repository.

### Security

- **Never commit tokens or credentials** to the repository
- **Prepare CI credential changes for a person to review and apply** (e.g., adding CI variables, configuring job token permissions)

## Consuming External Modules

To use an external module in your tardigrade deployment:

1. **Add to vendor/main.tf** (in alphabetical order):

  Public module example:
  ```hcl
  module "vpc" {
    source = "git::https://github.com/plus3it/terraform-aws-tardigrade-vpc.git?ref=8.0.0"
  }
  ```

  Private git module example:
  ```hcl
  module "private_module" {
    source = "git::https://github.com/example-org/terraform-example-module.git?ref=1.0.0"
  }
  ```

2. **Vendor the module** (authentication must be configured first for private sources):
  ```bash
  make terraform/vendor
  ```

3. **Reference from a root module**:
  ```hcl
  module "vpc" {
    source = "../../vendor/.terraform/modules/vpc.this"
    
    # module inputs
  }
  ```

4. **Update lock file** (for provider changes):
  ```bash
  make terraform/lock
  ```

For detailed vendor procedures, see [vendor/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/vendor/AGENTS.md).

# Finding Existing Modules

Browse tardigrade modules on:
- [GitHub](https://github.com/search?q=org%3Aplus3it+tardigrade)
- [Terraform Registry](https://registry.terraform.io/search?q=tardigrade)
