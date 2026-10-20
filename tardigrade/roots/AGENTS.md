# Roots: Adding Terraform Root Modules

This file describes how to add a new Terraform root module to tardigrade.

## What is a Root

A root is a Terraform root module in `tardigrade/roots/<root>/` that composes vendored and local modules into a deployable configuration. Roots are partition-agnostic; they work across partitions (e.g., AWS commercial, GovCloud, or GCP).

Units (the Terragrunt configurations in `stacks/<partition>/<scope_id>/<region>/<root>/`) deploy roots to specific scopes and regions.

## Add a Root

### 1. Create the Root Directory

```bash
mkdir -p tardigrade/roots/<root>
```

### 2. Create Root Files

A root typically contains:

- `main.tf` — Module calls and resources
- `variables.tf` — Input variables
- `outputs.tf` — Outputs (optional)
- `locals.tf` — Local values (optional)
- `.tardigrade.config.yaml` — Dependency globs for change detection (required)

### 3. Define the Variables Contract

Roots receive inputs from Terragrunt's merged YAML configuration and computed values. In the AWS example, common inputs provided by `terragrunt-root.hcl`:

- `account_id` (string) — AWS account ID, extracted from the unit path
- `region` (string) — AWS region, extracted from the unit path
- `partition` (string) — AWS partition (`aws`, `aws-us-gov`, etc.), from the parent directory name
- `session_name` (string, nullable) — From `AWS_ROLE_SESSION_NAME` environment variable
- `default_tags` (map of strings) — Generated tags including repository info and state paths

For other providers, the scope ID variable name and computed values will differ based on the implementation in `terragrunt-root.hcl`.

Additionally, roots receive all keys from the merged YAML files:
- `globals.tfvars.yaml`
- `<root>.tfvars.yaml` (if exists)
- Scope-level YAML (e.g., `account.tfvars.yaml` for AWS)

Define variables for any YAML keys the root expects. For the AWS example, if `account.tfvars.yaml` contains `account_name` and `email_address`, declare those variables in `variables.tf`.

#### Where to Put Values

- **Deployment-wide values** (set once for the entire deployment): `tardigrade/stacks/<partition>/<root>.tfvars.yaml` (verified: `terragrunt-root.hcl` loads this file)
- **Per-scope values** (different for each scope): `tardigrade/stacks/<partition>/<scope_id>/account.tfvars.yaml` (or equivalent scope-level YAML)

### 4. Reference Modules

Reference vendored modules using relative paths from the root to `vendor/.terraform/modules/<label>.this`:

```hcl
module "example" {
  source = "../../vendor/.terraform/modules/<label>.this"
  
  # inputs
}
```

For modules with submodules, the vendored path becomes:

```hcl
module "example_submodule" {
  source = "../../vendor/.terraform/modules/<label>.this/modules/<submodule>"
}
```

Check `vendor/<label>/main.tf` for the `module "this"` source and `vendor/main.tf` for the module label entry. After running `make terraform/vendor`, inspect `vendor/.terraform/modules/modules.json` to verify the exact Dir path for submodules.

Reference local modules using relative paths:

```hcl
module "local_example" {
  source = "../../modules/<name>"
}
```

### 5. Provider Configuration

Do not create a `providers.tf` file in the root. Provider configuration comes from `stacks/<partition>/providers.tf` and is generated into each unit by Terragrunt.

In the AWS example, the standard provider configuration includes:
- `aws` (default provider) — Assumes role in the target account
- `aws.management` (alias) — Assumes role in the management account

For other providers, the configuration will differ (e.g., `google` provider for GCP).

If the root needs additional providers or provider aliases, document them in a comment at the top of `main.tf`.

### 6. Create the Dependency Globs File

Create `tardigrade/roots/<root>/.tardigrade.config.yaml` listing all dependencies the root uses. Paths are relative to `tardigrade/`:

```yaml
dependency_globs:
  - vendor/<label>/**
  - modules/<name>/**
  # Add other files or directories the root depends on
```

Include:
- `vendor/<label>/**` for each vendored module the root uses
- `modules/<name>/**` for each local module the root uses
- Any data files or other resources under `tardigrade/` that the root depends on

This file enables change detection: when files matching these globs change, Terragrunt knows which units need replanning. See [tardigrade/vendor/AGENTS.md](../vendor/AGENTS.md) for details on how this affects module upgrades.

### 7. Validate the Root

```bash
make terraform/vendor         # Ensure modules are vendored
make terraform/validate-roots # Validates all roots against vendored modules
```

### 8. Create Matching Templates

For each root, create matching templates so new stacks can deploy the root easily:

```bash
mkdir -p tardigrade/templates/<type>/global/<root>
mkdir -p tardigrade/templates/<type>/regional/<root>
```

See [tardigrade/templates/AGENTS.md](../templates/AGENTS.md) for template conventions.

### 9. Report Affected Units

A change to a root affects every unit that uses it. In your final report, list the affected units for a person or CI to plan. Find them with:

```bash
find tardigrade/stacks -path '*/<root>/terragrunt.hcl'
```

## Maintaining Dependency Globs

Whenever a root starts or stops using a vendored module, local module, or other dependency, update its `.tardigrade.config.yaml` accordingly:

- **Adding a dependency:** Add the glob pattern to `dependency_globs`
- **Removing a dependency:** Remove the glob pattern from `dependency_globs`

Accurate dependency globs ensure that only affected units are replanned when dependencies change. This is especially important for CI/CD pipelines and large deployments.

## Example Root Structure

```
tardigrade/roots/member/
├── main.tf         # Module calls (cloudtrail, config, guardduty, etc.)
├── variables.tf    # account_name, email_address, cloudtrail_bucket, etc.
├── outputs.tf      # Exported values for other roots
└── locals.tf       # Local computed values (namespace, partition, etc.)
```

## Partition Considerations

Roots that work across partitions (e.g., AWS commercial, GovCloud, China) should use the `partition` input to construct ARNs dynamically:

```hcl
arn:${var.partition}:service:region:account:resource
```

For AWS roots, never hardcode `arn:aws:`; use the partition variable instead.
