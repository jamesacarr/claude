# Integrations

> Last mapped: 2026-02-23T16:43:06Z

## Claude Code Runtime

This project has no databases, external APIs, or traditional service integrations. It is a plugin consumed by the Claude Code runtime. All "integrations" are Claude Code platform features used by agents and skills.

### Platform Features Used

| Feature | Purpose | Used in |
|---------|---------|---------|
| **Task tool** | Spawns subagents for parallel/sequential work | `plugins/jc/skills/map/SKILL.md`, `plugins/jc/skills/plan/SKILL.md`, `plugins/jc/skills/implement/SKILL.md` |
| **Agent Teams** | Coordinates teammate sessions (peer-to-peer messaging, lead-delegated assignment) | `plugins/jc/agents/team-leader.md` |
| **EnterWorktree** | Creates git worktrees for isolated execution | `plugins/jc/skills/implement/SKILL.md`, `plugins/jc/agents/team-leader.md` |
| **AskUserQuestion** | Prompts user for decisions (escalation, confirmation, routing) | `plugins/jc/skills/implement/SKILL.md`, `plugins/jc/skills/plan/SKILL.md`, `plugins/jc/skills/map/SKILL.md` |
| **WebSearch / WebFetch** | External research when Context7 MCP has no coverage | `plugins/jc/agents/team-researcher.md` |
| **Read / Write / Bash / Grep / Glob** | Core file and shell tools used by all agents | `plugins/jc/agents/team-mapper.md` (declares in frontmatter) |

### Agent Tool Declarations

| Agent | Declared Tools |
|-------|---------------|
| `team-mapper` | Read, Write, Bash, Grep, Glob |
| `team-researcher` | Read, Write, Bash, Grep, Glob, WebSearch, WebFetch |
| `team-planner` | Read, Write, Bash, Glob, Grep, WebFetch |
| Other agents | Tools not declared in frontmatter (inherit defaults) |

## Environment Variables

No environment variables are referenced in this project. The `.claude/settings.local.json` file configures Claude Code permissions declaratively:

| Permission | Purpose | Configured in |
|------------|---------|--------------|
| `WebFetch(domain:raw.githubusercontent.com)` | Allow fetching from GitHub raw content | `.claude/settings.local.json` |
| `Bash(git add:*)` | Allow git staging commands | `.claude/settings.local.json` |
| `Bash(git commit:*)` | Allow git commit commands | `.claude/settings.local.json` |

## External Services

| Service | How Used | Referenced in |
|---------|----------|--------------|
| GitHub (`raw.githubusercontent.com`) | WebFetch permission for reading raw files from GitHub | `.claude/settings.local.json` |
| GitHub (`github.com/jamesacarr/claude`) | Plugin homepage / source repo | `plugins/jc/.claude-plugin/plugin.json` |

### Prescriptive Guidance

- **No traditional integrations to add.** This project does not connect to databases, APIs, or external services in the conventional sense.
- **New agent tool needs:** Declare required tools in the agent's YAML frontmatter `tools:` field. See `plugins/jc/agents/team-researcher.md` for an example with WebSearch/WebFetch.
- **New permissions:** Add to `.claude/settings.local.json` under `permissions.allow[]`. Follow the existing pattern: `ToolName(constraint)`.
- **WebFetch domains:** If a new agent needs to fetch from a new domain, add `WebFetch(domain:example.com)` to `.claude/settings.local.json`.
- **Context7 MCP is preferred** over WebSearch/WebFetch for library documentation. WebSearch/WebFetch are fallbacks when Context7 has no coverage (see `plugins/jc/agents/team-researcher.md` line 26).
