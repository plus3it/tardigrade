# Agent Instructions

Before starting any task in this repository:

1. Run `make agents/sync`. It writes the shared Plus3 IT instructions for this repository's tardigrade-ci version to `.agents/plus3it/AGENTS.md`.
2. Read `.agents/plus3it/AGENTS.md` and follow it together with this file. If the sync fails, tell the user, and don't guess the conventions.

These rules always apply, even without the shared instructions:

- Don't push, open pull requests, publish releases, or apply infrastructure changes unless the user asks. List those steps for a person in your final report.
- Don't edit files under `.agents/plus3it/`; they are generated and overwritten by the sync.

@.agents/plus3it/AGENTS.md

## What is tardigrade

tardigrade is a repository structure and set of conventions for Terragrunt + Terraform deployments with any Terraform provider. It's used for whole-account baselines (most often AWS) and for single-application deployments (for example, on GCP). The template ships an AWS account-baseline example (management and member roots).

### Architecture Layers

tardigrade organizes infrastructure into these layers, bottom to top:

1. **Vendor**: External Terraform modules pinned and vendored locally (`tardigrade/vendor/`)
2. **Modules**: Local reusable Terraform modules (`tardigrade/modules/<name>/`)
3. **Roots**: Terraform root modules that compose modules into deployable configurations (`tardigrade/roots/<root>/`)
4. **Stacks and Units**: Scope-specific Terragrunt configurations (`tardigrade/stacks/<partition>/<scope_id>/<region>/<root>/`). In the AWS example, the scope is an account.
5. **Templates**: Starter configurations for onboarding new stacks (`tardigrade/templates/<type>/`)

### Glossary

- **Unit**: A directory with `terragrunt.hcl`; one unit has one state file. Path: `tardigrade/stacks/<partition>/<scope_id>/<region>/<root>/`
- **Stack**: A scope directory and all its units, `tardigrade/stacks/<partition>/<scope_id>/`. The scope is whatever the provider deploys into: an AWS account, a GCP project, an Azure subscription, and so on. "Add a stack" means onboarding a new scope (for AWS, an account). "Add a unit" means a new region or root in an existing stack. Note: this is NOT a `terragrunt.stack.hcl` file or a Spacelift stack. A deployment may also use terragrunt.stack.hcl files; when it does, say "Terragrunt stack file" for those.
- **Root**: A Terraform root module in `tardigrade/roots/<root>/`, deployed by units.
- **Module**: A local reusable module in `tardigrade/modules/<name>/`
- **External module**: A reusable module from any external source (public or private git repositories, public or private Terraform registries). Plus3 IT public modules use the `plus3it/terraform-aws-tardigrade-*` naming convention.
- **Vendor**: One subdirectory per external module. `tardigrade/vendor/<label>/main.tf` holds a single `module "this"` with the pinned source; `tardigrade/vendor/main.tf` only lists `module "<label>" { source = "./<label>" }`. One `terraform init` in `vendor/` fetches everything; roots use `vendor/.terraform/modules/<label>.this`
- **Dependency globs**: `tardigrade/roots/<root>/.tardigrade.config.yaml` lists `dependency_globs` (`vendor/<label>/**`, `modules/<name>/**`, data files) for what the root uses; a unit may add its own `.tardigrade.config.yaml`. `terragrunt-root.hcl` calls `mark_glob_as_read()` and `mark_as_read()` on globs and shared input files, so change detection (`terragrunt find --filter "[<base>...HEAD]"`) selects only units affected by a dependency update. Shared files that affect all units: `vendor/versions.tf`, `vendor/.terraform.lock.hcl`, `stacks/<partition>/providers.tf`, `globals.tfvars.yaml`. Scope-level files (e.g., `account.tfvars.yaml`) affect only units in that scope. Root-specific files (e.g., `<root>.tfvars.yaml`) affect only units of that root.
- **Template**: Starter files in `tardigrade/templates/<type>/` for creating new stacks
- **Partition**: The cloud or partition directory (e.g., `aws`, `aws-us-gov`, `gcp`). For the AWS example: AWS partition (e.g., `aws`, `aws-us-gov`, `aws-cn`)
- **Global region**: The primary region for each partition where global resources are deployed (e.g., `us-east-1` for `aws`, `us-gov-west-1` for `aws-us-gov`)

### Verify and Build Commands

Before running any Terraform or Terragrunt commands, ensure external modules are vendored:

```bash
make terraform/vendor
```

Linting:

```bash
make lint                     # Runs all linters
make ec/lint                  # Editorconfig check
make hcl/lint                 # HCL syntax
make terraform/lint           # Terraform files in roots/
make json/lint                # JSON files
make yaml/lint                # YAML files
```

Validate roots:

```bash
make terraform/validate-roots # Validates all roots against vendored modules
```

Plan a single unit (requires AWS credentials):

```bash
terragrunt plan --working-dir tardigrade/stacks/<partition>/<scope_id>/<region>/<root>
```

Never run `apply`, `destroy`, `import`, or `state` commands without explicit human approval.

### Safety Rules

- Never run `apply`, `destroy`, `import`, or `state` commands, or `aws organizations create-account`/`close-account`. Prepare them for a person to run.
- These actions move state and need a human-approved migration plan: renaming or moving a unit path, moving `terragrunt-root.hcl` to a different depth, or changing the state `key`/`TfstateKey` expression.
- Never edit generated `backend.tf`, `providers.tf`, `versions.tf`, or `.terraform.lock.hcl` in a unit directory. These files are generated by Terragrunt from the partition-level configuration.

### Procedure Index

