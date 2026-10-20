---
title: "Creating a Module"
permalink: /create-a-module/
toc: true
---

# Overview

Tardigrade uses two types of modules:

1. **Local modules** — Deployment-specific modules in `tardigrade/modules/`
2. **Public modules** — Reusable modules in `plus3it/terraform-aws-tardigrade-*` repositories

This guide covers both approaches.

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

# Public Modules

Public modules are published to the Terraform Registry and can be reused across deployments.

## When to Use Public Modules

Create a public module when:
- The module provides general-purpose infrastructure (e.g., S3 bucket, VPC, IAM role)
- You want to share the module across multiple tardigrade deployments
- The module implements a common security baseline or compliance control

## Creating a Public Module

Public modules are separate repositories created from the [repo-template](https://github.com/plus3it/repo-template):

1. **Use the template**:
    - Visit [https://github.com/plus3it/repo-template](https://github.com/plus3it/repo-template)
    - Click "Use this template" → "Create a new repository"
    - Name it `terraform-aws-tardigrade-<service>` (e.g., `terraform-aws-tardigrade-vpc`)

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
- Run tests with `make test`

For modules that can use moto instead of LocalStack, set `ONLY_MOTO := true` in the Makefile:

```makefile
ONLY_MOTO := true
```

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

#### Release Process

Releases are automated:
1. Create a PR with the version bump and CHANGELOG update
2. Merge the PR to the default branch (main or master)
3. The `.github/workflows/release.yml` workflow creates a GitHub Release and tag automatically

For more details on module conventions, see [terraform-aws-tardigrade-acm/AGENTS.md](https://github.com/plus3it/terraform-aws-tardigrade-acm/blob/master/AGENTS.md).

## Consuming Public Modules

To use a public module in your tardigrade deployment:

1. **Add to vendor/main.tf** (in alphabetical order):
  ```hcl
  module "vpc" {
    source = "git::https://github.com/plus3it/terraform-aws-tardigrade-vpc.git?ref=8.0.0"
  }
  ```

2. **Vendor the module**:
  ```bash
  make terraform/vendor
  ```

3. **Reference from a root module**:
  ```hcl
  module "vpc" {
    source = "../../vendor/.terraform/modules/vpc"
    
    # module inputs
  }
  ```

4. **Update lock file** (for provider changes):
  ```bash
  make terraform/lock
  ```

For vendor procedures, see [vendor/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/vendor/AGENTS.md).

# Finding Existing Modules

Browse tardigrade modules on:
- [GitHub](https://github.com/search?q=org%3Aplus3it+tardigrade)
- [Terraform Registry](https://registry.terraform.io/search?q=tardigrade)
