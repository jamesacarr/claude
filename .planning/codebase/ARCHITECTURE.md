# Architecture

> Last mapped: 2026-02-23T16:43:07Z

## Directory Structure

```
.
├── .claude/                          # Claude Code session config
│   ├── settings.local.json           # Permission allowlist (git, fetch)
│   └── docs/plans/                   # Implementation plans (manual/historical)
├── .claude-plugin/
│   └── marketplace.json              # Marketplace manifest — registers plugins
├── plugins/
│   └── jc/                           # "James' Claude Toolkit" plugin
│       ├── .claude-plugin/
│       │   └── plugin.json           # Plugin manifest (name, version, description)
│       ├── agents/                   # Agent definitions (8 markdown files)
│       │   ├── team-leader.md        # Agent Team coordinator (lead session)
│       │   ├── team-mapper.md        # Codebase mapping specialist
│       │   ├── team-researcher.md    # Task-scoped research
│       │   ├── team-planner.md       # Plan creation, critique, revision
│       │   ├── team-executor.md      # Task implementation (TDD)
│       │   ├── team-verifier.md      # Functional verification
│       │   ├── team-reviewer.md      # Code quality review
│       │   └── team-debugger.md      # Root-cause investigation
│       ├── skills/                   # User-invocable skill definitions
│       │   ├── map/SKILL.md          # /jc:map — codebase mapping orchestration
│       │   ├── research/SKILL.md     # /jc:research — 4-dimension research
│       │   ├── plan/SKILL.md         # /jc:plan — plan-critique-revise loop
│       │   ├── implement/SKILL.md    # /jc:implement — wave execution + resume
│       │   ├── debug/SKILL.md        # /jc:debug — debugger agent orchestration
│       │   ├── status/SKILL.md       # /jc:status — read-only .planning/ report
│       │   ├── cleanup/SKILL.md      # /jc:cleanup — remove completed task dirs
│       │   ├── test/SKILL.md         # /jc:test — test quality principles
│       │   ├── test/references/      # Reference docs for test skill
│       │   ├── test-driven-development/SKILL.md  # /jc:test-driven-development
│       │   └── verify-completion/SKILL.md        # /jc:verify-completion
│       └── docs/                     # Shared contracts and schemas
│           ├── agent-io-contract.md  # Standard agent invocation format
│           └── plan-schema.md        # PLAN.md structure specification
├── .planning/                        # Runtime artifact directory (per-project)
│   ├── codebase/                     # Shared codebase map (6 files)
│   └── {task-id}/                    # Task-scoped artifacts
│       ├── research/                 # 4 research docs
│       ├── plans/                    # PLAN.md + CRITIQUE.md
│       ├── verification/             # Per-task + plan-level verification
│       ├── reviews/                  # Plan-level review
│       └── debug/                    # Debug session logs
└── README.md                         # Marketplace usage instructions
```

## Module Boundaries

This repository is a **Claude Code plugin marketplace** containing a single plugin (`jc`). There is no runtime application code — the entire codebase consists of Markdown specifications that Claude Code interprets at runtime.

### Marketplace Layer

- `/.claude-plugin/marketplace.json` — registers the marketplace with Claude Code
- `/plugins/` — contains all installable plugins (currently only `jc`)
- Each plugin has its own `.claude-plugin/plugin.json` manifest

### Plugin Layer (`plugins/jc/`)

The `jc` plugin has three sub-modules:

1. **Agents** (`agents/`) — 8 Markdown files defining agent personas, capabilities, constraints, and workflows. Each agent supports two invocation modes:
   - **Task-tool subagent**: spawned by a skill via the Task tool
   - **Agent Team teammate**: coordinated by the Team Leader via Agent Teams messaging

2. **Skills** (`skills/`) — 10 user-invocable skill definitions. Each skill orchestrates one or more agents. Skills are self-contained and never invoke other skills — the user drives the workflow sequence.

3. **Docs** (`docs/`) — 2 shared contracts consumed by agents and skills:
   - `agent-io-contract.md` — standardised Task/Context/Input/Expected Output format
   - `plan-schema.md` — PLAN.md structure (frontmatter, waves, tasks, status values)

### Runtime Artifacts (`.planning/`)

Not part of the plugin source. Created at runtime in the project where the plugin is used:
- `.planning/codebase/` — project-wide, shared across tasks, persists until regenerated
- `.planning/{task-id}/` — task-scoped, created per feature/ticket, cleaned up via `/jc:cleanup`

## Data Flow

### Two Invocation Patterns

The system supports two coordination models that produce identical `.planning/` artifacts:

**Pattern 1: Skills workflow (user-orchestrated)**

```
User ─── /jc:map ────────── spawns 4 team-mapper agents ──► .planning/codebase/ (6 files)
  │
  ├── /jc:research ──────── spawns 4 team-researcher agents ──► .planning/{task-id}/research/ (4 files)
  │
  ├── /jc:plan ──────────── spawns team-planner (plan→critique→revise) ──► .planning/{task-id}/plans/
  │
  └── /jc:implement ─────── state machine orchestrating:
        │                     team-executor (per task)
        │                     team-verifier (per task + plan-level)
        │                     team-reviewer (per wave + plan-level)
        │                     team-debugger (on escalation)
        └──────────────────► .planning/{task-id}/verification/, reviews/, debug/
```

Each skill is a separate user command. Skills prompt the user to run prerequisites if missing (hard gates for map, research, plan). File content never flows through the skill — agents read/write `.planning/` directly.

**Pattern 2: Agent Team (Team Leader-orchestrated)**

