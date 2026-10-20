# Stacks: Adding Accounts and Units

This file describes how to add AWS accounts (stacks) and regions or roots (units) to a tardigrade deployment.

## Add a Stack (New AWS Account)

A stack is an AWS account managed by tardigrade. Adding a stack means onboarding a new account into the deployment.

### Prerequisites

The AWS account must already exist. If it's not known whether the account exists, ask before proceeding. If it doesn't exist, prepare the `aws organizations create-account` command for a person to run. Never run organization management commands yourself.

### Steps

1. Choose the template type (`member` or `management`) based on the account's role.

2. Copy the account configuration file:

    ```bash
    cp tardigrade/templates/<type>/account.tfvars.yaml \
        tardigrade/stacks/<partition>/<account_id>/account.tfvars.yaml
    ```

3. Edit `tardigrade/stacks/<partition>/<account_id>/account.tfvars.yaml` and fill in all values:
    - `account_name`: lowercase letters, numbers, and hyphens only
    - `email_address`: root email address for the account
    - Remove any other placeholder comments

4. Copy the global unit for the account's primary root:

    ```bash
    cp -r tardigrade/templates/<type>/global/<root> \
        tardigrade/stacks/<partition>/<account_id>/<global_region>/<root>
    ```

5. Copy regional units for each additional region:

    ```bash
    cp -r tardigrade/templates/<type>/regional/<root> \
        tardigrade/stacks/<partition>/<account_id>/<region>/<root>
    ```

6. Edit each unit's `terragrunt.hcl` and `terraform.tfvars`:
    - Replace any remaining `{{placeholders}}` with actual values
    - Update dependency paths if needed (e.g., `{{management_account_id}}` in dependency blocks)
    - Verify the `source` path points to the correct root module

7. Validate the configuration:

    ```bash
    terraform -chdir=tardigrade/roots/<root> validate
    ```

Regional units typically depend on the global unit for the same root. Ensure dependency paths are correct.

8. In your final report, list for a person to complete:
    - Create the account or confirm it exists (if not already confirmed)
    - Run `terragrunt plan --working-dir <unit-path>` for each new unit (list the unit paths)

## Add a Unit (New Region or Root)

Adding a unit means deploying an existing root to a new region within an existing account, or deploying a new root to an existing account.

### For a New Region

Copy the regional template for the root:

```bash
cp -r tardigrade/templates/<type>/regional/<root> \
    tardigrade/stacks/<partition>/<account_id>/<region>/<root>
```

Edit the files to replace placeholders and verify dependencies.

### For a New Root in an Existing Region

1. Ensure the root exists in `tardigrade/roots/<new_root>/`
2. Ensure a template exists in `tardigrade/templates/<type>/{global,regional}/<new_root>/`
3. Copy the appropriate template to the stack:

    ```bash
    cp -r tardigrade/templates/<type>/global/<new_root> \
        tardigrade/stacks/<partition>/<account_id>/<global_region>/<new_root>
    ```

## Inputs Precedence

Terragrunt merges YAML configuration files in this order (later values override earlier ones):

1. `tardigrade/stacks/<partition>/globals.tfvars.yaml` — partition-wide settings
2. `tardigrade/stacks/<partition>/<root>.tfvars.yaml` — root-specific settings for the partition (if exists)
3. `tardigrade/stacks/<partition>/<account_id>/account.tfvars.yaml` — account-specific settings
4. Computed inputs — extracted from the unit path and added by `terragrunt-root.hcl`:
    - `account_id`: from the directory path
    - `region`: from the directory path
    - `partition`: from the parent directory name
    - `session_name`: from `AWS_ROLE_SESSION_NAME` environment variable
    - `default_tags`: generated tags including state paths

Verify the merge logic in `tardigrade/stacks/<partition>/terragrunt-root.hcl`.

## Generated Files

Terragrunt generates these files in each unit directory. Never edit them directly:

- `backend.tf` — S3 backend configuration
- `providers.tf` — AWS provider configuration (copied from `stacks/<partition>/providers.tf`)
- `versions.tf` — Terraform and provider version constraints (copied from `vendor/versions.tf`)
- `.terraform.lock.hcl` — Provider lock file (copied from `vendor/.terraform.lock.hcl`)

If you need to change these files, edit the source file in `stacks/<partition>/` or `vendor/`, then rerun `terragrunt init` in the unit.

## State Key Paths

The Terraform state key for each unit is derived from `path_relative_to_include()`, which is the path from the partition directory to the unit. For example:

-   Unit: `tardigrade/stacks/aws/123456789012/us-east-1/member/`
-   State key: `tfstate/123456789012/us-east-1/member/terraform.tfstate`

Never change the state key expression in `terragrunt-root.hcl` without a human-approved migration plan. Moving or renaming a unit directory changes its state key and requires a state migration.

## Safety Rules

- Never run `apply`, `destroy`, `import`, or `state` commands, or `aws organizations create-account`/`close-account`. Prepare them for a person to run.
- Renaming or moving a unit path requires a state migration plan approved by a human.
- Never edit generated files in unit directories.