Detailed instructions for common tasks. Before starting one of these tasks, read the linked file. In a deployment, `make agents/sync` writes these files to `.agents/plus3it/tardigrade/` when the repository pins the tardigrade template (see `.github/workflows/dependabot_hack.yml`). In the plus3it/tardigrade template itself, they are in `agents/procedures/`. A short `AGENTS.md` in each of `tardigrade/{stacks,roots,modules,vendor,templates}/` points to the matching file.

- Add a stack or unit: `.agents/plus3it/tardigrade/stacks.md` (template: `agents/procedures/stacks.md`)
- Add a root: `.agents/plus3it/tardigrade/roots.md` (template: `agents/procedures/roots.md`)
- Add a local module: `.agents/plus3it/tardigrade/modules.md` (template: `agents/procedures/modules.md`)
- Add or upgrade a vendor module: `.agents/plus3it/tardigrade/vendor.md` (template: `agents/procedures/vendor.md`)
- Template conventions: `.agents/plus3it/tardigrade/templates.md` (template: `agents/procedures/templates.md`)
- [Create a new deployment repository](NEW_REPO.md)

### Using Another Provider or Deployment Type

The AWS account-baseline example follows these conventions, but tardigrade works with any Terraform provider. For guidance on adapting tardigrade for GCP, Azure, or single-application deployments, see the "Using another provider or deployment type" section in [Structure](https://plus3it.github.io/tardigrade/structure/#using-another-provider-or-deployment-type).

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

### Testing

Before reporting work complete, run:

```bash
make terraform/vendor         # Vendor external modules
make terraform/validate-roots # Validate all root modules
make lint                     # Run all linters
```

To find units affected by a change, use Terragrunt's change detection:

```bash
terragrunt find --filter "[<base>...HEAD]" --working-dir tardigrade/stacks/<partition>
```

This lists units whose dependencies changed between `<base>` and `HEAD`. For example, use `origin/main...HEAD` to find units affected by commits in the current branch.

List affected units in your final report so a person or CI can plan them.

## Maintaining the tardigrade template (plus3it/tardigrade only)

This section applies only to the plus3it/tardigrade template repository. When creating a new deployment repository, delete this section, the `docs/` directory, and the `agents/` directory (see [NEW_REPO.md](NEW_REPO.md)).

### Documentation Sync

Any change to files under `tardigrade/` or to a procedure in `agents/procedures/` must update the corresponding GitHub Pages documentation in the same PR:

| File | Pages URL |
|------|-----------|
| `AGENTS.md` | https://plus3it.github.io/tardigrade/using-agents/ |
| `agents/procedures/stacks.md` | https://plus3it.github.io/tardigrade/how-to-guide/ |
| `agents/procedures/roots.md` | https://plus3it.github.io/tardigrade/structure/ |
| `agents/procedures/modules.md` | https://plus3it.github.io/tardigrade/create-a-module/ |
| `agents/procedures/vendor.md` | https://plus3it.github.io/tardigrade/structure/ and https://plus3it.github.io/tardigrade/create-a-module/ |
| `agents/procedures/templates.md` | https://plus3it.github.io/tardigrade/structure/ |
| `NEW_REPO.md` | https://plus3it.github.io/tardigrade/new-repository/ |

The Pages site is built from the `docs/` directory. Keep the procedures and Pages content consistent: the procedures give step-by-step instructions for agents; Pages explain concepts and link to the procedures in `agents/procedures/`. The `AGENTS.md` stubs in `tardigrade/*/` never change.

### Agent Instruction Maintenance

The committed pointer at the top of this file comes from plus3it/repo-template. When repo-template updates it, copy the new version here unchanged.

The shared instructions live in tardigrade-ci `agents/` and are synced at runtime into `.agents/plus3it/AGENTS.md`, pinned to the tardigrade-ci version this repository uses. Changes to shared conventions happen in tardigrade-ci and reach deployment repos when their tardigrade-ci pin is bumped, through the update pull requests Dependabot (GitHub) or Renovate (other hosts) opens.

When updating tardigrade-specific sections (glossary, procedures, etc.) in this file, also update the corresponding Pages documentation.

### Template Procedures

The procedures in `agents/procedures/` (`stacks.md`, `roots.md`, `modules.md`, `vendor.md`, `templates.md`) are released with the template's tags. They describe this layout, so change them in the same PR as the layout change. Deployments read them at a pinned tag: a `uses: plus3it/tardigrade@<tag>` line in `.github/workflows/dependabot_hack.yml` opts a deployment in, and `make agents/sync` (tardigrade-ci 0.31.0 or later) writes the files from that tag to `.agents/plus3it/tardigrade/`. A deployment bumps the pin on purpose, after reading the template CHANGELOG.

- `.bumpversion.cfg` rewrites the pin in `.github/workflows/dependabot_hack.yml` on every version bump, so the pin always equals the released version. A deployment created from the template starts pinned to the version it was created from.
- The procedure files must be named exactly as above; tardigrade-ci copies every `*.md` in `agents/procedures/`.
- In a procedure, name another procedure by file name ("`vendor.md`, in the same directory"), not by relative link, because deployments read the files from `.agents/plus3it/tardigrade/`. Paths from the repository root, such as `tardigrade/stacks/`, are valid in a deployment and can stay.
- The template's own `agents/` directory is removed from new deployments (a step in [NEW_REPO.md](NEW_REPO.md)), because deployments receive the procedures by sync. The `AGENTS.md` stubs in `tardigrade/*/` stay.
- A major version bump means a layout change; describe the migration in the CHANGELOG.
