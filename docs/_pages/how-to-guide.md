---
title: "How-To Guide"
permalink: /how-to-guide/
toc: true
---

# Prerequisites
* [terraform >= 0.12](https://www.terraform.io/)
  - credentials configured for an AWS account
  - note, some modules are pinned to 0.14 It is advised to use this version for now for best compatability. 
* [terragrunt >= v0.21](https://github.com/gruntwork-io/terragrunt)
* (optional!) [AWS CLI >= 2.0](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
  - used for logging in to AWS during the quickstart example

# Authentication
Users have multiple options for authentication to deploy their resources, basically whatever the Terraform providers support at the time! Generally, this falls into one of the following: Login through a CLI tool (which sets $ENV variables that Terraform providers will then use), or setting the account directly with vars in the provider (see the provider documentation for more deails).

# How To Use (quickstart)
Note: this quickstart covers a very simple setup using AWS and the included templates. Once you have a feel for how the tool works and is deployed, you can further extend functionality however you'd like. Validate that you have all tools installed correctly. You can do this by typing `{tool} --version` into the comand line to validate the tool is in your PATH and the version is appropriate. Note that in some installation methods of terragrunt (namely, Brew) will attempt to install the latest version of Terraform with it. This can cause a dependency issue. You may have to manually uninstall undesired versions and add the correct ones to your PATH. 

After all tools are validated, you must log into the AWS CLI to set your environment config. This generally involves creating programmatic access for a user account and setting it up with `aws configure`. [Instructions for configuring your CLI environment to the desired AWS account can be found here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

Next, you need to add a configuration into the environment you would like to deploy resources into. In the current state, we only support AWS and are currently working on Azure support. The repository has a `tardigrade/templates/aws` folder where there are two templates for a Management and Member account. The `terragrunt.hcl` file of the Member account is currently written to be dependent on the Management account being done first. This dependency within the file would need to be edited with the Management folder name later, if you wanted to add a member underneath a management account. For the sake of demonstration, we will only be deploying a Management config at this time. Copy the `terraform.tfvars` and `terragrunt.hcl` files from the Management template, into `/tardigrade/configs/aws/{your aws account id}/management/`. 

Edit `../{account id}/management/terraform.tfvars` with the `account_name` you'd like to set. This is a unique identifier used in the deployment

Edit `../configs/aws/globals.tfvars.yaml` with the namespace you would like to set. This is a unique identifier used in the deployment

Edit `../configs/aws/terragrunt.hcl`, find the `remote_state` block. Change the `bucket` and `dynamo_db` name to something unique, like by adding a unique suffix to the string.  (TODO, this is likely an unintended change or dependency, this will likely be patched later so that you do not have to edit this file)

Run `terragrunt init --terragrunt-working-dir tardigrade/configs/aws/{account_id}/management` to initialize the backend. This will prompt to create a new bucket (using the name you provided) as the backend if needed. 

After successful init, run `terragrunt plan --terragrunt-working-dir tardigrade/configs/aws/{account_id}/management` and validate the output. You may run `apply` in a similar fashion to complete the deployment. 


# Modify the Baseline
Currently, there is a simple implementation located in `tardigrade/roots/aws/member`
that stitches together several of Plus3 IT's terraform modules. This baseline is
what will be deployed to the account. You can edit the baseline to add/remove modules
as you see fit.
