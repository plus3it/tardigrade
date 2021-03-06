---
title: "Structure"
permalink: /structure/
toc: true
---

# File Structure
```
tardigrade/
├── configs                                # Container for terragrunt configs
│   └── aws                                # AWS partition
│       ├── {management_account_id}        # Idempotent identifier for management account configurations
│       │   └── management                 # Baseline teragrunt configuration for management account
│       └── {member_account_id...}         # Idempotent identifier for member account configurations
│           └── member                     # Baseline terragrunt configuration for management account
├── roots                                  # Container for terraform root modules
│   └── aws                                # AWS partition
│       ├── management                     # Management root module
│       │   └── policy_templates           # Container for policy templates used by management config
│       └── member                         # Member root module
└── templates                              # Container for terragrunt template configs
    └── aws                                # AWS partition
        ├── member                         # Terragrunt config template for member accounts
        └── management                     # Terragrunt config template for management accounts
```

## Partition
In this example, the partition is aws (i.e., `tardigrade/configs/aws`). Generally
speaking, most AWS implementations of tardigrade will only use the `aws` partition.
The `aws` partition is the commercial partition that most people are familiar with.
There are other partitions though, such as AWS GovCloud (`aws-us-gov`) and AWS China
(`aws-cn`)

### Idempotent Element
Each directory at this level (e.g., `tardigrade/configs/aws/{accounts...}`) represents
an individual account. For AWS, the account number is an idempotent value so we
used that to represent individual accounts. The names of these directories do not
influence the operation of this framework in any way. They simply serve as a mechanism
for developers to easily identify the account.

Each directory at this level represents an individual account. Account level configurations
are stored here and are applied within the context of the target account. Specific
elements of the account level configuration are described below.

#### Baseline
This directory has the following files:

```
base
├── terraform.tfvars         # defines config-specific variables
└── terragrunt.hcl           # terragrunt configuration
```

## roots/aws/<baseline>
This directory contains the terraform modules that tie together the various terraform
components to comprise an infrastructure baseline to be deployed to every account
of a given type.

## templates/aws/<template>
This directory contains template terragrunt configs that can be copied into the
`configs/aws/{account}` directory to quickly instantiate a new account.
