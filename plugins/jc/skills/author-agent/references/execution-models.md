# Execution Models

> Agents support one or more execution capabilities: subagent, forked skill, or team member. An agent can be dual-purpose. This reference covers the capabilities model, decision framework, and design considerations.

## Capabilities Model

An agent's execution model defines how it is spawned, communicates, and completes its lifecycle. Three capabilities exist:

| Capability | Spawned Via | Communication | Lifecycle | Tools |
|------------|------------|---------------|-----------|-------|
| **Subagent** | `Task` tool | None (returns result) | One-shot | Read, Write, Edit, Bash, Grep, Glob, etc. |
| **Forked Skill** | `context: fork` | None (returns result) | One-shot | Tools inherited from main thread |
| **Team Member** | `Task` tool + `team_name` | `SendMessage`, `TaskList/Update` | Persistent, multi-turn | All tools + SendMessage, TaskList, TaskUpdate, TaskGet, TaskCreate |

Agents can support **multiple capabilities** (dual-purpose). The auditor checks applicable rules for each capability the agent claims.

## Subagent Capability

One-shot execution: receives input, does work, returns result. No inter-agent communication, no user interaction.

**Characteristics:**
- Spawned via `Task` tool with `subagent_type` parameter (do NOT use `name` — it creates team members)
- Receives all context in the initial prompt (I/O contract format)
- Returns result via stdout or writes files directly
- No access to `AskUserQuestion`, `SendMessage`, `TaskList`
- No mid-execution user input

**Design considerations:**
- Prompt must be self-contained — all context in the I/O contract
- Callers pass reference file paths as absolute paths resolved from the skill's announced base directory. Do NOT use the `name` parameter — it creates team members instead of foreground subagents
- Keep prompts focused — one task per subagent invocation
- Handle errors by returning structured error output, not retrying

**Canonical examples:** (none currently)

## Forked Skill Capability

One-shot execution via `context: fork` in SKILL.md frontmatter. Runs in an isolated fork of the main context.

**Characteristics:**
- Spawned automatically when skill is invoked (no explicit Task tool call)
- Inherits tools from main thread
- Returns result to main context when complete
- Cannot interact with user during execution

**Design considerations:**
- Suited for analysis, auditing, and read-heavy tasks
- Fork inherits the full conversation context — useful when skill needs prior discussion context
- Less control over tool access than subagent (inherits all)

## Team Member Capability

Persistent agent that participates in an Agent Team. Coordinates with teammates via messaging and shared task lists.

**Characteristics:**
- Spawned via `Task` tool with `team_name` parameter
- Communicates with teammates via `SendMessage` tool
- Reads/claims tasks via `TaskList`, `TaskGet`, `TaskUpdate`, `TaskCreate`
- Discovers teammates by reading `~/.claude/teams/{team-name}/config.json`
- Persists across multiple turns — goes idle between work, wakes on message
- Handles `shutdown_request` messages gracefully

**Design considerations:**
- Must include `## Team Behavior` section in agent prompt
- Must handle message types: task assignments, status requests, shutdown requests
- Must poll `TaskList` after completing each task to find next work
- Should send status updates to team lead via `SendMessage`
- Tools must include coordination tools: `SendMessage`, `TaskList`, `TaskUpdate`, `TaskGet`, `TaskCreate`

**Canonical examples:** `team-leader` (coordinates teammates via SendMessage/TaskList)

## Dual-Purpose Agents

Some agents work both as standalone subagents AND as team members. The agent detects its mode based on available context:

- **Team mode:** `team_name` present → use SendMessage, TaskList coordination
- **Subagent mode:** no `team_name` → one-shot execution, return result via stdout/files

**Design pattern:**
```markdown
## Team Behavior

When spawned as a team member (team_name present):
- Read team config to discover teammates
- Claim tasks via TaskUpdate
- Send status updates via SendMessage
- Handle shutdown requests

When spawned as a standalone subagent:
- Execute the task described in the prompt
- Return results per I/O contract
- No team coordination needed
```

**Canonical examples:** `team-mapper`, `team-researcher`, `team-executor`, `team-reviewer`, `team-verifier` (can be spawned standalone or as part of an agent team)

## Decision Framework

Use this to choose which capabilities an agent needs:

```
Is the agent always spawned by a specific orchestrator?
├─ Yes: Subagent (one-shot, I/O contract)
└─ No: ↓

Does the agent need to coordinate with other agents?
├─ Yes: Team member
└─ No: ↓

Does the agent need conversation context from the main thread?
├─ Yes: Forked skill (context: fork)
└─ No: Subagent

Should it work both standalone AND in teams?
├─ Yes: Dual-purpose (subagent + team)
└─ No: Single capability
```

## Capability Compliance Rules

The auditor verifies these rules per capability:

### All Capabilities
- No mid-execution user input (`AskUserQuestion` belongs in main chat)
- Pure Markdown structure (no XML tags)
- Description drives routing (specific triggers + differentiation)

### Subagent-Specific
- No `SendMessage`, `TaskList`, `TaskUpdate` in tools
- No `## Team Behavior` section
- Prompt follows I/O contract format expectations

### Team Member-Specific
- Has `## Team Behavior` section
- Tools include `SendMessage`, `TaskList`, `TaskUpdate`, `TaskGet`, `TaskCreate`
- Handles shutdown requests
- Polls TaskList after completing work
- Discovers teammates via team config file

### Dual-Purpose
- All rules for ALL claimed capabilities apply
- Mode detection documented in `## Team Behavior`
- Both execution paths tested independently
