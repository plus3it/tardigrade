---
title: "How-To Guide"
permalink: /how-to-guide/
toc: true
---

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

# Modify the Baseline
Currently, there is a simple implementation located in `tardigrade/roots/aws/baseline` that stitches together several of Plus3 IT's terraform modules. This baseline is what's deployed to the account. You can edit the baseline to add/remove modules as you see fit.
