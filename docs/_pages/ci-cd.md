---
title: "CI/CD"
permalink: /ci-cd/
toc: true
---

# Overview

CI/CD for tardigrade deployments is currently a per-deployment choice. Each deployment repository documents its CI/CD setup in `AGENTS.md` under "Repository-specific → CI/CD".

This page describes common patterns in use as examples. These are not officially supported features but reflect real-world implementations.

# Common Patterns

## GitLab CI with Gruntwork Pipelines

Some deployments use Gruntwork Pipelines for automated Terragrunt workflows:

- Plan on every merge request
- Apply on merge to the default branch
- Drift detection on a schedule
- Unit-level or root-level parallelization

## Spacelift

Spacelift provides a managed Terraform/Terragrunt platform:

- Automatically detects changes to Spacelift stacks
- Supports drift detection and policy enforcement
- Integrates with VCS for plan/apply workflows
- Provides a web UI for reviewing plans and applying changes

## GitLab CI with Job Matrix

Some deployments generate GitLab CI jobs dynamically:

- A script generates job definitions for each unit
- Jobs run in parallel (subject to GitLab runner limits)
- Each job runs `terragrunt plan` or `terragrunt apply` for a single unit

# Security Considerations

When configuring CI/CD for tardigrade:

1. **Credentials should be plan-only** — Agents and automated pipelines should have read-only access sufficient for `terragrunt plan`. Applies should require human approval or separate credentials.

2. **Use OIDC for authentication** — Avoid long-lived credentials. Use OIDC/federation where possible (GitHub Actions OIDC, GitLab CI OIDC, Spacelift OIDC).

3. **Separate plan and apply permissions** — Use a read-only role for plans and a separate role, limited to the deploy branch, for applies.

4. **State backend access** — Ensure the backend IAM role has appropriate permissions for your CI system to assume.

# Documenting Your CI/CD

Document your deployment's CI/CD setup in your repository's `AGENTS.md` file under "Repository-specific → CI/CD". Include:

- What triggers plans and applies
- Authentication mechanism (OIDC, IAM role, etc.)
- Where to view pipeline status
- How to manually trigger pipelines if needed

If your deployment doesn't use CI/CD yet, note that in the AGENTS.md file. Agents should ask before assuming a CI/CD setup.

# Future Plans

A first-class CI/CD offering for both GitHub and GitLab is planned. Until it exists, choose and document CI/CD per deployment.
