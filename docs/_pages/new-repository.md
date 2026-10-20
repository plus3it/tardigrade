---
title: "Creating a New Repository"
permalink: /new-repository/
toc: true
---

# Overview

Creating a new tardigrade deployment repository involves setting up the repository structure, configuring placeholders for your environment, and initializing the backend infrastructure. The template ships an AWS account-baseline example; adapt it for other providers or deployment types following the guidance in the [Structure]({{ "/structure/#using-another-provider-or-deployment-type" | relative_url }}) guide.

# Choosing a Repository Host

## GitHub Template (Recommended)

If your deployment will be hosted on GitHub, use the tardigrade repository as a template:

1. Visit [https://github.com/plus3it/tardigrade](https://github.com/plus3it/tardigrade)
2. Click "Use this template" → "Create a new repository"
3. Choose your organization and repository name
4. Clone your new repository

New repositories use `main` as the default branch. The template's default branch is `master`, so rename the new repository's default branch to `main` (Settings → General → Default branch) before cloning it.

## GitLab or Other Hosts

For GitLab or other hosts:

1. Clone the tardigrade repository:
  ```bash
  git clone https://github.com/plus3it/tardigrade.git <your-repo-name>
  cd <your-repo-name>
  ```

2. Update the remote:
  ```bash
  git remote remove origin
  git remote add origin <your-repo-url>
  git branch -m master main
  ```

3. Remove GitHub-specific files (for non-GitHub hosts):
  ```bash
  rm -rf .github/
  rm .mergify.yml
  ```
  
  Dependabot and Mergify only work on GitHub. On other hosts, dependency updates use Renovate (a `renovate.json` at the repository root, run from the host's CI). Set up CI/CD per the Repository-specific → CI/CD section in `AGENTS.md`.

4. Push to your new repository:
  ```bash
  git push -u origin main
  ```

  Push `main` first so it becomes the default branch, and confirm the host's default branch setting is `main`.

# Repository Initialization (for the AWS example)

The `make init/repo` target substitutes placeholders in the tardigrade template and creates partition directories. Note: these variables are specific to the AWS account-baseline example shipped with the template.

## Required Variables

Set these environment variables before running `make init/repo`:

- `REPO_NAME` — Repository name (used for S3 bucket and DynamoDB table names in AWS)
- `REPO_URL` — Web URL of the repository (any host)
- `GLOBAL_REGION` — AWS region for global resources (e.g., `us-east-1`)
- `MANAGEMENT_ACCOUNT_ID` — AWS account ID for the management/organization account
- `BACKEND_ROLE_NAME` — IAM role name for backend state access

## Optional Variables

- `PARTITIONS` — Space-separated list of partitions (default: `aws`). For AWS GovCloud: `PARTITIONS="aws aws-us-gov"`. For China: `PARTITIONS="aws aws-cn"`. For other clouds, use the cloud name (e.g., `gcp`, `azure`).

## Running Initialization

```bash
export REPO_NAME="acme-tardigrade"
export REPO_URL="https://github.com/acme/acme-tardigrade"
export GLOBAL_REGION="us-east-1"
export MANAGEMENT_ACCOUNT_ID="111111111111"
export BACKEND_ROLE_NAME="TerraformBackend"

# Optional: add partitions
export PARTITIONS="aws aws-us-gov"

make init/repo
```

This command:
1. Replaces all `{{placeholder}}` values in files under `tardigrade/`
2. Creates `stacks/<partition>` directories for each partition (copies `stacks/aws` for additional partitions)

# State Backend Prerequisites (for the AWS example)

Before running `terragrunt init` in any unit, ensure the backend infrastructure exists. For the AWS example:

1. **S3 bucket** — Named `<REPO_NAME>-tfstate`, with versioning enabled
2. **DynamoDB table** — Named `<REPO_NAME>-tfstate-lock`, with `LockID` as the partition key (string type)
3. **IAM role** — Named `<BACKEND_ROLE_NAME>` in the management account, with permissions to:
    - Read/write to the S3 bucket
    - Read/write to the DynamoDB table
    - Assume the role from your deployment accounts

For GCP or other clouds, replace with the appropriate backend (e.g., GCS bucket for GCP).

Terragrunt does not create these implicitly. Either create them yourself, or have a person with management-account credentials run `terragrunt backend bootstrap --working-dir <unit>`, which creates the bucket and lock table from the `remote_state` block in `terragrunt-root.hcl`. See [NEW_REPO.md](https://github.com/plus3it/tardigrade/blob/master/NEW_REPO.md).

# Versioning and Release Automation

Deployments are typically not released or versioned. The NEW_REPO.md procedure removes `.bumpversion.cfg` and `.github/workflows/release.yml` by default. If the team wants to version the deployment, keep those files, set an initial version in `.bumpversion.cfg`, and update `CHANGELOG.md` following [Keep a Changelog](http://keepachangelog.com/) format.

# Choosing a Global Region (for the AWS example)

The global region hosts resources that are region-independent or must exist in a specific region. In the AWS example:

- IAM resources (region-agnostic but must be deployed somewhere)
- CloudTrail (often deployed to a single region)
- S3 buckets for logs and artifacts

Choose a region based on:
- Your primary operational region
- Compliance requirements (GovCloud deployments typically use `us-gov-west-1`)
- Cost considerations

For deployments on other clouds, the concept of a "global region" may be handled differently (e.g., a `_global/` directory for GCP).

# CI/CD Choices

CI/CD is a per-deployment choice. Common patterns include:

- **GitLab CI with Gruntwork Pipelines** — Fully automated plan/apply pipeline
- **Spacelift** — Managed Terraform platform with drift detection and policy enforcement
- **GitLab CI with job matrix** — Generated pipeline jobs for each unit

A first-class CI/CD offering for GitHub and GitLab is planned. See [CI/CD]({{ "/ci-cd/" | relative_url }}).

Document your CI/CD setup in your repository's `AGENTS.md` file under "Repository-specific → CI/CD".

# Step-by-Step Procedure

For detailed step-by-step instructions, see [NEW_REPO.md](https://github.com/plus3it/tardigrade/blob/master/NEW_REPO.md) in the tardigrade repository. That file includes a checklist and is automatically deleted after you complete the setup.
