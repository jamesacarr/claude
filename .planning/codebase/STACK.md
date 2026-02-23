# Stack

> Last mapped: 2026-02-23T16:43:06Z

## Languages

- Markdown — all agents, skills, docs, and configuration are authored in Markdown. No compiled languages present.
- JSON — plugin manifests and settings: `.claude-plugin/marketplace.json`, `plugins/jc/.claude-plugin/plugin.json`, `.claude/settings.local.json`

## Frameworks

- **Claude Code Plugin System** — this is a Claude Code plugin marketplace and agent toolkit, not a traditional application. Entry point: `.claude-plugin/marketplace.json` (marketplace manifest), `plugins/jc/.claude-plugin/plugin.json` (plugin manifest)
- **Agent Teams model** — multi-agent coordination framework built on Claude Code's Task tool and Agent Teams features. Orchestrated by: `plugins/jc/agents/team-leader.md`

## Package Manager

No package manager. This project has no runtime dependencies, lockfiles, or build artifacts. Content is entirely declarative Markdown and JSON consumed by the Claude Code runtime.

## Key Dependencies

| Dependency | Version | Purpose | Used in |
|-----------|---------|---------|---------|
| Claude Code | n/a (runtime) | Agent execution, Task tool, Agent Teams, EnterWorktree | All agents and skills |
| Git | n/a (system) | Worktree isolation, commit tracking, staleness detection | `plugins/jc/skills/implement/SKILL.md`, `plugins/jc/agents/team-leader.md` |
| GPG | n/a (system) | Commit signing (required, never `--no-gpg-sign`) | `plugins/jc/skills/map/SKILL.md`, `.claude/settings.local.json` |

## Build & Dev Tools

No build tools, bundlers, linters, formatters, or CI/CD pipelines. The project is a collection of Markdown specifications consumed directly by Claude Code.

## Project Structure

| Path | Purpose |
|------|---------|
| `.claude-plugin/marketplace.json` | Marketplace manifest — registers this repo as a Claude Code plugin marketplace |
| `plugins/jc/.claude-plugin/plugin.json` | Plugin manifest for the `jc` plugin (v0.0.1) |
| `plugins/jc/agents/` | Agent definitions (8 agents: team-leader, team-mapper, team-researcher, team-planner, team-executor, team-verifier, team-reviewer, team-debugger) |
| `plugins/jc/skills/` | Skill definitions (9 skills: map, research, plan, implement, test, test-driven-development, verify-completion, debug, cleanup, status) |
| `plugins/jc/docs/` | Shared specifications: `agent-io-contract.md`, `plan-schema.md` |
| `.claude/settings.local.json` | Local Claude Code permissions (WebFetch, git add, git commit) |
| `.planning/codebase/` | Output directory for codebase map documents (this file lives here) |

### Prescriptive Guidance

- **No runtime code to add.** This is a pure-Markdown plugin. New functionality means new agent definitions (`plugins/jc/agents/*.md`) or skill definitions (`plugins/jc/skills/*/SKILL.md`).
- **Agent format:** YAML frontmatter (`name`, `description`, `tools`) followed by Markdown sections: Role, Focus Areas, Constraints, Workflow/Process, Output Format, Success Criteria. See `plugins/jc/agents/team-mapper.md` as a canonical example.
- **Skill format:** YAML frontmatter (`name`, `description`) followed by Markdown sections: Essential Principles, Quick Start, Process (numbered steps), Anti-Patterns, Success Criteria, References. See `plugins/jc/skills/plan/SKILL.md` as a canonical example.
- **Plugin registration:** New plugins must be added to `.claude-plugin/marketplace.json` under `plugins[]` and have their own `.claude-plugin/plugin.json` manifest.
- **Git commits must be GPG-signed.** Never use `--no-gpg-sign`. If GPG fails due to sandbox, disable sandbox for that command.
