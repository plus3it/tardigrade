# tardigrade

A repository structure and conventions for Terragrunt + Terraform deployments that works with any Terraform provider. Used for whole-account baselines (most often AWS) and for single-application deployments (for example, on GCP). This template ships an AWS account-baseline example.

## User Documentation
User documentation can be found at: [https://plus3it.github.io/tardigrade](https://plus3it.github.io/tardigrade)

## Developer Documentation
The source of this project is located in the `tardigrade` directory. That directory contains the terragrunt configuration at `tardigrade/stacks` and the terraform root modules at `tardigrade/roots`.

### Editing User Documentation
The user documentation website is created using GitHub Pages. We are using the [minimal-mistakes](https://github.com/mmistakes/minimal-mistakes) theme. The content can be found in the `docs/` folder
