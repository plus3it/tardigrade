---
title: "Structure"
permalink: /structure/
toc: true
---

# File Structure
```
tardigrade/
├── aws                                    # AWS partition
│   ├── 609421024627                       # idempotent element to describe the account
│   │   ├── base                           # baseline configuration
│   │   │   ├── tenant-local.auto.tfvars   # defined variables valuables specific to the account
│   │   │   ├── terragrunt.hcl             # terragrunt configuration for the account
│   │   └── custom                         # custom configuration
│   │       ├── terragrunt.hcl             # terragrunt configuration for the account
│   │       └── variables.tf               # variable declaration specific to the customization
│   ├── tenant.tf                          # partition provider and variable declarations
│   ├── tenant-global.tfvars.yaml          # partition variable values
│   └── terragrunt.hcl                     # terragrunt configuration
└── roots                                  # root module for terraform
    └── aws
        └── baseline                       # baseline configuration for an AWS account
```

## Partition
In this example, the partition is aws (i.e., `tardigrade/aws`). Generally speaking, most AWS implementations of tardigrade  will only use the `aws` partition. The `aws` partition is the commercial partition that most people are used to. There are other partitions though, such as AWS GovCloud (`aws-us-gov`) and AWS China (`aws-cn`)

### Idempotent Element
Each directory at this level (e.g., `tardigrade/aws/<accounts>`) represents an individual account. For AWS, the account number is an idempotent value so we used that to represent individual accounts. The names of these directories do not influence the operation of this framework in any way. They simply serve as a mechanism for developers to easily identify the account.

Each directory at this level represents an individual account. Account level configurations are stored here and are applied within the context of the target account. Specific elements of the account level configuration are described below.

#### Base
This directory has the following files
```
base
├── tenant-local.auto.tfvars # defines tenant specific variables
└── terragrunt.hcl           # terragrunt configuration
```

#### Custom
This directory is meant to allow you to add in custom elements that a tenant would like included in their account but are outside of the general baseline created for each account.

## roots/aws/baseline
This directory contains the terraform code that ties together the various terraform modules to constitute an infrastructure baseline to be deployed to every account.
