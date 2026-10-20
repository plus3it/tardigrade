---
title: "Welcome to Tardigrade"
permalink: /
sidebar:
  nav: "docs"
---

# Overview
Tardigrade is a multi-cloud account provisioning and maintenance framework built
with Terragrunt and Terraform. Currently, this implementation demonstrates the
ability to manage AWS accounts, but can easily be extended to manage accounts on
other cloud platforms.

The framework provides a layered structure for managing infrastructure deployments
across multiple accounts, regions, and AWS partitions (commercial, GovCloud, China).

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
