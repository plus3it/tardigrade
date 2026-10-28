## tardigrade Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

### [0.2.0](https://github.com/plus3it/tardigrade/releases/tag/0.2.0)

**Commit Delta**: [Change from 0.1.0 release](https://github.com/plus3it/tardigrade/compare/0.1.0...0.2.0)

**Released**: 2026.10.28

**Summary**:

*   Updates the template to the layout used by current deployments: `vendor/`, `modules/`, `roots/`, `templates/`, and `stacks/<partition>/<scope_id>/<region>/<root>/`, with one `terragrunt-root.hcl` per partition ([#261](https://github.com/plus3it/tardigrade/pull/261))
*   Vendors each external module in its own directory, and lists the directories each root uses in `.tardigrade.config.yaml` ([#261](https://github.com/plus3it/tardigrade/pull/261))
*   Updates the example roots for the interfaces of the pinned module versions, and gates global-only resources with `is_global` ([#261](https://github.com/plus3it/tardigrade/pull/261))
*   Applies the `TardigradeManaged` tag through the provider `default_tags` in `terragrunt-root.hcl`, and removes the unused `tags` variable from the example roots ([#261](https://github.com/plus3it/tardigrade/pull/261))
*   Adds agent instructions in `AGENTS.md`, with the procedures in `agents/procedures/`; `make agents/sync` (tardigrade-ci 0.31.0 or later) writes them to `.agents/plus3it/tardigrade/` at the template version that a deployment pins ([#261](https://github.com/plus3it/tardigrade/pull/261))
*   Adds the pin `uses: plus3it/tardigrade@<version>` in `.github/workflows/dependabot_hack.yml`, which `.bumpversion.cfg` updates on each release ([#261](https://github.com/plus3it/tardigrade/pull/261))
*   Rewrites the GitHub Pages docs, adds `NEW_REPO.md`, and generalizes the description of tardigrade beyond AWS account baselines ([#261](https://github.com/plus3it/tardigrade/pull/261))
*   Bumps tardigrade-ci to 0.31.0 ([#261](https://github.com/plus3it/tardigrade/pull/261))

### 0.1.0

**Commit Delta**: [Change from 0.1.0 release](https://github.com/plus3it/tardigrade/compare/0.0.5...0.1.0)

**Released**: 2025.05.19

**Summary**:

*   Uses Github Actions for CI/CD and removes Travis-CI configuration

### 0.0.5

**Commit Delta**: [Change from 0.0.4 release](https://github.com/plus3it/tardigrade/compare/0.0.4...0.0.5)

**Released**: 2020.03.11

**Summary**:

*   Fix missing local variables file
*   Update module version references
*   Update terraform provider version
*   Update aws provider version
*   Update external provider version

### 0.0.4

**Commit Delta**: [Change from 0.0.3 release](https://github.com/plus3it/tardigrade/compare/0.0.3...0.0.4)

**Released**: 2020.01.08

**Summary**:

*   Add metric filters
*   Remove unused variables
*   Add metric alarms
*   Remove AWSSupportAccess policy from user and add it to a group instead

### 0.0.3

**Commit Delta**: [Change from 0.0.2 release](https://github.com/plus3it/tardigrade/compare/0.0.2...0.0.3)

**Released**: 2020.01.03

**Summary**:

*   Add AWSSupportAccess AWS Managed Policy to user

### 0.0.2

**Commit Delta**: [Change from 0.0.1 release](https://github.com/plus3it/tardigrade/compare/0.0.1...0.0.2)

**Released**: 2020.01.02

**Summary**:

*   Update cloudtrail version which integrates kms
*   Remove rules from default vpc's default security group
*   Remove 0.0.0.0/0 rule from the created vpc's default security group

### 0.0.1

**Commit Delta**: [Change from 0.0.0 release](https://github.com/plus3it/tardigrade/compare/0.0.0...0.0.1)

**Released**: 2019.10.28

**Summary**:

*   Pins tfdocs-awk version

### 0.0.0

**Commit Delta**: N/A

**Released**: 2019.10.17

**Summary**:

*   Initial release!
