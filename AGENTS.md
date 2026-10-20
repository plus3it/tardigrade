# Agent Instructions for Plus3IT Repositories

This file provides instructions for AI agents working with Plus3IT repositories. Every repository created from this template inherits these instructions.

## Overview

Plus3IT repositories follow a standardized structure using tardigrade-ci tooling for development, testing, and releases. Most repositories are hosted on GitHub and use reusable workflows from plus3it/actions-workflows.

## Tooling

All Plus3IT repositories include tardigrade-ci, a Docker-based test framework that provides standardized make targets for development tasks.

### Available Commands

Run `make help` to see all available targets. Common targets include:

- `make lint` — Runs all linters (editorconfig, YAML, JSON, shell scripts, Python, Terraform, HCL)
- `make test` — Runs tests (typically Terraform pytest via mockstack)
- `make docker/run target=<TARGET>` — Runs a make target inside the tardigrade-ci Docker container
- `make <lang>/format` — Formats files (e.g., `make python/format`, `make terraform/format`, `make hcl/format`, `make json/format`)

### Docker Image and Makefile

The `Dockerfile` at the repository root pins the tardigrade-ci version with a `FROM plus3it/tardigrade-ci:<version>` line. Dependabot automatically updates this pin. The Makefile bootstrap reads the same pin to clone the matching tardigrade-ci version.

The repository Makefile includes tardigrade-ci's bootstrap:

```makefile
include $(shell test -f .tardigrade-ci || curl -sSL -o .tardigrade-ci "https://raw.githubusercontent.com/plus3it/tardigrade-ci/master/bootstrap/Makefile.bootstrap"; echo .tardigrade-ci)
```

This bootstrap automatically clones or updates the tardigrade-ci tooling into a local subdirectory based on the Dockerfile pin.

## Release Process

Use bump2version to increment the version in `.bumpversion.cfg`:

```bash
make bumpversion/patch   # For bug fixes (1.2.3 → 1.2.4)
make bumpversion/minor   # For new features (1.2.3 → 1.3.0)
make bumpversion/major   # For breaking changes (1.2.3 → 2.0.0)
```

