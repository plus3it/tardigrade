---
title: "How-To Guide"
permalink: /how-to-guide/
toc: true
---

# Prerequisites
* [terraform >= 0.12](https://www.terraform.io/)
  - Note, the current `configs/versions.tf` is pinned to 0.14, but this can be updated by users themselves if they have code ready for a newer version. 
  - For root modules, we always recommend a strict pin on the terraform-core version. This pin is to prevent inadvertent upgrades of tfstate by different people working the same project. The pin is in the file configs/versions.tf. To use another version, just update the version in the file. All modules used ought to be compatible from 0.13 and later (when support for module-level for_each was added). It is expected that everything is compatible to 1.x.
* [terragrunt >= v0.21](https://github.com/gruntwork-io/terragrunt)
* (optional!) [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
  - used for authenticating to AWS during the quickstart example
  - Credentials configured for an AWS account


# Authentication
Users have multiple options for authentication to deploy their resources, basically whatever the Terraform providers support at the time! Generally, this falls into one of the following: Login/configure through a CLI tool (which sets $ENV variables that Terraform providers will then use), config file, or setting the account directly with vars in the provider (see the provider documentation for more deails). One example to take a close look at is the AWS provider documentation [found here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication). You'll see the the provider lists many options for providing authentication to Terraform for it to do its thing!

# How To Use (quickstart)
Note: this quickstart covers a very simple setup using AWS and the included templates. Once you have a feel for how the tool works and is deployed, you can further extend functionality however you'd like. Validate that you have all tools installed correctly. You can do this by typing `{tool} --version` into the comand line to validate the tool is in your PATH and the version is appropriate. Note that in some installation methods of terragrunt (namely, Brew) will attempt to install the latest version of Terraform with it. This can cause a dependency issue. You may have to manually uninstall undesired versions and add the correct ones to your PATH. 

After all tools are validated, you must use the AWS CLI to set your environment config for authentication. This generally involves creating programmatic access for a user account and setting it up with `aws configure`. [Instructions for configuring your CLI environment to the desired AWS account can be found here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html). Note, this is only a quickstart example to get the ball rolling -  mature environments may choose to use an SSO service for authentication to avoid tying IAM Users (and programmatic access keys) to individuals. 

If you have not already, `git clone https://github.com/plus3it/tardigrade.git <project-name>`. It's important to make the `<project-name>` something somewhat unique, as this namespace is used to build the name of the backend tfstate S3 bucket. (You _can_ choose to edit the name of the bucket directly if you want, found in the `../configs/aws/terragrunt.hcl` => `remote_state` block.)

Next, you need to add a configuration into the environment you would like to deploy resources into. In the current state, we only support AWS and are currently working on Azure support. The repository has a `tardigrade/templates/aws` folder where there are two templates for a Management and Member account. The `terragrunt.hcl` file of the Member account is currently written to be dependent on the Management account being done first. This dependency within the file would need to be edited with the Management folder name later, if you wanted to add a member underneath a management account. For the sake of demonstration, we will only be deploying a Management config at this time. Copy the `terraform.tfvars` and `terragrunt.hcl` files from the Management template, into `/tardigrade/configs/aws/{your aws account id}/management/`. 

Edit `../{account id}/management/terraform.tfvars` with the `account_name` you'd like to set. This is a unique identifier used in the deployment

Edit `../configs/aws/globals.tfvars.yaml` with the namespace you would like to set. This is a unique identifier used in the deployment

Run `terragrunt init --terragrunt-working-dir tardigrade/configs/aws/{account_id}/management` to initialize the backend. This will prompt to create a new bucket (using the name you provided) as the backend if needed. 

After successful init, run `terragrunt plan --terragrunt-working-dir tardigrade/configs/aws/{account_id}/management` and validate the output. You may run `apply` in a similar fashion to complete the deployment. 


# Modify the Baseline
Currently, there is a simple implementation located in `tardigrade/roots/aws/member`
that stitches together several of Plus3 IT's terraform modules. This baseline is
what will be deployed to the account. You can edit the baseline to add/remove modules
as you see fit.
