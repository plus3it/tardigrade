# Roots: Adding Terraform Root Modules

This file describes how to add a new Terraform root module to tardigrade.

## What is a Root

A root is a Terraform root module in `tardigrade/roots/<root>/` that composes vendored and local modules into a deployable configuration. Roots are partition-agnostic; they work across AWS commercial, GovCloud, and other partitions.

Units (the Terragrunt configurations in `stacks/<partition>/<account_id>/<region>/<root>/`) deploy roots to specific accounts and regions.

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

### 3. Define the Variables Contract

Roots receive inputs from Terragrunt's merged YAML configuration and computed values. Common inputs provided by `terragrunt-root.hcl`:

- `account_id` (string) — AWS account ID, extracted from the unit path
- `region` (string) — AWS region, extracted from the unit path
- `partition` (string) — AWS partition (`aws`, `aws-us-gov`, etc.), from the parent directory name
- `session_name` (string, nullable) — From `AWS_ROLE_SESSION_NAME` environment variable
- `default_tags` (map of strings) — Generated tags including repository info and state paths

Additionally, roots receive all keys from the merged YAML files:
- `globals.tfvars.yaml`
- `<root>.tfvars.yaml` (if exists)
- `account.tfvars.yaml`

Define variables for any YAML keys the root expects. For example, if `account.tfvars.yaml` contains `account_name` and `email_address`, declare those variables in `variables.tf`.

#### Where to Put Values

- **Deployment-wide values** (set once for the entire deployment): `tardigrade/stacks/<partition>/<root>.tfvars.yaml` (verified: `terragrunt-root.hcl` loads this file)
- **Per-account values** (different for each account): `tardigrade/stacks/<partition>/<account_id>/account.tfvars.yaml`

### 4. Reference Modules

Reference vendored modules using relative paths from the root to `vendor/.terraform/modules/<label>`:

```hcl
module "example" {
  source = "../../vendor/.terraform/modules/<label>"
  
  # inputs
}
```

For modules with submodules (e.g., `cloudtrail//modules/s3-bucket`), the vendored path becomes:

```hcl
module "example_submodule" {
  source = "../../vendor/.terraform/modules/<label>/modules/<submodule>"
}
```

Check `vendor/main.tf` for the module label and `vendor/.terraform/modules/modules.json` (after running `make terraform/vendor`) to verify submodule paths.

Reference local modules using relative paths:

```hcl
module "local_example" {
  source = "../../modules/<name>"
}
```

### 5. Provider Configuration

Do not create a `providers.tf` file in the root. Provider configuration comes from `stacks/<partition>/providers.tf` and is generated into each unit by Terragrunt.

The standard provider configuration includes:
- `aws` (default provider) — Assumes role in the target account
- `aws.management` (alias) — Assumes role in the management account

If the root needs additional providers or provider aliases, document them in a comment at the top of `main.tf`.

### 6. Validate the Root

```bash
make terraform/vendor  # Ensure modules are vendored
terraform -chdir=tardigrade/roots/<root> init -backend=false
terraform -chdir=tardigrade/roots/<root> validate
```

### 7. Create Matching Templates

For each root, create matching templates so new stacks can deploy the root easily:

```bash
mkdir -p tardigrade/templates/<type>/global/<root>
mkdir -p tardigrade/templates/<type>/regional/<root>
```

See [tardigrade/templates/AGENTS.md](../templates/AGENTS.md) for template conventions.

### 8. Report Affected Units

A change to a root affects every unit that uses it. In your final report, list the affected units for a person or CI to plan. Find them with:

```bash
find tardigrade/stacks -path '*/<root>/terragrunt.hcl'
```

## Example Root Structure

```
tardigrade/roots/member/
├── main.tf         # Module calls (cloudtrail, config, guardduty, etc.)
├── variables.tf    # account_name, email_address, cloudtrail_bucket, etc.
├── outputs.tf      # Exported values for other roots
└── locals.tf       # Local computed values (namespace, partition, etc.)
```

## Partition Considerations

Roots must work across partitions (commercial AWS, GovCloud, China). Use the `partition` input to construct ARNs dynamically:

```hcl
arn:${var.partition}:service:region:account:resource
```

Never hardcode `arn:aws:` in roots.