This command updates `current_version` in `.bumpversion.cfg` and commits the change (the config has `commit = True` and `tag = False`). Update `CHANGELOG.md` in the same PR following [Keep a Changelog](http://keepachangelog.com/) format.

When the PR merging the version bump is pushed to the default branch (main or master), the release workflow (`.github/workflows/release.yml`) runs automatically. The workflow creates a GitHub Release and tag named after `current_version` ONLY if that version differs from the latest existing tag. Release notes are generated automatically by GitHub, not extracted from CHANGELOG.md.

## Repository Automation

### Mergify

The `.mergify.yml` file auto-approves Dependabot pull requests and then merges them (merge method). It has no rules for other pull requests.

### Dependabot

The `.github/dependabot.yml` file configures automatic dependency updates for GitHub Actions and Docker images (weekly, grouped by ecosystem).

## Formatting

All repositories follow `.editorconfig` rules. Validate formatting with `make ec/lint`.

## What is tardigrade

tardigrade is an account baseline framework that uses Terragrunt and Terraform to deploy and manage AWS account configurations. It provides a standardized structure for managing multiple AWS accounts across different partitions (commercial AWS, GovCloud, etc.).

### Architecture Layers

tardigrade organizes infrastructure into these layers, bottom to top:

1. **Vendor**: External Terraform modules pinned and vendored locally (`tardigrade/vendor/`)
2. **Modules**: Local reusable Terraform modules (`tardigrade/modules/<name>/`)
3. **Roots**: Terraform root modules that compose modules into deployable configurations (`tardigrade/roots/<root>/`)
4. **Stacks and Units**: Account-specific Terragrunt configurations (`tardigrade/stacks/<partition>/<account_id>/<region>/<root>/`)
5. **Templates**: Starter configurations for onboarding new accounts (`tardigrade/templates/<type>/`)

### Glossary

- **Unit**: A directory with `terragrunt.hcl`; one unit has one state file. Path: `tardigrade/stacks/<partition>/<account_id>/<region>/<root>/`
- **Stack**: An account directory and all its units, `tardigrade/stacks/<partition>/<account_id>/`. "Add a stack" means onboarding an account. "Add a unit" means a new region or root in an existing account. Note: this is NOT a `terragrunt.stack.hcl` file or a Spacelift stack.
- **Root**: A Terraform root module in `tardigrade/roots/<root>/`, deployed by units.
- **Module**: A local reusable module in `tardigrade/modules/<name>/`
- **Public module**: A `plus3it/terraform-aws-tardigrade-*` repository
- **Vendor**: The `tardigrade/vendor/main.tf` file that pins external modules; after running `make terraform/vendor`, modules are available at `tardigrade/vendor/.terraform/modules/<label>`
- **Template**: Starter files in `tardigrade/templates/<type>/` for creating new stacks
- **Partition**: AWS partition (e.g., `aws`, `aws-us-gov`, `aws-cn`)
- **Global region**: The primary region for each partition where global resources are deployed (e.g., `us-east-1` for `aws`, `us-gov-west-1` for `aws-us-gov`)

### Verify and Build Commands

Before running any Terraform or Terragrunt commands, ensure external modules are vendored:

```bash
make terraform/vendor
```

Linting:

```bash
make lint              # Runs all linters
make ec/lint           # Editorconfig check
make hcl/lint          # HCL syntax
make terraform/lint    # Terraform files in roots/
make json/lint         # JSON files
make yaml/lint         # YAML files
```

Validate roots:

```bash
terraform -chdir=tardigrade/roots/<root> init -backend=false
terraform -chdir=tardigrade/roots/<root> validate
```

Plan a single unit (requires AWS credentials):

```bash
terragrunt plan --working-dir tardigrade/stacks/<partition>/<account_id>/<region>/<root>
```

Never run `apply`, `destroy`, `import`, or `state` commands without explicit human approval.

### Safety Rules

- Never run `apply`, `destroy`, `import`, or `state` commands, or `aws organizations create-account`/`close-account`. Prepare them for a person to run.
- These actions move state and need a human-approved migration plan: renaming or moving a unit path, moving `terragrunt-root.hcl` to a different depth, or changing the state `key`/`TfstateKey` expression.
- Never edit generated `backend.tf`, `providers.tf`, `versions.tf`, or `.terraform.lock.hcl` in a unit directory. These files are generated by Terragrunt from the partition-level configuration.

### Procedure Index

Detailed instructions for common tasks:

- [Add a stack or unit](tardigrade/stacks/AGENTS.md)
- [Add a root](tardigrade/roots/AGENTS.md)
- [Add a local module](tardigrade/modules/AGENTS.md)
- [Add or upgrade a vendor module](tardigrade/vendor/AGENTS.md)
- [Template conventions](tardigrade/templates/AGENTS.md)
- [Create a new deployment repository](NEW_REPO.md)

### tardigrade-cli

The tardigrade-cli project is defunct and in reference-only mode. Do not suggest installing or running `tg`. If documentation references tardigrade-cli functions, treat them as describing logic to replicate, not as a dependency to invoke.

## Repository-specific

### Purpose

<!--
Describe the specific purpose of this tardigrade deployment repository.
Example: "Manages the AWS account baselines for ACME Corp's commercial and GovCloud environments."
-->

### Accounts and Partitions

<!--
List the AWS partitions, accounts, and their purposes managed by this repository.
Example:
- Partition: aws
  - Management (123456789012): Organization management, billing, CloudTrail/Config aggregation
  - Dev (210987654321): Development environment
  - Prod (135792468013): Production environment
- Partition: aws-us-gov
  - GovCloud Management (987654321098): GovCloud organization management
-->

### Credentials

<!--
Describe how to authenticate to AWS for local operations.
Example: "Set AWS_PROFILE=tardigrade-admin before running Terragrunt commands. The profile must have access to assume the OrganizationAccountAccessRole in each target account."

Or: "CI/CD uses OIDC to assume arn:aws:iam::123456789012:role/github-actions-role. For local testing, use aws-vault: `aws-vault exec tardigrade-admin -- terragrunt plan --working-dir <unit>`"
-->

### CI/CD

<!--
If this section is empty, ask the user how plan/apply run here; do not assume GitLab, GitHub Actions, Gruntwork Pipelines, or Spacelift.

Describe the actual CI/CD workflow for this repository.
Example:
- Pull requests trigger `make lint` via GitHub Actions
- Merges to main trigger a GitLab pipeline that runs `terragrunt run --all plan` across all changed units
- Applies require manual approval in GitLab and run `terragrunt run --all apply` on affected units
- State is stored in S3 bucket `acme-tardigrade-tfstate` with DynamoDB table `acme-tardigrade-tfstate-lock`

Or:
- This repository uses Spacelift. Each unit is a separate Spacelift stack with drift detection enabled.
- Spacelift manages the apply workflow; do not run `terragrunt apply` locally.
-->

## Maintaining the tardigrade template (plus3it/tardigrade only)

This section applies only to the plus3it/tardigrade template repository. When creating a new deployment repository, delete this section and the `docs/` directory (see [NEW_REPO.md](NEW_REPO.md)).

### Documentation Sync

Any change to files under `tardigrade/` or to AGENTS.md procedures must update the corresponding GitHub Pages documentation in the same PR:

| File | Pages URL |
|------|-----------|
| `AGENTS.md` | https://plus3it.github.io/tardigrade/using-agents/ |
| `tardigrade/stacks/AGENTS.md` | https://plus3it.github.io/tardigrade/how-to-guide/ |
| `tardigrade/roots/AGENTS.md` | https://plus3it.github.io/tardigrade/structure/ |
| `tardigrade/modules/AGENTS.md` | https://plus3it.github.io/tardigrade/create-a-module/ |
| `tardigrade/vendor/AGENTS.md` | https://plus3it.github.io/tardigrade/structure/ |
| `tardigrade/templates/AGENTS.md` | https://plus3it.github.io/tardigrade/structure/ |
| `NEW_REPO.md` | https://plus3it.github.io/tardigrade/new-repository/ |

The Pages site is built from the `docs/` directory. Keep AGENTS.md files and Pages content consistent: AGENTS.md provides step-by-step procedures for agents; Pages explain concepts and link to the GitHub AGENTS.md files for the steps.

### Template Maintenance

Keep the generic sections of this AGENTS.md file (Overview, Tooling, Release Process, Repository Automation, Formatting) in sync with plus3it/repo-template. When repo-template updates those sections, propagate the changes here.
