---
title: "Using AI Agents"
permalink: /using-agents/
toc: true
---

# Overview

Tardigrade repositories include instructions for AI agents to assist with common tasks. These instructions use `AGENTS.md`, a cross-tool standard that most AI coding agents read directly.

# AGENTS.md Files

Each tardigrade repository contains an `AGENTS.md` file at the root. The procedures for layer-specific tasks are released with the tardigrade template, in `agents/procedures/`, and deployments read them at the template version they pin:

- `AGENTS.md` — Root instructions, conventions, and cross-repository standards
- `stacks.md` — Procedures for adding stacks (accounts) and units
- `roots.md` — Procedures for adding root modules
- `modules.md` — Guidelines for local modules
- `vendor.md` — Procedures for vendoring external modules
- `templates.md` — Template conventions
- `NEW_REPO.md` — Step-by-step procedure for creating a new deployment repository

In the plus3it/tardigrade template, the procedures are in `agents/procedures/`. In a deployment, `make agents/sync` writes them to `.agents/plus3it/tardigrade/`. A short stub `AGENTS.md` in each of `tardigrade/stacks/`, `tardigrade/roots/`, `tardigrade/modules/`, `tardigrade/vendor/`, and `tardigrade/templates/` tells agents (and keeps the directory-level loading of tools such as Claude Code and Antigravity) to read the matching file before changing that directory. The stubs never change.

These files are written for AI agents, but humans can read them too.

# No Tool-Specific Files

Repositories contain only `AGENTS.md` files. Don't add tool-specific instruction files such as `CLAUDE.md` or `GEMINI.md`: most agent tools read `AGENTS.md` directly, and some tools read only their own file when it exists. For example, Claude Code skips `AGENTS.md` files, including nested ones, when a `CLAUDE.md` is present.

If a tool you use doesn't read `AGENTS.md`, configure it in your own user settings to load `AGENTS.md`, or ask the agent to read it at the start of a session.

# What's in AGENTS.md

The root `AGENTS.md` in each repository has two parts:

1. **Committed pointer** — A short section that tells agents to run `make agents/sync` and read `.agents/plus3it/AGENTS.md`, plus core safety rules
2. **Repository-specific sections** — Details unique to this repository (purpose, accounts, CI/CD, etc.)

For tardigrade, the root `AGENTS.md` also includes:
- **What is tardigrade** — Overview, architecture layers, glossary
- **Verify and Build Commands** — How to vendor, lint, validate, and plan
- **Safety Rules** — Commands that should never be run without human approval
- **Procedure Index** — Where to find the procedure file for each task, in a deployment and in the template
- **Maintaining the tardigrade template** — How changes to `tardigrade/` should be reflected in `docs/`

# Shared Instructions

Shared conventions for Plus3 IT repositories (linting, testing, releases, dependency automation) live in the tardigrade-ci repository under `agents/` and are synced at runtime into `.agents/plus3it/AGENTS.md` when an agent runs `make agents/sync`. The sync reads from the tardigrade-ci version the repository already uses (pinned in the `Dockerfile`), so shared changes reach deployment repos when their tardigrade-ci pin is bumped, through the update pull requests Dependabot (GitHub) or Renovate (other hosts) opens.

The `.agents/plus3it/` directory is generated and ignores itself (via `.agents/plus3it/.gitignore`), so no repository needs a `.gitignore` change.

The committed pointer at the top of each repository's `AGENTS.md` comes from plus3it/repo-template and rarely changes.

# Template Procedures

The tardigrade procedures describe the template's layout, so they are released with the template rather than with tardigrade-ci:

- **Pin.** A deployment records the template version whose layout it matches in `.github/workflows/dependabot_hack.yml`, as a `uses: plus3it/tardigrade@<tag>` line. The workflow never runs; the line exists so that Dependabot (or Renovate, on other hosts) proposes a bump when the template publishes a release. A person reviews each bump against the template CHANGELOG and updates the deployment to match, because the instructions must not describe a layout the deployment does not have.
- **Sync.** `make agents/sync` (tardigrade-ci 0.31.0 or later) reads the pin and writes the five procedure files from that tag to `.agents/plus3it/tardigrade/`. Without a pin, only the general instructions are written.
- **Mirrors.** A deployment that hosts the template elsewhere writes the mirror's project path in the pin line and sets `TARDIGRADE_GIT_URL` in the `Makefile`. The sync derives the project name it looks for from that URL.
- **New repositories.** A deployment deletes the template's `agents/` directory (the procedures arrive by sync) and keeps the stubs. See [New Repository]({{ "/new-repository/" | relative_url }}).