```
User ─── team-leader ──► ASSESS → MAP → RESEARCH → PLAN → WORKTREE → EXECUTE → FINAL
                          │
                          ├── Spawns teammates per phase (same agents as skills)
                          ├── Lead-delegated task assignment (no self-claiming)
                          ├── Peer-to-peer messaging (verifier↔executor, reviewer↔executor)
                          └── Lead owns all PLAN.md status updates
```

The Team Leader coordinates the full lifecycle autonomously. Same agents, same artifacts, different coordination mechanism.

### Execution Isolation: Worktree Strategy

```
Main tree                          Worktree ({task-id} branch)
──────────                         ─────────────────────────
/jc:map        writes .planning/
/jc:research   writes .planning/
/jc:plan       writes .planning/
                 │
                 ├── commit .planning/ ──►  /jc:implement creates worktree
                 │                          │
                 │                          ├── executor writes source code
                 │                          ├── verifier runs tests
                 │                          └── reviewer checks conventions
                 │
                 └──────────────────────── user merges branch back
```

Pre-execution phases (map, research, plan) produce only documentation and run in the main tree. Execution modifies source code and runs in a git worktree for branch isolation.

### Plan Document as Central State

`PLAN.md` (schema: `plugins/jc/docs/plan-schema.md`) is the single source of truth for execution state:

| Consumer | Reads | Writes |
|----------|-------|--------|
| Implement skill | Full doc | Frontmatter, task/wave status, retries |
| Verifier agent | Success criteria, NFRs, tasks | Nothing (writes separate reports) |
| Reviewer agent | Success criteria, task structure | Nothing (writes separate reports) |
| Status skill | Full doc | Nothing (read-only) |
| Planner (revise) | Full doc + CRITIQUE.md | Overwrites full doc |

### Codebase Map as Shared Context

`.planning/codebase/` (6 files) is consumed by multiple agents — see `plugins/jc/docs/plan-schema.md` and the plan in `.claude/docs/plans/2026-02-21-jc-agents-skills.md` (Codebase Map Reference Model table):

| Agent | Files Read | Purpose |
|-------|-----------|---------|
| Planner | All 6 | Full project understanding for plan creation |
| Planner (critique) | CONVENTIONS, TESTING, CONCERNS, ARCHITECTURE | Cross-reference plan against codebase |
| Executor | STACK, TESTING | Language, framework, test runner basics |
| Reviewer (wave) | CONVENTIONS | Convention adherence check |
| Reviewer (plan) | CONVENTIONS, TESTING, CONCERNS | Full quality review |
| Team Leader | All 6 | Routing decisions and context sharing |

## Key Patterns

### Agent-Skill Separation

Agents define **what** an agent is (persona, constraints, output format). Skills define **how** to orchestrate agents (sequencing, gates, user interaction). Same agent `.md` files serve both the skills workflow and Agent Team mode.

- Agent definitions: `plugins/jc/agents/team-*.md`
- Skill definitions: `plugins/jc/skills/*/SKILL.md`

### Standardised I/O Contract

All agent invocations follow the contract in `plugins/jc/docs/agent-io-contract.md`:
- **Task** — single imperative sentence
- **Context** — task-id, project root, planning directory
- **Input** — concrete data, absolute file paths
- **Expected Output** — exact file paths or stdout format

Agents write files directly. Skills never relay file content — they pass metadata only.

### Wave-Based Parallel Execution

Plans are structured as ordered waves (schema: `plugins/jc/docs/plan-schema.md`). Within a wave, tasks are independent and can execute in parallel. The implement skill (`plugins/jc/skills/implement/SKILL.md`) enforces file-level isolation via pre-flight overlap detection at `WAVE_START`.

### Hard Gates with Soft Prompts

Skills enforce prerequisites via a tiered gate system (see `plugins/jc/skills/plan/SKILL.md`, Step 2):
- **Hard gate** — missing prerequisite, execution stops (codebase map, research)
- **Soft gate** — stale data, user prompted to refresh or proceed (>50 commits since last map)

### Skill Preloading via Frontmatter

Agents cannot invoke skills at runtime. Instead, skill content is injected at agent startup via the `skills` YAML frontmatter field (e.g., executor gets `jc:test` and `jc:test-driven-development`). See agent frontmatter in `plugins/jc/agents/team-executor.md`.

### Naming Conventions

- Agents: `team-` prefix, kebab-case — `plugins/jc/agents/team-{role}.md`
- Skills: kebab-case directory with `SKILL.md` — `plugins/jc/skills/{name}/SKILL.md`
- Task IDs: lowercase alphanumeric + hyphens/underscores, validated in research skill (`plugins/jc/skills/research/SKILL.md`, Step 1)

### Prescriptive Guidance

- New agents: add to `plugins/jc/agents/` with `team-` prefix. Follow the canonical heading structure: `## Role`, `## Focus Areas`, `## Constraints`, `## Workflow`, `## Output Format`, `## Success Criteria`. Add `## Agent Team Behavior` if the agent participates in the Team Leader workflow. Reference `plugins/jc/agents/team-mapper.md` as a minimal example.
- New skills: create `plugins/jc/skills/{name}/SKILL.md`. Include `## Essential Principles`, `## Quick Start`, `## Process`, `## Anti-Patterns`, `## Success Criteria`, `## References`. Reference `plugins/jc/skills/research/SKILL.md` as a clean example.
- New docs/contracts: add to `plugins/jc/docs/`. These are shared specifications consumed by multiple agents — keep them stable since changes ripple across consumers.
- New plugins: create `plugins/{name}/` with `.claude-plugin/plugin.json` and register in `/.claude-plugin/marketplace.json`.
- Runtime artifacts: always write to `.planning/` using the established directory structure. Task-scoped output goes in `.planning/{task-id}/`. Project-wide output goes in `.planning/codebase/`.
