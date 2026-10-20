# Creating a New Deployment Repository

This document describes how to create a new tardigrade deployment repository from the plus3it/tardigrade template. The template ships an AWS account-baseline example; adapt it for other providers or deployment types following the guidance in [docs/_pages/structure.md](https://plus3it.github.io/tardigrade/structure/#using-another-provider-or-deployment-type).

## Prerequisites (for the AWS example)

- AWS management account with appropriate permissions
- S3 bucket and DynamoDB table for Terraform state (see State Backend Prerequisites below)
- IAM role for Terraform backend access in the management account

## Option A: GitHub (Recommended)

### 1. Use This Template

Click the green "Use this template" button on the plus3it/tardigrade repository page, or visit:
https://github.com/plus3it/tardigrade/generate

Select the repository owner, give it a name (e.g., `acme-tardigrade`), enter a description, select Public or Private, and click "Create repository from template".

New repositories use `main` as the default branch. The template's default branch is `master`, so the new repository starts with `master`. Rename it before cloning: in the new repository, go to Settings → General → Default branch, rename `master` to `main` (or run `gh api -X POST repos/<owner>/<repo>/branches/master/rename -f new_name=main`).

### 2. Clone and Create a Branch

```bash
git clone <your-new-repo-url>
cd <repo-name>
git checkout -b initial-setup
```

### 3. Configure Repository Settings (a person does this)

A person with repository admin access should follow the checklist from the [repo-template README](https://github.com/plus3it/repo-template#readme):

- **GENERAL**
  - **Features**: Turn off Wikis, Sponsorships, Discussions, and Projects
  - **Pull Requests**: Turn off Squash Merging and Rebase Merging; turn on Allow Auto-Merge and Automatically delete head branches
  - **Pushes**: Limit how many branches can be updated in a single push: 2
- **COLLABORATORS and TEAMS**
  - **Manage Access**: Add relevant team roles (e.g., `tardigrade-admins` Admin, `terraform` Write, `releasebot` Write)
- **Branches**
  - **Create Branch Protection rule** for `main`:
    - Turn on Require pull request before merging
    - Turn on Require approvals
    - Turn on Dismiss stale pull requests
  - **Required Status Checks**: Add checks like `lint/tardigradelint`, etc.
    - Turn on Do not allow bypassing the above settings
- **README**: Replace README.md with deployment-specific content

## Option B: GitLab or Other Hosts

### 1. Clone the Template

```bash
git clone https://github.com/plus3it/tardigrade.git <repo-name>
cd <repo-name>
```

### 2. Set New Remote

```bash
git remote set-url origin <your-new-repo-url>
git branch -m master main  # New repositories use main as the default branch
git checkout -b initial-setup
```

### 3. Remove GitHub-specific Files

For hosts other than GitHub, remove files that only work on GitHub:

```bash
rm -rf .github/
rm .mergify.yml
```

Dependabot and Mergify only work on GitHub. On other hosts, dependency updates use Renovate: add a `renovate.json` at the repository root and run Renovate from the host's CI. Record the setup in AGENTS.md under Repository-specific → CI/CD.

### 4. Push to New Remote (a person does this)

```bash
git push -u origin main  # Push main first so it becomes the default branch
git push -u origin initial-setup
```

## Customize the Repository (for the AWS example)

### 1. Run make init/repo

This substitutes placeholders and creates partition directories. Provide all required variables. Note: these variables are specific to the AWS account-baseline example shipped with the template.

```bash
make init/repo \
  REPO_NAME=<repo-name> \
  REPO_URL=<repo-web-url> \
  GLOBAL_REGION=<primary-region> \
  MANAGEMENT_ACCOUNT_ID=<12-digit-account-id> \
  BACKEND_ROLE_NAME=<role-name> \
  PARTITIONS="<space-separated-partitions>"
```

**Variables:**
- `REPO_NAME`: Repository name (e.g., `acme-tardigrade`)
- `REPO_URL`: Web URL (e.g., `https://github.com/acme/acme-tardigrade` or `https://gitlab.com/acme/acme-tardigrade`)
- `GLOBAL_REGION`: Primary region for the default partition (e.g., `us-east-1` for `aws`, `us-gov-west-1` for `aws-us-gov`)
- `MANAGEMENT_ACCOUNT_ID`: 12-digit AWS account ID of your management account
- `BACKEND_ROLE_NAME`: IAM role name for Terraform backend access (e.g., `TerraformStateRole`)
- `PARTITIONS`: Space-separated partition list (e.g., `"aws"` or `"aws aws-us-gov"`). The `aws` partition already exists; additional partitions are created by copying `stacks/aws/`.

**Example:**

```bash
make init/repo \
  REPO_NAME=acme-tardigrade \
  REPO_URL=https://github.com/acme/acme-tardigrade \
  GLOBAL_REGION=us-east-1 \
  MANAGEMENT_ACCOUNT_ID=123456789012 \
  BACKEND_ROLE_NAME=TerraformStateRole \
  PARTITIONS="aws"
```

For GovCloud and commercial AWS:

```bash
make init/repo \
  REPO_NAME=acme-tardigrade \
  REPO_URL=https://github.com/acme/acme-tardigrade \
  GLOBAL_REGION=us-east-1 \
  MANAGEMENT_ACCOUNT_ID=123456789012 \
  BACKEND_ROLE_NAME=TerraformStateRole \
  PARTITIONS="aws aws-us-gov"
```

Note: `GLOBAL_REGION` and `MANAGEMENT_ACCOUNT_ID` substitute placeholders in the `aws` partition. After `make init/repo` copies `stacks/aws/` to `stacks/aws-us-gov/`, manually edit the copied partition:

1. In `stacks/aws-us-gov/terragrunt-root.hcl`, change `global_region` from `us-east-1` to `us-gov-west-1`
2. In `stacks/aws-us-gov/terragrunt-root.hcl`, update the `role_arn` account ID in `remote_state.config.assume_role`. The GovCloud management account ID always differs from the commercial management account ID.
3. In `stacks/aws-us-gov/globals.tfvars.yaml`, update `management_account_id` and any other partition-specific values
4. Templates hold the commercial management account ID and global-region directory. Units copied from templates into another partition need both the management account ID and region updated in dependency paths. Dependencies are never cross-partition.

Repeat similar edits for `aws-cn` or other partitions.

### 2. Delete Documentation and Template Maintenance Section

The `docs/` directory and the "Maintaining the tardigrade template" section in `AGENTS.md` apply only to the plus3it/tardigrade template repository. Remove them from deployment repositories:

```bash
rm -rf docs/
```

Edit `AGENTS.md` and delete the entire "Maintaining the tardigrade template (plus3it/tardigrade only)" section (from the heading to the end of the file).

Replace `README.md` with your deployment-specific content describing the repository's purpose, accounts, and credentials.

### 3. Reset Changelog and Release Automation

Deployments are typically not released. Remove versioning and release automation files:

```bash
rm -f .bumpversion.cfg .github/workflows/release.yml
```

Replace `CHANGELOG.md` with a fresh file containing a single initial entry:

```bash
cat > CHANGELOG.md <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

- Initial tardigrade deployment setup
EOF
```

If the team wants to version this deployment, keep `.bumpversion.cfg` and `.github/workflows/release.yml`, set the initial version in `.bumpversion.cfg`, and update `CHANGELOG.md` following [Keep a Changelog](http://keepachangelog.com/) format.

### 4. Configure CI/CD

If using GitLab, Bitbucket, or another host, set up CI/CD per the Repository-specific → CI/CD section in `AGENTS.md`. GitHub Actions workflows in `.github/workflows/` are already configured if you kept those files.

### 5. Edit Repository-specific Sections

Edit `AGENTS.md` and fill in the "Repository-specific" section:

- **Purpose**: Describe what this deployment manages (e.g., "Manages AWS account baselines for ACME Corp's commercial and GovCloud environments")
- **Accounts and Partitions**: List the partitions, accounts, and their purposes
- **Credentials**: Describe how to authenticate for local operations (e.g., AWS profile, aws-vault, OIDC)
- **CI/CD**: Describe how plan/apply run (GitHub Actions, GitLab CI, Spacelift, etc.). If you don't have CI/CD set up yet, state that explicitly.

### 6. Create State Backend Prerequisites

Terraform state requires an S3 bucket and DynamoDB table in the management account. The bucket and table names are derived from `REPO_NAME`:

- S3 bucket: `<repo-name>-tfstate`
- DynamoDB table: `<repo-name>-tfstate-lock`

You have two options:

**Option 1: Create Manually**

A person with appropriate AWS permissions should create the S3 bucket and DynamoDB table. Example AWS CLI commands (omit `--create-bucket-configuration` for `us-east-1`):

```bash
aws s3api create-bucket \
  --bucket <repo-name>-tfstate \
  --region <global-region> \
  --create-bucket-configuration LocationConstraint=<global-region>  # Omit this line for us-east-1

aws s3api put-bucket-versioning \
  --bucket <repo-name>-tfstate \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket <repo-name>-tfstate \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name <repo-name>-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region <global-region>
```

**Option 2: Terragrunt backend bootstrap**

Terragrunt does not create the backend implicitly. A person with credentials for the management account runs, from the first unit:

```bash
terragrunt backend bootstrap --working-dir tardigrade/stacks/<partition>/<scope_id>/<region>/<root>
```

This creates the bucket and lock table from the `remote_state` block in `terragrunt-root.hcl`, including its encryption and tags. Agents prepare this command; they do not run it.

### 7. Add the First Stacks

Follow the instructions in [tardigrade/stacks/AGENTS.md](tardigrade/stacks/AGENTS.md) to onboard your first AWS accounts.

Typically, start with the management account:

```bash
cp tardigrade/templates/management/account.tfvars.yaml \
    tardigrade/stacks/aws/<management-account-id>/account.tfvars.yaml

cp -r tardigrade/templates/management/global/management \
    tardigrade/stacks/aws/<management-account-id>/<global-region>/management
```

Edit the YAML and Terragrunt files to replace any remaining placeholders and fill in account-specific values.

### 8. Validate

```bash
make terraform/vendor
make lint
make terraform/validate-roots
```

### 9. Commit and Open a PR (a person does this)

```bash
git rm NEW_REPO.md  # This file is only used once, during repository creation
git add -A
git status  # Review staged files for anything sensitive
git commit -m "Initial tardigrade deployment setup"
git push -u origin initial-setup
```

Open a pull request for review.
