---
title: "Welcome to Tardigrade"
permalink: /
sidebar:
  nav: "docs"
---

# Overview
Tardigrade is a mutlicloud account provisioning and maintenance framework built with terragrunt and terraform. Currently, this implementation demonstrates the ability to manage AWS accounts, but can easily be extended to manage accounts on other cloud platforms.

# Prerequisites
* [terraform >= 0.12](https://www.terraform.io/)
  - credentials configured for an AWS account
* [terragrunt >= v0.21](https://github.com/gruntwork-io/terragrunt)

# How To Use
You can use the following instructions to see the baseline infrastructure deployed to your account

```
terragrunt plan --terragrunt-working-dir tardigrade/aws/609421024627/base --terragrunt-source-update
```

Note: Even though the account is noted as `609421024627`, terraform will deploy to the account it's configured for
{: .notice--info}

# Terraform Modules
As part of creating a baseline configuration for cloud accounts we have created over 20 terraform modules. Each module pertains to a particular service and has been published to the [Terraform Registry](https://registry.terraform.io/search?q=tardigrade). You can also find our modules on [GitHub](https://github.com/search?q=org%3Aplus3it+tardigrade)
