# Stacks: Adding Scopes and Units

This file describes how to add scopes (stacks) and regions or roots (units) to a tardigrade deployment. In the AWS account-baseline example, a stack is an AWS account.

## Add a Stack (New Scope)

A stack is a scope directory managed by tardigrade. The scope is whatever the provider deploys into: an AWS account, a GCP project, an Azure subscription, and so on. Adding a stack means onboarding a new scope into the deployment. For AWS, this means onboarding an account.

### Prerequisites (AWS example)

For AWS: the account must already exist. If it's not known whether the account exists, ask before proceeding. If it doesn't exist, prepare the `aws organizations create-account` command for a person to run. Never run organization management commands yourself.

For other providers: ensure the scope (project, subscription, etc.) exists before proceeding.

### Steps

1. Choose the template type (`member` or `management` in the AWS example) based on the scope's role.

2. Copy the scope configuration file:

    ```bash
    cp tardigrade/templates/<type>/account.tfvars.yaml \
        tardigrade/stacks/<partition>/<scope_id>/account.tfvars.yaml
    ```

    For AWS, `<scope_id>` is the 12-digit account ID. For GCP, it's the project ID. For Azure, it's the subscription ID.

3. Edit `tardigrade/stacks/<partition>/<scope_id>/account.tfvars.yaml` (or the equivalent scope-level YAML) and fill in all values. For the AWS example:
    - `account_name`: lowercase letters, numbers, and hyphens only
    - `email_address`: root email address for the account
    - Remove any other placeholder comments

4. Copy the global unit for the scope's primary root:

    ```bash
    cp -r tardigrade/templates/<type>/global/<root> \
        tardigrade/stacks/<partition>/<scope_id>/<global_region>/<root>
    ```

    For units that aren't regional (e.g., in a GCP deployment), the directory may be named `_global/` instead of a region name.

5. Copy regional units for each additional region:

    ```bash
    cp -r tardigrade/templates/<type>/regional/<root> \
        tardigrade/stacks/<partition>/<scope_id>/<region>/<root>
    ```

6. Edit each unit's `terragrunt.hcl` and `terraform.tfvars`:
    - Replace any remaining `{{placeholders}}` with actual values
    - Update dependency paths if needed (e.g., `{{management_account_id}}` in dependency blocks)
    - Verify the `source` path points to the correct root module

7. Validate the configuration:

    ```bash
    make terraform/validate-roots
    ```

Regional units typically depend on the global unit for the same root. Ensure dependency paths are correct.

For the AWS example: member stacks depend on the management stack. The management stack must be applied first so member units can reference its outputs (CloudTrail and Config bucket names). The member templates include `mock_outputs` limited to `validate`: with backend credentials, `terragrunt validate` works on a member unit before the management stack is applied. Without credentials, check unit configuration with `terragrunt hcl validate` and roots with `make terraform/validate-roots`; `plan` never uses the mocks.

8. In your final report, list for a person to complete:
    - Create the scope or confirm it exists (if not already confirmed). For AWS: create the account or confirm it exists.
    - For member stacks in the AWS example: apply the management stack first if not already applied
    - Run `terragrunt plan --working-dir <unit-path>` for each new unit (list the unit paths)

## Add a Unit (New Region or Root)

Adding a unit means deploying an existing root to a new region within an existing stack, or deploying a new root to an existing stack.

### For a New Region

Copy the regional template for the root:

```bash
cp -r tardigrade/templates/<type>/regional/<root> \
    tardigrade/stacks/<partition>/<scope_id>/<region>/<root>
```

Edit the files to replace placeholders and verify dependencies.

### For a New Root in an Existing Region

1. Ensure the root exists in `tardigrade/roots/<new_root>/`
2. Ensure a template exists in `tardigrade/templates/<type>/{global,regional}/<new_root>/`
3. Copy the appropriate template to the stack:

    ```bash
    cp -r tardigrade/templates/<type>/global/<new_root> \
        tardigrade/stacks/<partition>/<scope_id>/<global_region>/<new_root>
    ```

## Unit-Level Dependency Globs (Optional)

A unit may add its own `.tardigrade.config.yaml` with additional `dependency_globs` (paths relative to `tardigrade/`). These globs supplement the root's dependency globs for change detection.

Use this sparingly and only for dependencies specific to one unit (e.g., a unit-specific data file). Never put state-affecting changes here; it only affects change detection via `terragrunt find --filter`.

Example:

```yaml
dependency_globs:
  - data/unit-specific-data.yaml
```

## Inputs Precedence

Terragrunt and Terraform merge configuration inputs in this order (later values override earlier ones):

1. `tardigrade/stacks/<partition>/globals.tfvars.yaml` — partition-wide settings (loaded by Terragrunt)
2. `tardigrade/stacks/<partition>/<root>.tfvars.yaml` — root-specific settings for the partition (if exists, loaded by Terragrunt)
3. `tardigrade/stacks/<partition>/<scope_id>/account.tfvars.yaml` (or equivalent scope-level YAML) — scope-specific settings (loaded by Terragrunt)
4. Computed inputs — extracted from the unit path and added by `terragrunt-root.hcl`. For the AWS example:
    - `account_id`: from the directory path
    - `region`: from the directory path
    - `partition`: from the parent directory name
    - `global_region`: from `terragrunt-root.hcl` local
    - `session_name`: from `AWS_ROLE_SESSION_NAME` environment variable
    - `default_tags`: generated tags, including state paths and the `TardigradeManaged` marker
5. Unit-level `inputs` block in the unit's `terragrunt.hcl` — unit-specific overrides
6. `terraform.tfvars` in the unit directory — auto-loaded by Terraform. This overrides Terragrunt's inputs because Terraform loads `terraform.tfvars` after processing the TF_VAR_* environment variables that Terragrunt sets.

Verify the merge logic in `tardigrade/stacks/<partition>/terragrunt-root.hcl`. Use Terragrunt's `inputs` block (step 5) for most unit-specific values. Use `terraform.tfvars` (step 6) sparingly, only when you need values to override Terragrunt's inputs.

## Generated Files

Terragrunt generates these files in each unit directory. Never edit them directly:

- `backend.tf` — Backend configuration (S3 in the AWS example)
- `providers.tf` — Provider configuration (copied from `stacks/<partition>/providers.tf`)
- `versions.tf` — Terraform and provider version constraints (copied from `vendor/versions.tf`)
- `.terraform.lock.hcl` — Provider lock file (copied from `vendor/.terraform.lock.hcl`)

If you need to change these files, edit the source file in `stacks/<partition>/` or `vendor/`, then rerun `terragrunt init` in the unit.

## State Key Paths

The Terraform state key for each unit is derived from `path_relative_to_include()`, which is the path from the partition directory to the unit. Examples:

-   AWS: Unit `tardigrade/stacks/aws/123456789012/us-east-1/member/` → State key `tfstate/123456789012/us-east-1/member/terraform.tfstate`
-   GCP: Unit `tardigrade/stacks/gcp/my-project/us-east5/app/` → State key `tfstate/my-project/us-east5/app/terraform.tfstate`

Never change the state key expression in `terragrunt-root.hcl` without a human-approved migration plan. Moving or renaming a unit directory changes its state key and requires a state migration.

## Safety Rules

- Never run `apply`, `destroy`, `import`, or `state` commands, or `aws organizations create-account`/`close-account`. Prepare them for a person to run.
- Renaming or moving a unit path requires a state migration plan approved by a human.
- Never edit generated files in unit directories.