# Safety Model

AI agents and automation should prepare changes, but people (or explicitly approved CI/CD pipelines) apply them:

- **Agents can**: Read files, run linters, run `terraform plan`, run `terragrunt plan`, generate code, create branches, prepare commits
- **Agents cannot**: Run `terraform apply/destroy/import/state`, run `terragrunt apply/destroy`, push to protected branches, create AWS resources directly

This model ensures:
- All state-changing operations are reviewed by humans
- Credentials used by agents can be read-only (plan-only permissions)
- Mistakes are caught before they affect production infrastructure

Document this in your deployment's AGENTS.md under "Safety rules".

# Where Procedures Live

Task-specific procedures are separate files in `agents/procedures/` in the template (and `.agents/plus3it/tardigrade/` in a deployment, after `make agents/sync`). The links below go to the template's copy:

| Task | File |
|------|------|
| Create a new deployment repo | [NEW_REPO.md](https://github.com/plus3it/tardigrade/blob/master/NEW_REPO.md) |
| Add a stack (account) | [stacks.md](https://github.com/plus3it/tardigrade/blob/master/agents/procedures/stacks.md) |
| Add a unit (region/root) | [stacks.md](https://github.com/plus3it/tardigrade/blob/master/agents/procedures/stacks.md) |
| Add a root module | [roots.md](https://github.com/plus3it/tardigrade/blob/master/agents/procedures/roots.md) |
| Add a local module | [modules.md](https://github.com/plus3it/tardigrade/blob/master/agents/procedures/modules.md) |
| Vendor an external module | [vendor.md](https://github.com/plus3it/tardigrade/blob/master/agents/procedures/vendor.md) |

The root AGENTS.md file provides an index of these files.

# Using Agents Effectively

## Be Specific

AI agents work best with specific tasks:
- ✅ "Add a stack for account 222222222222 with units in us-east-1 and us-west-2"
- ❌ "Set up infrastructure"

## Review Plans

Always review `terragrunt plan` output before applying:
- Check resource changes (additions, modifications, deletions)
- Verify no unintended changes (e.g., recreating existing resources)
- Confirm the blast radius is appropriate

## Let Agents Prepare, You Apply

A good workflow:
1. Ask the agent to add a stack/unit/root
2. The agent creates files and runs `terragrunt plan`
3. Review the plan output
4. You run `terragrunt apply`

## Iterate on Errors

If the agent's first attempt has errors, provide the error message and ask it to fix them. The AGENTS.md instructions help agents self-correct.

# Docs-Sync Rule (Template Maintainers Only)

If you're maintaining the plus3it/tardigrade template itself:

Any change under `tardigrade/` or to a procedure in `agents/procedures/` must update the corresponding `docs/` page in the same PR:

| File/Directory | Mapped Page |
|----------------|-------------|
| `AGENTS.md` | [using-agents.md]({{ "/using-agents/" | relative_url }}) |
| `agents/procedures/stacks.md` | [how-to-guide.md]({{ "/how-to-guide/" | relative_url }}) |
| `agents/procedures/roots.md` | [structure.md]({{ "/structure/" | relative_url }}) |
| `agents/procedures/modules.md` | [create-a-module.md]({{ "/create-a-module/" | relative_url }}) |
| `agents/procedures/vendor.md` | [structure.md]({{ "/structure/" | relative_url }}) and [create-a-module.md]({{ "/create-a-module/" | relative_url }}) |
| `agents/procedures/templates.md` | [structure.md]({{ "/structure/" | relative_url }}) |
| `NEW_REPO.md` | [new-repository.md]({{ "/new-repository/" | relative_url }}) |

The stubs in `tardigrade/*/AGENTS.md` never change. This keeps the human-facing documentation in sync with the agent instructions.

# Supported Tools

Agents that read `AGENTS.md` directly include:

- **Claude Code** (v2.1.277 and later, when the repository has no `CLAUDE.md`), including nested `AGENTS.md` files as it works in subdirectories
- **Google Antigravity**, which loads `AGENTS.md` files cumulatively from the edited file's directory up to the workspace root
- **OpenAI Codex**, **GitHub Copilot**, **Cursor**, and other tools that support the AGENTS.md standard

Agents that only load the root file still find the procedures: the root `AGENTS.md` tells them to read the linked file before starting each task.

The format is tool-agnostic: it's just Markdown with clear headings and procedures.
