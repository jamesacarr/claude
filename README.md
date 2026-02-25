# Claude Code Marketplace & Plugins

A personal marketplace containing curated plugins for Claude Code.

## Plugins

| Plugin | Description |
|--------|-------------|
| `jc` | James' Claude Toolkit — agent-based workflow system with TDD, verification, and codebase mapping |

## Structure

```
.claude-plugin/
  marketplace.json        # Marketplace manifest
plugins/
  jc/                     # James' Claude Toolkit
    .claude-plugin/
      plugin.json         # Plugin manifest
    agents/               # 10 agent definitions
    docs/                 # Shared references (plan schema, agent I/O contract)
    skills/               # 14 skill modules
```

### Agents

| Agent | Role |
|-------|------|
| `team-leader` | Coordinates the full feature lifecycle across teammates |
| `team-mapper` | Maps codebases across 4 dimensions (stack, architecture, conventions, testing) |
| `team-researcher` | Researches tasks across approach, integration, quality, and risk dimensions |
| `team-planner` | Creates implementation plans through a plan-critique-revise loop |
| `team-executor` | Implements tasks from PLAN.md using TDD (RED → GREEN → REFACTOR) |
| `team-verifier` | Verifies task completion against done-when criteria |
| `team-reviewer` | Reviews code for quality, security, performance, and architectural fit |
| `team-debugger` | Investigates bugs and failures using scientific method |
| `audit-agent-auditor` | Audits agent definitions for correctness and best practices |
| `audit-skill-auditor` | Audits skill definitions for compliance |

### Skills

| Skill | Purpose |
|-------|---------|
| `map` | Map a codebase to structured analysis documents |
| `research` | Research a task across 4 dimensions via parallel agents |
| `plan` | Create implementation plans through plan-critique-revise |
| `implement` | Execute plans via wave-based parallelization with verification and review |
| `debug` | Investigate bugs by spawning the debugger agent |
| `test` | Enforce test quality — behavioral assertions, minimal mocking |
| `test-driven-development` | Enforce RED → GREEN → REFACTOR TDD discipline |
| `verify-completion` | Evidence-based completion verification |
| `changelog` | Generate CHANGELOG.md entries from git history |
| `release` | Bump version, finalize changelog, tag, and push |
| `status` | Report on planning state without modifications |
| `cleanup` | Remove finished task directories from .planning/ |
| `author-skill` | Create, edit, audit, and delete skills |
| `author-agent` | Create, edit, audit, and delete agents |

## Skill Guide

See **[GUIDE.md](GUIDE.md)** for detailed descriptions, usage examples, and typical workflows for every skill.

## Usage

### Add the marketplace

```
/plugin marketplace add jamesacarr/claude
```

### Install a plugin

```
/plugin install jc@jamesacarr-claude
```

### Manage

```
/plugin marketplace list                  # List marketplaces
/plugin marketplace update                # Refresh listings
/plugin marketplace remove                # Remove marketplace
/plugin disable jc@jamesacarr-claude      # Disable plugin
/plugin uninstall jc@jamesacarr-claude    # Uninstall plugin
```

## License

UNLICENSED
