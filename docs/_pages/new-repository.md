---
title: "Creating a New Repository"
permalink: /new-repository/
toc: true
---

# Overview

Creating a new tardigrade deployment repository involves setting up the repository structure, configuring placeholders for your environment, and initializing the backend infrastructure.

# Choosing a Repository Host

## GitHub Template (Recommended)

If your deployment will be hosted on GitHub, use the tardigrade repository as a template:

1. Visit [https://github.com/plus3it/tardigrade](https://github.com/plus3it/tardigrade)
2. Click "Use this template" → "Create a new repository"
3. Choose your organization and repository name
4. Clone your new repository

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
  ```

3. Push to your new repository:
  ```bash
  git push -u origin master
  ```

# Repository Initialization

The `make init/repo` target substitutes placeholders in the tardigrade template and creates partition directories.

## Required Variables

Set these environment variables before running `make init/repo`:

- `REPO_NAME` — Repository name (used for S3 bucket and DynamoDB table names)
- `REPO_URL` — Web URL of the repository (any host)
- `GLOBAL_REGION` — AWS region for global resources (e.g., `us-east-1`)
- `MANAGEMENT_ACCOUNT_ID` — AWS account ID for the management/organization account
- `BACKEND_ROLE_NAME` — IAM role name for backend state access

## Optional Variables

- `PARTITIONS` — Space-separated list of AWS partitions (default: `aws`). For GovCloud: `PARTITIONS="aws aws-us-gov"`. For China: `PARTITIONS="aws aws-cn"`.

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

# State Backend Prerequisites

Before running `terragrunt init` in any unit, ensure the backend infrastructure exists:

1. **S3 bucket** — Named `<REPO_NAME>-tfstate`, with versioning enabled
2. **DynamoDB table** — Named `<REPO_NAME>-tfstate-lock`, with `LockID` as the partition key (string type)
3. **IAM role** — Named `<BACKEND_ROLE_NAME>` in the management account, with permissions to:
    - Read/write to the S3 bucket
    - Read/write to the DynamoDB table
    - Assume the role from your deployment accounts

Terragrunt does not create these implicitly. Either create them yourself, or have a person with management-account credentials run `terragrunt backend bootstrap --working-dir <unit>`, which creates the bucket and lock table from the `remote_state` block in `terragrunt-root.hcl`. See [NEW_REPO.md](https://github.com/plus3it/tardigrade/blob/master/NEW_REPO.md).

# Choosing a Global Region

The global region hosts resources that are region-independent or must exist in a specific region:

- IAM resources (region-agnostic but must be deployed somewhere)
- CloudTrail (often deployed to a single region)
- S3 buckets for logs and artifacts

Choose a region based on:
- Your primary operational region
- Compliance requirements (GovCloud deployments typically use `us-gov-west-1`)
- Cost considerations

# CI/CD Choices

CI/CD is a per-deployment choice. Common patterns include:

- **GitLab CI with Gruntwork Pipelines** — Fully automated plan/apply pipeline
- **Spacelift** — Managed Terraform platform with drift detection and policy enforcement
- **GitLab CI with job matrix** — Generated pipeline jobs for each unit

A first-class CI/CD offering for GitHub and GitLab is planned. See [CI/CD]({{ "/ci-cd/" | relative_url }}).

Document your CI/CD setup in your repository's `AGENTS.md` file under "Repository-specific → CI/CD".

# Step-by-Step Procedure

For detailed step-by-step instructions, see [NEW_REPO.md](https://github.com/plus3it/tardigrade/blob/master/NEW_REPO.md) in the tardigrade repository. That file includes a checklist and is automatically deleted after you complete the setup.
