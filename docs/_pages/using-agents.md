---
title: "Using AI Agents"
permalink: /using-agents/
toc: true
---

# Overview

Tardigrade repositories include instructions for AI agents to assist with common tasks. These instructions use `AGENTS.md`, a cross-tool standard that most AI coding agents read directly.

# AGENTS.md Files

Each tardigrade repository contains an `AGENTS.md` file at the root. Some repositories have nested `AGENTS.md` files in subdirectories for layer-specific procedures:

- `AGENTS.md` — Root instructions, conventions, and cross-repository standards
- `tardigrade/stacks/AGENTS.md` — Procedures for adding stacks (accounts) and units
- `tardigrade/roots/AGENTS.md` — Procedures for adding root modules
- `tardigrade/modules/AGENTS.md` — Guidelines for local modules
- `tardigrade/vendor/AGENTS.md` — Procedures for vendoring external modules
- `tardigrade/templates/AGENTS.md` — Template conventions
- `NEW_REPO.md` — Step-by-step procedure for creating a new deployment repository

These files are written for AI agents, but humans can read them too.

# No Tool-Specific Files

Repositories contain only `AGENTS.md` files. Don't add tool-specific instruction files such as `CLAUDE.md` or `GEMINI.md`: most agent tools read `AGENTS.md` directly, and some tools read only their own file when it exists. For example, Claude Code skips `AGENTS.md` files, including nested ones, when a `CLAUDE.md` is present.

If a tool you use doesn't read `AGENTS.md`, configure it in your own user settings to load `AGENTS.md`, or ask the agent to read it at the start of a session.

# What's in AGENTS.md

AGENTS.md files typically include:

- **Overview** — What the repository does
- **Tooling** — How to run linters, tests, and builds (via `make` targets)
- **Conventions** — File layout, naming conventions, version pins
- **Procedures** — Step-by-step instructions for common tasks
- **Safety rules** — Commands that should never be run without human approval
- **Repository-specific** — Details unique to this deployment (accounts, CI/CD, etc.)

For the tardigrade template, there's also a "Maintaining the tardigrade template" section that documents how changes to `tardigrade/` should be reflected in `docs/`.

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

Task-specific procedures are split across the nested AGENTS.md files:

| Task | File |
|------|------|
| Create a new deployment repo | [NEW_REPO.md](https://github.com/plus3it/tardigrade/blob/master/NEW_REPO.md) |
| Add a stack (account) | [stacks/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/stacks/AGENTS.md) |
| Add a unit (region/root) | [stacks/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/stacks/AGENTS.md) |
| Add a root module | [roots/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/roots/AGENTS.md) |
| Add a local module | [modules/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/modules/AGENTS.md) |
| Vendor an external module | [vendor/AGENTS.md](https://github.com/plus3it/tardigrade/blob/master/tardigrade/vendor/AGENTS.md) |

The root AGENTS.md file provides an index and links to these nested files.

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

Any change under `tardigrade/` or to an AGENTS.md procedure must update the corresponding `docs/` page in the same PR:

| File/Directory | Mapped Page |
|----------------|-------------|
| `AGENTS.md` | [using-agents.md]({{ "/using-agents/" | relative_url }}) |
| `tardigrade/stacks/AGENTS.md` | [how-to-guide.md]({{ "/how-to-guide/" | relative_url }}) |
| `tardigrade/roots/AGENTS.md` | [structure.md]({{ "/structure/" | relative_url }}) |
| `tardigrade/modules/AGENTS.md` | [create-a-module.md]({{ "/create-a-module/" | relative_url }}) |
| `tardigrade/vendor/AGENTS.md` | [structure.md]({{ "/structure/" | relative_url }}) |
| `tardigrade/templates/AGENTS.md` | [structure.md]({{ "/structure/" | relative_url }}) |
| `NEW_REPO.md` | [new-repository.md]({{ "/new-repository/" | relative_url }}) |

This keeps the human-facing documentation in sync with the agent instructions.

# Supported Tools

Agents that read `AGENTS.md` directly include:

- **Claude Code** (v2.1.277 and later, when the repository has no `CLAUDE.md`), including nested `AGENTS.md` files as it works in subdirectories
- **Google Antigravity**, which loads `AGENTS.md` files cumulatively from the edited file's directory up to the workspace root
- **OpenAI Codex**, **GitHub Copilot**, **Cursor**, and other tools that support the AGENTS.md standard

Agents that only load the root file still find the procedures: the root `AGENTS.md` tells them to read the linked file before starting each task.

The format is tool-agnostic: it's just Markdown with clear headings and procedures.
