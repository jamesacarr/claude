# Conventions

> Last mapped: 2026-02-23T16:43:08Z

## Naming

- Files (skills): `SKILL.md` in a kebab-case directory — example: `plugins/jc/skills/test-driven-development/SKILL.md`
- Files (agents): `team-<role>.md` in flat `agents/` directory — example: `plugins/jc/agents/team-executor.md`
- Files (docs): kebab-case `.md` — example: `plugins/jc/docs/agent-io-contract.md`
- Files (reference material): kebab-case `.md` in a `references/` subdirectory — example: `plugins/jc/skills/test/references/testing-anti-patterns.md`
- Directories: kebab-case throughout — example: `plugins/jc/skills/verify-completion/`
- Task IDs: lowercase alphanumeric, hyphens, underscores only — example: `add-oauth2-auth`
- Skill names: namespaced `jc:<skill-name>` — example: `jc:test-driven-development`
- Agent names: `team-` prefix on all subagents — example: `team-mapper`, `team-executor`

## File Organisation

- Source root: `plugins/jc/`
- Skills: `plugins/jc/skills/<skill-name>/SKILL.md` — one `SKILL.md` per skill, optional `references/` subdirectory
- Agents: `plugins/jc/agents/team-<role>.md` — flat directory, no subdirectories (not supported by plugin system)
- Shared docs: `plugins/jc/docs/` — contracts and schemas referenced by multiple agents/skills
- Plugin manifests: `.claude-plugin/marketplace.json` (marketplace level), `plugins/jc/.claude-plugin/plugin.json` (plugin level)
- Planning output: `.planning/codebase/` (shared), `.planning/{task-id}/` (task-scoped)

## Document Structure

### Skills (`SKILL.md`)

Every skill follows this structure (see `plugins/jc/skills/implement/SKILL.md` for the most complete example):

```
---
name: <skill-name>
description: "<one-line description with usage guidance and anti-guidance>"
---

## Essential Principles
## Quick Start
## Process
## Anti-Patterns
## Success Criteria
```

- Frontmatter `description` must include positive guidance ("Use when...") and negative guidance ("Do NOT use for... (use X)")
- Essential Principles: numbered list, imperative tone, bold keywords
- Anti-Patterns: table format with "Excuse" | "Reality" columns (or equivalent)
- Success Criteria: bulleted checklist of observable outcomes

### Agents (`team-*.md`)

Every agent follows canonical heading structure (see `plugins/jc/agents/team-executor.md`):

```
---
name: <agent-name>
description: "<one-line description>"
tools: <comma-separated tool list>
skills: <comma-separated skill list, if preloaded>
---

## Role
### Codebase Map Reference (if reads codebase map)
## Focus Areas
## Constraints
## Workflow
## Output Format
## Agent Team Behavior (if dual-mode)
## Success Criteria
```

- Frontmatter `tools` enforces least-privilege (e.g., `Read, Write, Edit, Bash, Grep, Glob`)
- Frontmatter `skills` preloads skill content into agent context (e.g., `skills: jc:test, jc:test-driven-development`)
- `## Role` includes a `### Codebase Map Reference` table when the agent reads `.planning/codebase/` files

## Commit Messages

Conventional Commits format with scoped types — configured in `.claude/docs/plans/2026-02-21-jc-agents-skills.md`:

| Type | Scope | Use |
|------|-------|-----|
| `feat(jc)` | `jc` | New agents, skills |
| `docs(jc)` | `jc` | Contracts, schemas, reference docs |
| `test(jc)` | `jc` | Integration test fixes |
| `chore(jc)` | `jc` | Directory structure, plugin.json, config |
| `chore(marketplace)` | `marketplace` | Marketplace-level config |
| `refactor(jc)` | `jc` | Structural changes without new features |

Subject line must be <= 72 characters. Format: `<type>(<scope>): <subject>`.

## Imports / References

- Skills reference other skills by namespace: `jc:test`, `jc:test-driven-development`
- Agents reference docs with relative paths from plugin root: `plugins/jc/docs/agent-io-contract.md`
- Cross-references within docs use inline path format: `See \`references/testing-anti-patterns.md\``
- The I/O contract (`plugins/jc/docs/agent-io-contract.md`) is the shared calling convention referenced by all skills that spawn agents

## Error Handling

- Agents return structured `## Result` / `## Summary` / `## Details` blocks — defined in `plugins/jc/docs/agent-io-contract.md`
- Result values: `PASS`, `FAIL`, `OBJECTIONS`, `ERROR`
- On error, agents include: what was attempted, root cause, and suggestion for the orchestrator
- Hard retry limit: 3 per task (executor-verifier loop), 3 per plan-review revision round
- On escalation: present options to user via `AskUserQuestion` — never retry silently past the limit

## Code Style

- Markdown files throughout — no runtime code in this codebase
- Tables preferred for structured comparisons (anti-patterns, options, field definitions)
- Imperative tone in principles and constraints ("MUST", "NEVER", "Do NOT")
- Bold keywords for emphasis in numbered lists
- YAML frontmatter on all skills and agents — required fields vary by type

## Security

- Never quote `.env`, credential files, private keys, or service account files — note existence only
- Never include API keys, tokens, or secrets in code or commits
- Never use `git add -A` — stage specific files only
- Never use `--no-gpg-sign` — all commits must be GPG signed

### Prescriptive Guidance

- New skills: create `plugins/jc/skills/<kebab-case-name>/SKILL.md` with frontmatter (`name`, `description`), then sections: Essential Principles, Quick Start, Process, Anti-Patterns, Success Criteria. Follow `plugins/jc/skills/implement/SKILL.md` as the canonical example
- New agents: create `plugins/jc/agents/team-<role>.md` with frontmatter (`name`, `description`, `tools`, optionally `skills` and `mcpServers`), then sections: Role, Focus Areas, Constraints, Workflow, Output Format, Success Criteria. Add `## Agent Team Behavior` if the agent operates in both Task-tool and Agent Team modes. Follow `plugins/jc/agents/team-executor.md` as the canonical example
- New docs: place in `plugins/jc/docs/` with kebab-case naming. Reference from skills/agents via relative path
- New reference material: place in `plugins/jc/skills/<skill>/references/` subdirectory
- Commit messages: always use Conventional Commits with appropriate scope. Use HEREDOC for multi-line messages
- Task IDs: validate format (alphanumeric, hyphens, underscores) before use. Generate slugs from descriptions, confirm with user
