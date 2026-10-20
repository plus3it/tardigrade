---
title: "Welcome to Tardigrade"
permalink: /
sidebar:
  nav: "docs"
---

# Overview
Tardigrade is a repository structure and conventions for Terragrunt + Terraform deployments that works with any Terraform provider. It's used for whole-account baselines (most often AWS) and for single-application deployments (for example, on GCP).

The framework provides a layered structure for managing infrastructure deployments across multiple scopes, regions, and partitions. This template ships an AWS account-baseline example (management and member roots) that demonstrates managing multiple AWS accounts across partitions (commercial, GovCloud, China).

# Prerequisites

Tool versions are pinned in `.mise.toml`. Install [mise](https://mise.jdx.dev/) to ensure you're using the correct versions:

```bash
mise install
```

You'll also need AWS credentials configured through the standard AWS credential chain (AWS_PROFILE, environment variables, or CI OIDC).

# Terraform Modules
As part of creating a baseline configuration for cloud accounts we have created
over 20 terraform modules. Each module pertains to a particular service and has
been published to the [Terraform Registry](https://registry.terraform.io/search?q=tardigrade).
You can also find our modules on [GitHub](https://github.com/search?q=org%3Aplus3it+tardigrade).
