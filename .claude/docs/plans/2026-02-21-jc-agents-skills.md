---
created: 2026-02-21T22:47:02Z
updated: 2026-02-22T21:19:10Z
status: draft
feature: JC Plugin - Agents & Skills
---

# JC Plugin: Agents & Skills — Implementation Plan

## Resume Protocol

1. Read this plan from the top — skim the steps checklist to find the first `- [ ]`
2. Read the step description and its linked spec in the appendix
3. Read any referenced contract/schema files already committed (I/O contract, plan schema)
4. Execute the step using `/wc:author-agent` or `/wc:author-skill` where indicated
5. Mark the step `- [x]` in this file
6. Stage and commit both the work **and** this updated plan in one commit
7. Repeat — or stop at any step boundary when context is getting full

**When pausing:** The last commit always contains the current progress state. To resume in a new session, just read this file and continue from the first unchecked step.

## Commit Convention

[Conventional Commits](https://www.conventionalcommits.org/) with scope `jc`:

| Type | Use |
|------|-----|
| `chore(jc)` | Directory structure, plugin.json, config |
| `docs(jc)` | Contracts, schemas, reference docs |
| `feat(jc)` | Agents, skills |
| `test(jc)` | Integration test fixes |

## Overview

Build a complete agent-based workflow system for the JC (James's Claude Toolkit) plugin. The system supports two invocation patterns:

1. **Skills + Task subagents** — User invokes a skill (e.g., `/jc:research`, `/jc:plan`, `/jc:implement`), which orchestrates subagents via the Task tool
2. **Agent Team** — A Team Leader agent coordinates the same agents as an Agent Team, with shared context

Both patterns use the same underlying agent definitions. The user orchestrates between skills — skills never invoke other skills.

---

## Steps

### Foundation

- [x] **Step 1:** Create directory structure under `plugins/jc/`
  - Create `agents/`, `skills/` (with all subdirs per [Directory Structure](#directory-structure)), `docs/`
  - Empty `.gitkeep` files where needed to preserve structure
  - Commit: `chore(jc): create plugin directory structure`

- [x] **Step 2:** Define agent I/O contract — `docs/agent-io-contract.md`
  - Standardised Task/Context/Input/Expected Output structure for all agents
  - See [Agent I/O Contract Spec](#agent-io-contract-spec)
  - Commit: `docs(jc): define agent I/O contract`

- [x] **Step 3:** Define plan document schema — `docs/plan-schema.md`
  - Plan format: frontmatter, task structure, wave definitions, status fields, resume state, NFR section
  - Central contract consumed by Implement, Resume, Status, Verifier, Reviewer
  - See [Plan Schema Spec](#plan-schema-spec)
  - Commit: `docs(jc): define plan document schema`

- [x] **Step 4:** Create test skill — `skills/test/` (TDD: RED baseline showed over-mocking/weak naming, GREEN fixed all core failures, audit applied)
  - `SKILL.md` + `references/testing-anti-patterns.md`
  - Extracted from `wc:tdd` — test quality principles
  - User-invocable as `/jc:test`, preloaded into Executor and Verifier
  - Use `/wc:author-skill` to create
  - Commit: `feat(jc): add test skill`

- [x] **Step 5:** Create TDD skill — `skills/test-driven-development/` (TDD: RED baseline showed interleaving rationalization on "obvious" tasks, GREEN fixed with phase boundaries + rationalizations table, audit applied)
  - `SKILL.md` — RED → GREEN → REFACTOR process
  - References `jc:test` for test-writing guidance
  - User-invocable as `/jc:test-driven-development`, preloaded into Executor
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add test-driven-development skill`

- [x] **Step 6:** Create verify-completion skill — `skills/verify-completion/` (TDD: RED baseline passed all 4 scenarios — agents already good at verification. Skill codifies consistent process/report format. Audit applied)
  - `SKILL.md` — evidence-based completion verification
  - Extracted from `wc:verify-completion`
  - User-invocable as `/jc:verify-completion`, preloaded into Verifier
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add verify-completion skill`

- [x] **Step 7:** Update `plugin.json`
  - New version and description reflecting agent/skill additions
  - Commit: `chore(jc): update plugin.json for agents and skills`

### Codebase Mapping

- [x] **Step 8:** Create mapper agent — `agents/team-mapper.md`
  - See [Mapper Agent Spec](#mapper-agent)
  - **You MUST use `/wc:author-agent` to create this agent.** Do NOT write the agent `.md` file directly — invoke the skill and follow its workflow
  - Commit: `feat(jc): add mapper agent`

- [ ] **Step 9:** Create map skill — `skills/map/`
  - See [Map Skill Spec](#map-skill)
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add map skill`

### Research

- [ ] **Step 10:** Create researcher agent — `agents/team-researcher.md`
  - See [Researcher Agent Spec](#researcher-agent)
  - **You MUST use `/wc:author-agent` to create this agent.** Do NOT write the agent `.md` file directly — invoke the skill and follow its workflow
  - Commit: `feat(jc): add researcher agent`

- [ ] **Step 11:** Create research skill — `skills/research/`
  - See [Research Skill Spec](#research-skill)
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add research skill`

### Planning

- [ ] **Step 12:** Create planner agent — `agents/team-planner.md`
  - See [Planner Agent Spec](#planner-agent)
  - **You MUST use `/wc:author-agent` to create this agent.** Do NOT write the agent `.md` file directly — invoke the skill and follow its workflow
  - Commit: `feat(jc): add planner agent`

- [ ] **Step 13:** Create plan skill — `skills/plan/`
  - See [Plan Skill Spec](#plan-skill)
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add plan skill`

### Execution

- [ ] **Step 14:** Create executor agent — `agents/team-executor.md`
  - See [Executor Agent Spec](#executor-agent)
  - **You MUST use `/wc:author-agent` to create this agent.** Do NOT write the agent `.md` file directly — invoke the skill and follow its workflow
  - Commit: `feat(jc): add executor agent`

- [ ] **Step 15:** Create verifier agent — `agents/team-verifier.md`
  - See [Verifier Agent Spec](#verifier-agent)
  - **You MUST use `/wc:author-agent` to create this agent.** Do NOT write the agent `.md` file directly — invoke the skill and follow its workflow
  - Commit: `feat(jc): add verifier agent`

- [ ] **Step 16:** Create reviewer agent — `agents/team-reviewer.md`
  - See [Reviewer Agent Spec](#reviewer-agent)
  - **You MUST use `/wc:author-agent` to create this agent.** Do NOT write the agent `.md` file directly — invoke the skill and follow its workflow
  - Commit: `feat(jc): add reviewer agent`

- [ ] **Step 17:** Create debugger agent — `agents/team-debugger.md`
  - See [Debugger Agent Spec](#debugger-agent)
  - **You MUST use `/wc:author-agent` to create this agent.** Do NOT write the agent `.md` file directly — invoke the skill and follow its workflow
  - Commit: `feat(jc): add debugger agent`

- [ ] **Step 18:** Create debug skill — `skills/debug/`
  - See [Debug Skill Spec](#debug-skill)
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add debug skill`

### Orchestration

- [ ] **Step 19:** Create implement skill — `skills/implement/`
  - See [Implement Skill Spec](#implement-skill)
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add implement skill`

- [ ] **Step 20:** Create resume skill — `skills/resume/`
  - See [Resume Skill Spec](#resume-skill)
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add resume skill`

- [ ] **Step 21:** Create status skill — `skills/status/`
  - See [Status Skill Spec](#status-skill)
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add status skill`

- [ ] **Step 22:** Create cleanup skill — `skills/cleanup/`
  - See [Cleanup Skill Spec](#cleanup-skill)
  - **You MUST use `/wc:author-skill` to create this skill.** Do NOT write files directly — invoke the skill and follow its TDD workflow (RED baseline → GREEN → REFACTOR → structural audit)
  - Commit: `feat(jc): add cleanup skill`

### Team Leader

- [ ] **Step 23:** Create team leader agent — `agents/team-leader.md`
  - See [Team Leader Agent Spec](#team-leader-agent)
  - **You MUST use `/wc:author-agent` to create this agent.** Do NOT write the agent `.md` file directly — invoke the skill and follow its workflow
  - Commit: `feat(jc): add team leader agent`

### Integration Testing

Steps 24-33 are validation steps. If issues are found, fix and commit with `test(jc): fix <description>` before marking the step complete.

- [ ] **Step 24:** Test map skill — brownfield, greenfield, regeneration
  - See [Test: Map Skill](#test-map-skill)

- [ ] **Step 25:** Test gate enforcement — plan without map, plan without research, stale map
  - See [Test: Gate Enforcement](#test-gate-enforcement)

- [ ] **Step 26:** Test end-to-end skill workflow — `/jc:map` → `/jc:research` → `/jc:plan` → `/jc:implement`
  - See [Test: E2E Workflow](#test-e2e-workflow)

- [ ] **Step 27:** Test pause/resume flow — abort mid-wave, resume from worktree
  - See [Test: Pause/Resume](#test-pauseresume)

- [ ] **Step 28:** Test failure handling — retry exhaustion, escalation options, skip with dependents
  - See [Test: Failure Handling](#test-failure-handling)

- [ ] **Step 29:** Test plan critique loop — weak plan triggers objections, revision addresses them
  - See [Test: Critique Loop](#test-critique-loop)

- [ ] **Step 30:** Test wave review — convention check after wave, fix round if needed
  - See [Test: Wave Review](#test-wave-review)

- [ ] **Step 31:** Test status and cleanup skills
  - See [Test: Status & Cleanup](#test-status--cleanup)

- [ ] **Step 32:** Test debug skill — known bug, root cause identification
  - See [Test: Debug](#test-debug)

- [ ] **Step 33:** Test team leader end-to-end — full Agent Team workflow
  - See [Test: Team Leader](#test-team-leader)

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Team Leader vs Skills | Coexist independently | Skills = subagent orchestration, Team Leader = Agent Team. Same agents, different coordination |
| Skill delegation | Eliminated | Skills never invoke other skills. Each skill is self-contained. User orchestrates the workflow (`/jc:map` → `/jc:research` → `/jc:plan` → `/jc:implement`). Skills prompt user to run prerequisites if missing |
| Summariser | Removed | Planner reads all research docs directly. No separate synthesis step — the Planner needs to deeply understand the research anyway. Avoids information loss from summarization |
| Researcher count | Always 4 | Every research run spawns 4 researchers with fixed focus areas (approach, codebase integration, quality & standards, risks & edge cases). Keeps the system simple and consistent. Focus areas presented to user before spawning — user can override |
| Research focus areas | 4 fixed dimensions, user-confirmable | Fixed roles ensure consistent coverage across all tasks. Each dimension is task-scoped — same role, different research questions depending on the task. User can swap a focus area if one isn't relevant (e.g., replace "risks" with "database migration strategy") |
| Codebase map | Shared `.planning/codebase/` with 6 docs | Persistent, project-wide codebase map produced by `/jc:map`. Lives outside task-scoped directories. Referenced by Planner, Reviewer, and Team Leader. Run once when starting a new codebase, refreshed manually as needed. Supports both brownfield (map existing code) and greenfield (establish conventions from user input) |
| Mapper agent | Dedicated `team-mapper`, not reusing researcher | Researcher explores topics ("what should we do?"). Mapper explores existing code ("what's already here?"). Different inputs, outputs, and expertise. 4 mapper agents with different focus areas produce 6 files |
| Codebase map staleness | Commit-count check in Plan skill | `jc:plan` counts commits to source files since last map commit. Timestamps are unreliable (2 weeks idle vs 2 days with 50 commits). Hard gate if map missing, soft prompt if >50 source commits since last map |
| PROJECT-CONTEXT.md | Eliminated | With the codebase map providing persistent project-wide conventions and the plan containing task-specific guidance, PROJECT-CONTEXT.md was a redundant intermediate layer. Executors read the plan (task-specific instructions) + `STACK.md` and `TESTING.md` from the codebase map (language, framework, test runner). The critique loop ensures the plan contains correct guidance. Removing it simplifies the Planner's job and eliminates a source of inconsistency |
| Debugger | Include in v1 | Executor escalates to Debugger when auto-fix attempts exhausted |
| Failure handling | Hard limits + user options | Max 3 retries per loop (executor→verifier→fix). After that, present user with options: skip task, provide guidance, implement manually, or abort execution |
| Resume skill | Include in v1 | Essential for pause/resume workflow in Implement skill |
| Verifier agent | Separate from Reviewer | Verifier = "does the work meet spec?", Reviewer = "is the code good?" Different concerns, different cadence. Verifier does not write tests — executors handle that via TDD |
| Team Leader routing | Smart routing, default to research | Team Leader dynamically decides workflow scope based on task complexity. Skips research only when confident task is small, well-scoped, and in well-understood code. Any ambiguity → research |
| Status skill | Include in v1 | `/jc:status` reports on `.planning/` state without modifying anything |
| Skill naming | Namespaced (`jc:*`) | `jc:map`, `jc:research`, `jc:plan`, `jc:implement`, `jc:resume`, `jc:debug`, `jc:status`, `jc:cleanup`. Avoids collisions with other plugins |
| Agent naming | `team-` prefix on all agents except Team Leader | Agents live in a flat `agents/` directory (subdirectories not supported). Prefix ensures team agents group together alphabetically as unrelated agents are added to the plugin. Team Leader already has the prefix naturally |
| Model preferences | Inherit from parent + optional override | Agents inherit the session model by default. Skills can override per-agent when stakes warrant it (e.g., final verification on Opus). No user-facing config |
| Plan document format | Defined in Step 3 as core contract | Plan schema is consumed by Implement, Resume, Status, Verifier, and Reviewer. Must be stable before any consumers are built |
| `.planning/` lifecycle | Task-scoped directories + shared codebase map | `.planning/{task-id}/` for each task. `.planning/codebase/` shared across all tasks. Multiple tasks can coexist. `/jc:cleanup` handles removal of completed task directories |
| Templates | Shared I/O contract + inline formats | One shared doc defines the agent calling convention (Task/Context/Input/Expected Output). Each agent `.md` inlines its own output format. No separate template files |
| Task ID | Auto-generate with override, error on collision | Skill generates a slug from the task description (e.g., `add-auth-button`). User can override. If ticket reference given, use that (e.g., `WC-123`). If `.planning/{task-id}/` already exists, error and alert user — do not overwrite |
| `.planning/` in git | Committed to version control | Research, plans, reports, and codebase map are part of the project history. Required for worktree transfer. Provides audit trail of decisions in PRs. Cleanup is a post-merge concern, not an architecture concern |
| Research gate | Hard gate for planning | Plan skill always requires research before planning. Research always spawns 4 researchers — don't skip research entirely |
| Codebase map gate | Hard gate (missing) + soft gate (stale) in Plan skill | Plan skill checks `.planning/codebase/` existence (hard gate → prompt `/jc:map`). If map exists, counts source commits since last map (`git log --oneline <last-map-commit>..HEAD -- ':!.planning/'`). If >50 commits, prompts user to regenerate (soft gate — user decides) |
| Parallel file conflicts | Planner prevents + pre-flight fallback | Planner must ensure no file overlap within a wave. Implement skill runs a pre-flight check before each wave: parses the "files affected" field from each task in PLAN.md, builds a file-to-task map, and if any file appears in multiple tasks, runs those tasks sequentially instead of in parallel. Deterministic, no runtime heuristics — logs the fallback so the user knows it happened |
| Git worktrees | Worktree at implementation time only | Research, planning, and codebase mapping run in main tree (documentation only, no source changes). `/jc:implement` commits `.planning/` docs, creates a worktree, and executes there. Team Leader does the same — enters worktree when transitioning from planning to execution. Keeps worktree lifecycle simple and avoids cross-session worktree discovery problems |
| Reusing existing skills | Preload via agent `skills` field | Subagents can't invoke skills at runtime. Instead, preload relevant skills into agent context at startup via the `skills` field. Avoids duplicating methodology knowledge in agent prompts |
| Test vs TDD skills | Split into `jc:test` + `jc:test-driven-development` | Extracted from `wc:tdd` as independent copies. Test quality is a separate concern from TDD process — applicable to verifier, reviewer, and any agent that writes/evaluates tests. `test-driven-development` references `test` for how to write tests, focuses on the RED → GREEN → REFACTOR discipline |
| Debug/review methodology | Inlined in agent prompts, not preloaded skills | `wc:debug-code` and `wc:audit-code` are orchestrator skills that spawn their own subagents — preloading them gives instructions to spawn agents, not the actual methodology. Only the debugger debugs; only the reviewer reviews. Inline the knowledge directly in the agent `.md` |
| Verify-completion | Extracted to `jc:verify-completion` | Independent copy from `wc:verify-completion`. Ensures jc plugin works without wc installed (different repos — jc is personal, wc is work) |
| Non-functional requirements | Enforced through plan schema + verification chain | Plan schema requires explicit NFR section (security, performance, a11y). Planner surfaces NFRs from research as testable criteria. Verifier verifies all criteria including NFRs. Reviewer checks NFR test coverage gaps |
| Adversarial plan critique | Always-on critique loop in Plan skill | After Planner produces PLAN.md, a second Planner invocation (critique mode) adversarially reviews the plan for gaps, over/under-engineering, unclear specs, and codebase convention violations. Planner revises based on critique, critic reviews revision. Capped at 1 revision round — unresolved objections after revision are genuine ambiguities that go to the user. Reduces human guidance burden: users confirm approach rather than finding problems. Critique docs written to `.planning/{task-id}/plans/` as audit trail |
| Plan amendment | Replan mode in Plan skill | When `/jc:plan` detects an existing PLAN.md with completed tasks, it offers two modes: "replace" (start fresh) or "replan" (preserve completed tasks, rewrite remaining). Critique loop runs on replanned portion only — completed tasks are not re-critiqued |
| Review cadence | Wave + plan level | Lightweight convention check after each wave (catches systematic executor drift early — wrong naming, bad abstractions, misused patterns). Full quality review at plan level after all waves. Wave review is focused: convention adherence and pattern consistency against `CONVENTIONS.md` only — not a deep quality audit. One fix round per wave max to prevent loops |
| `.planning/` cleanup | `/jc:cleanup` skill in v1 | `.planning/` directories accumulate as tasks complete. Cleanup skill lists completed tasks, user selects which to remove, commits the removal. Prevents repo noise without automatic deletion |

## Directory Structure

```
plugins/jc/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest (exists)
├── agents/
│   ├── team-debugger.md       # Debugging/investigation agent
│   ├── team-executor.md       # Implementation agent
│   ├── team-leader.md         # Agent Team coordinator
│   ├── team-mapper.md         # Codebase mapping agent
│   ├── team-planner.md        # Planning/architecture agent
│   ├── team-researcher.md     # Research agent
│   ├── team-reviewer.md       # Code quality/maintainability agent
│   └── team-verifier.md       # Verification agent
├── skills/
│   ├── test/
│   │   ├── SKILL.md           # /jc:test — writing good tests
│   │   └── references/
│   │       └── testing-anti-patterns.md
│   ├── test-driven-development/
│   │   └── SKILL.md           # /jc:test-driven-development — RED → GREEN → REFACTOR process
│   ├── verify-completion/
│   │   └── SKILL.md           # /jc:verify-completion — evidence-based completion verification
│   ├── map/
│   │   └── SKILL.md           # /jc:map skill
│   ├── research/
│   │   └── SKILL.md           # /jc:research skill
│   ├── plan/
│   │   └── SKILL.md           # /jc:plan skill
│   ├── implement/
│   │   └── SKILL.md           # /jc:implement skill
│   ├── resume/
│   │   └── SKILL.md           # /jc:resume skill
│   ├── debug/
│   │   └── SKILL.md           # /jc:debug skill
│   ├── status/
│   │   └── SKILL.md           # /jc:status skill
│   └── cleanup/
│       └── SKILL.md           # /jc:cleanup skill
└── docs/
    ├── agent-io-contract.md   # Shared agent calling convention
    └── plan-schema.md         # Plan document format specification
```

## Document Output Convention

Agents write output to two locations relative to the project root where the plugin is used. Both are committed to version control.

### Codebase map (shared, project-wide)

Produced by `/jc:map`. Shared across all tasks. Referenced by the Planner (for planning context), Executor (for language/test runner basics), Reviewer (for convention adherence), and Team Leader (for routing decisions).

```
.planning/
└── codebase/
    ├── STACK.md               # Languages, frameworks, package managers, key dependencies, versions
    ├── INTEGRATIONS.md        # External services, APIs, databases, third-party dependencies
    ├── ARCHITECTURE.md        # Module boundaries, data flow, directory structure, high-level patterns
    ├── CONVENTIONS.md         # Naming, file organisation, import patterns, error handling, code style
    ├── TESTING.md             # Test framework, test patterns, coverage expectations, where tests live
    └── CONCERNS.md            # Tech debt, known pitfalls, fragile areas, things not to touch
```

### Task-scoped output

Each task gets its own scoped directory under `.planning/{task-id}/`.

**Task ID convention:** The first skill in the chain (typically `/jc:research`) generates the task-id. If a ticket reference is provided (e.g., `WC-123`), that is used directly. Otherwise, a slug is generated from the task description (e.g., `add-auth-button`) and presented to the user for confirmation/override. Subsequent skills reuse the existing task-id by detecting `.planning/{task-id}/` directories. If the generated task-id already exists in `.planning/`, the skill errors and alerts the user — it does not overwrite.

```
.planning/
└── {task-id}/
    ├── research/
    │   ├── approach.md                 # Implementation approaches, libraries, patterns
    │   ├── codebase-integration.md     # Affected code, entry points, dependencies
    │   ├── quality-standards.md        # Security, performance, a11y, testing implications
    │   └── risks-edge-cases.md         # Failure modes, backward compat, pitfalls
    ├── plans/
    │   ├── PLAN.md                     # Main plan document (schema defined in docs/plan-schema.md)
    │   └── CRITIQUE.md                 # Adversarial critique of the plan
    ├── verification/
    │   ├── task-{n}-VERIFICATION.md    # Per-task verification reports
    │   └── PLAN-VERIFICATION.md        # Final plan-level verification
    ├── reviews/
    │   └── PLAN-REVIEW.md             # Final plan-level code review
    └── debug/
        └── {session-id}.md             # Debug session logs
```

## Research Focus Areas

The Research skill always spawns 4 researchers with fixed focus areas. Each focus area is scoped to the specific task — same role, different research questions depending on what's being built.

| Focus area | Research question | Example: "add user auth" | Example: "optimise DB queries" |
|-----------|------------------|--------------------------|-------------------------------|
| **Approach** | What are the viable implementation approaches? | OAuth vs JWT vs session-based, Passport.js vs Auth.js, token storage strategies | Query analysis tools, indexing strategies, ORM vs raw SQL, caching layers |
| **Codebase integration** | What existing code is affected? | Route middleware hooks, user model structure, existing session handling | Current query patterns, ORM usage, connection pooling config, affected endpoints |
| **Quality & standards** | Security, performance, a11y, and testing implications? | OWASP auth checklist, rate limiting, password hashing, auth-specific test patterns | Query performance benchmarks, N+1 detection, load testing approach |
| **Risks & edge cases** | What could go wrong? | Token expiry race conditions, session fixation, existing unauthenticated endpoints | Index bloat, migration downtime, cache invalidation complexity, query plan regression |

The Research skill presents these 4 focus areas to the user via AskUserQuestion before spawning. The user can confirm, override individual focus areas, or accept the defaults.

## Codebase Map Reference Model

| Agent | Reads from codebase map | Purpose |
|-------|------------------------|---------|
| **Planner** | All 6 files | Full project understanding for planning. Embeds task-specific conventions and patterns directly into PLAN.md task descriptions |
| **Planner (critique)** | `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`, `ARCHITECTURE.md` | Cross-references plan against codebase conventions to catch alignment violations |
| **Executor** | `STACK.md`, `TESTING.md` | Language, framework, test runner basics. Task-specific guidance comes from PLAN.md |
| **Verifier** | `TESTING.md` | Test runner and verification command context |
| **Reviewer (wave)** | `CONVENTIONS.md` | Lightweight convention check after each wave |
| **Reviewer (plan)** | `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md` | Full review: convention adherence, test patterns, pitfall avoidance |
| **Team Leader** | All 6 files | Full picture for routing decisions and context sharing |

## Worktree Strategy

Research, planning, and codebase mapping produce documentation only — no source code changes. These run in the main tree so `.planning/` artifacts are immediately available to subsequent skills without merge complexity.

Execution modifies source code. All execution happens in a git worktree to isolate changes from the main branch.

### Skills workflow

```
/jc:map       →  main tree  →  writes .planning/codebase/
/jc:research  →  main tree  →  writes .planning/{task-id}/research/
/jc:plan      →  main tree  →  writes .planning/{task-id}/plans/
/jc:implement →  commits .planning/ docs  →  creates worktree  →  executes in worktree
/jc:resume    →  detects existing worktree  →  resumes execution in worktree
/jc:debug     →  runs in current tree (main or worktree, depending on context)
/jc:status    →  main tree  →  reads .planning/ (read-only)
```

### Implement skill worktree flow

1. Verify plan exists in `.planning/{task-id}/plans/PLAN.md`
2. Commit `.planning/` docs to current branch (so worktree inherits them)
3. Create worktree via `EnterWorktree` (named `{task-id}`)
4. Session switches to worktree — all spawned agents inherit this working directory
5. Execute plan (waves, verification, review)
6. On completion: worktree branch is ready for user to merge back to main

### Resume skill worktree flow

1. Check if session is already in a worktree → if yes, proceed with execution
2. If in main tree: look for existing worktree via `git worktree list` matching `{task-id}`
3. If worktree found: **prompt user** to start their session in the worktree (`claude --cwd <worktree-path>`) then re-run `/jc:resume`
4. If no worktree found: something went wrong — prompt user to run `/jc:implement` instead

### Team Leader worktree flow

1. Team Leader starts in main tree
2. Checks for codebase map in `.planning/codebase/` — if missing or stale, coordinates mapper agents first
3. Coordinates researchers → write to `.planning/{task-id}/` in main tree
4. Coordinates planner → writes plan to `.planning/{task-id}/` in main tree
5. Commits `.planning/` docs
6. Calls `EnterWorktree` → session switches to worktree
7. Coordinates executors, verifiers, reviewer, debugger → all in worktree
8. On completion: worktree branch is ready for user to merge

## Preloaded Skills

Subagents cannot invoke skills at runtime. Instead, relevant skills are preloaded into agent context at startup via the `skills` field in the agent `.md` frontmatter.

| Skill | Preloaded Into | Purpose |
|-------|---------------|---------|
| `jc:test` | Executor, Verifier | Test quality principles (naming, assertions, mock discipline, anti-patterns) |
| `jc:test-driven-development` | Executor | TDD process discipline (RED → GREEN → REFACTOR). References `jc:test` |
| `jc:verify-completion` | Verifier | Evidence-based completion verification |

**Not preloaded — methodology inlined in agent prompts instead:**
- **Mapper** — codebase exploration methodology. Only the mapper maps
- **Debugger** — scientific method investigation approach (from `wc:debug-code`). Only the debugger debugs
- **Reviewer** — code quality criteria (from `wc:audit-code`). Only the reviewer reviews

---

## Appendix A: Agent Specifications

### Mapper Agent

**File:** `agents/team-mapper.md`

- Accepts a focus area and writes structured analysis to `.planning/codebase/`
- 4 focus areas producing 6 files:
  - **Technology** → `STACK.md` + `INTEGRATIONS.md` (package manifests, configs, env vars, service connections)
  - **Architecture** → `ARCHITECTURE.md` (module boundaries, data flow, directory structure)
  - **Quality** → `CONVENTIONS.md` + `TESTING.md` (code patterns, naming, style, test framework, test organisation)
  - **Concerns** → `CONCERNS.md` (tech debt, fragile areas, known pitfalls)
- Every finding must reference actual file paths (e.g., `src/services/user.ts`), not vague descriptions
- Includes prescriptive guidance: not just "this is how things are" but "when adding new code, follow this pattern"
- **Security:** Never quotes contents of `.env`, credential files, private keys, or service account files. Notes their existence only
- Writes documents directly to `.planning/codebase/` — returns a short confirmation to the orchestrator to minimise context load
- Tool access: Read, Write, Bash, Grep, Glob
- Handles both modes: explicit prompt (subagent) or team context (Agent Team)

### Researcher Agent

**File:** `agents/team-researcher.md`

- Accepts a focus area and task description
- Uses Context7 MCP as primary documentation source (per user CLAUDE.md)
- Writes structured findings to `.planning/{task-id}/research/{focus-area}.md` (output format defined inline in agent)
- Tool access: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Context7 MCP
- Handles both modes: explicit prompt (subagent) or team context (Agent Team)

### Planner Agent

**File:** `agents/team-planner.md`

Operates in three modes, controlled by the Plan skill:

**Plan mode:**
- Combines roadmapping (phase breakdown, dependency mapping, success criteria) with detailed task planning (task decomposition, verification steps, execution waves)
- Reads all research docs in `.planning/{task-id}/research/`
- Reads the codebase map in `.planning/codebase/` (all 6 files)
- Embeds task-specific conventions and patterns directly into PLAN.md task descriptions (e.g., "create `src/services/auth.ts` following the service pattern in `src/services/user.ts`, add tests in `__tests__/services/auth.test.ts` using vitest")
- Identifies parallel execution opportunities and wave structure
- **Wave file isolation:** Tasks within the same wave must not touch overlapping files
- Uses goal-backward methodology: what must be true when this is done?
- Creates observable, testable success criteria
- **Non-functional requirements:** Identifies security, performance, and accessibility implications from the research. Translates them into testable criteria in the plan's required NFR section. Can mark "none identified" but cannot omit the section
- Writes plan to `.planning/{task-id}/plans/PLAN.md` conforming to `docs/plan-schema.md`
- Each task specifies: files affected, action, verification command, done criteria

**Critique mode:**
- Receives an existing PLAN.md + research docs + codebase map
- **Two review dimensions:**
  1. **Internal consistency:** Gaps in coverage, over-engineered tasks, under-specified success criteria, tasks that should be split or merged, wave ordering problems, NFR gaps, missing edge cases
  2. **Codebase alignment:** Cross-references the plan against the codebase map:
     - `CONVENTIONS.md`: Do tasks follow existing naming, file location, import, and error handling patterns?
     - `TESTING.md`: Do verification commands use the correct test runner and match existing test patterns?
     - `CONCERNS.md`: Does the plan touch fragile areas without acknowledging risk?
     - `ARCHITECTURE.md`: Does the plan respect module boundaries and data flow patterns?
- Must produce specific, actionable objections backed by evidence
- Writes critique to `.planning/{task-id}/plans/CRITIQUE.md`
- Returns either "no objections" (sign-off) or structured list of objections

**Revise mode:**
- Receives original PLAN.md + CRITIQUE.md
- Addresses each objection: accepts and revises, or explicitly rebuts with reasoning
- Writes revised plan to `.planning/{task-id}/plans/PLAN.md` (overwrites)

**Replan mode:** (orthogonal — applies when existing plan has completed tasks) Preserves completed tasks as-is and replans remaining work. Critique loop reviews only the new/changed tasks.

- Tool access: Read, Write, Bash, Glob, Grep, WebFetch, Context7 MCP

### Executor Agent

**File:** `agents/team-executor.md`

- Receives a specific task/section from the plan
- Reads `STACK.md` and `TESTING.md` from `.planning/codebase/` for language, framework, and test runner context
- Follows TDD principles: RED → GREEN → REFACTOR
- Makes small, atomic commits per task
- Handles deviations: auto-fixes within scope (max 3 attempts), then escalates to caller
- Reports completion status and any deviations back to caller
- Tool access: Read, Write, Edit, Bash, Grep, Glob
- Preloaded skills: `jc:test`, `jc:test-driven-development`

### Verifier Agent

**File:** `agents/team-verifier.md`

- Verifies claims against evidence — does not write tests (executors handle that via TDD)
- Reads `TESTING.md` from `.planning/codebase/` for test runner and verification context
- Runs existing test suites to check for regressions
- Goal-backward verification: works from intended outcome, not task list
- Two modes:
  - **Task verification:** Verify a single executor's work → writes `task-{n}-VERIFICATION.md`
  - **Plan verification:** Verify the entire plan's goals → writes `PLAN-VERIFICATION.md`. Must verify every success criterion including NFRs. Flags any criterion it cannot verify with evidence
- Tool access: Read, Write, Bash, Grep, Glob
- Preloaded skills: `jc:test`, `jc:verify-completion`

### Reviewer Agent

**File:** `agents/team-reviewer.md`

- Evaluates code quality and maintainability — distinct from Verifier's functional verification
- Reads codebase map directly: `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md` from `.planning/codebase/`
- Focus areas: simplicity, readability, tech debt, consistency, YAGNI enforcement
- Readability over raw performance unless perf is explicitly required
- **Two review modes:**
  - **Wave review:** Lightweight convention check after a wave completes. Focused on convention adherence from `CONVENTIONS.md`. Writes findings to stdout (not persisted). One fix round per wave max
  - **Plan review:** Full quality review after all waves → writes `PLAN-REVIEW.md`. Cross-references plan success criteria against actual test coverage — flags any criterion without corresponding tests
- Can request executor revisions via structured feedback (specific file, line, issue, suggestion)
- Tool access: Read, Write, Bash, Grep, Glob
- Review methodology inlined in agent prompt

### Debugger Agent

**File:** `agents/team-debugger.md`

- Systematic root-cause investigation using scientific method
- Accepts: problem description, error output, failing tests, or executor escalation
- Forms hypotheses, designs experiments, narrows scope
- Writes findings to `.planning/{task-id}/debug/{session-id}.md`
- Returns: root cause, recommended fix, confidence level
- Tool access: Read, Write, Edit, Bash, Grep, Glob, WebSearch
- Debug methodology inlined in agent prompt

### Team Leader Agent

**File:** `agents/team-leader.md`

- NOT a subagent — used as the entry point for Agent Team coordination
- Accepts: feature description or task to implement
- Coordinates Mapper, Researcher, Planner, Executor, Verifier, Reviewer, Debugger as team members
- **Codebase map awareness:** Checks `.planning/codebase/` before starting. If missing, coordinates mapper agents first. If stale (>50 source commits), prompts user to regenerate. Reads the full codebase map for routing decisions
- **Smart routing:** dynamically decides workflow scope based on task assessment:
  - Evaluates: task description complexity, estimated blast radius, test coverage in affected area, requirement ambiguity
  - Skip research only when confident task is small, well-scoped, and in well-understood code
  - **Default to research when unsure**
  - Transparent about what it skips and why
- Applies same failure handling as skills: max 3 retries per loop, then escalates to user
- Manages information flow between agents (shares context rather than passing docs)
- Handles the full lifecycle: (map →) research → plan (with critique loop) → execute → verify/review → debug (if needed)
- **Worktree transition:** After research and planning, commits `.planning/` docs and calls `EnterWorktree` before coordinating execution agents
- Writes status updates to `.planning/{task-id}/plans/PLAN.md` for resume capability

---

## Appendix B: Skill Specifications

### Map Skill

**File:** `skills/map/SKILL.md`

- Accepts: no required arguments (maps the current project)
- **Brownfield mode** (codebase has source files):
  - If `.planning/codebase/` already exists: asks user "regenerate entire map?" or "cancel" via AskUserQuestion
  - Spawns 4 mapper subagents in parallel, each with a different focus area (technology, architecture, quality, concerns)
  - Each agent writes directly to `.planning/codebase/` — skill does not relay content
  - After all agents complete: verifies all 6 files exist in `.planning/codebase/`
- **Greenfield mode** (no/minimal source files detected):
  - Prompts user via AskUserQuestion for key decisions: tech stack, architecture, testing, conventions
  - Produces the same 6 files as prescriptive guides from user answers
  - Single agent or direct skill output (no need for 4 parallel agents on an empty codebase)
- Commits the codebase map to git
- Returns: paths to codebase map documents + suggestion to proceed with `/jc:research`

### Research Skill

**File:** `skills/research/SKILL.md`

- Accepts: topic/codebase/feature description, optional task-id
- If no task-id: generates a slug from task description, presents to user for confirmation/override
- If ticket reference detected (e.g., `WC-123`): uses that as task-id
- If `.planning/{task-id}/` already exists: errors and alerts user
- Determines 4 focus areas using fixed research dimensions. Presents to user via AskUserQuestion for confirmation/override before spawning
- Spawns 4 researcher subagents in parallel
- Returns: paths to research output documents

### Plan Skill

**File:** `skills/plan/SKILL.md`

- Accepts: task description OR ticket reference, optional task-id
- If ticket reference: fetches ticket details via CLI directly (`jira`, `gh`, `glab`)
- Asks clarifying questions if requirements are ambiguous
- **Codebase map gate (3-tier check):**
  1. Missing → hard gate: tells user to run `/jc:map` first
  2. Stale (>50 source commits since last map commit) → soft prompt via AskUserQuestion
  3. Recent → proceed
- **Research gate:** If no research in `.planning/{task-id}/research/` → hard gate: tells user to run `/jc:research`
- **Existing plan check:** If PLAN.md exists with completed tasks → asks "replace" or "replan" via AskUserQuestion
- **Plan-critique loop:**
  ```
  1. Spawn Planner (plan mode) → PLAN.md
  2. Spawn Planner (critique mode) → CRITIQUE.md
     ├── no objections → done, present to user
     └── has objections →
         3. Spawn Planner (revise mode) → revised PLAN.md
         4. Spawn Planner (critique mode) → updated CRITIQUE.md
            ├── no objections → done, present to user
            └── has objections → present plan + unresolved objections to user
  ```
- Max 1 revision round (4 planner invocations worst case)
- Returns: path to plan document + critique status

### Implement Skill

**File:** `skills/implement/SKILL.md`

- Accepts: task-id to implement
- If no plan exists: prompts user to run `/jc:plan` first
- Manages execution via state machine:

```
States:
  INIT          → validate plan exists, parse PLAN.md
  WORKTREE      → commit .planning/, create worktree, switch session
  WAVE_START    → read next wave, pre-flight file overlap check
  TASK_EXECUTE  → spawn Executor for task
  TASK_VERIFY   → spawn Verifier for completed task
  TASK_RETRY    → re-spawn Executor with Verifier feedback (counter++)
  TASK_ESCALATE → present user with options
  TASK_DONE     → update PLAN.md status, advance to next task
  WAVE_DONE     → all tasks in wave complete
  WAVE_REVIEW   → spawn Reviewer (wave-review mode)
  WAVE_REVISE   → spawn Executor to fix convention issues
  PLAN_VERIFY   → spawn Verifier (plan-verification mode)
  PLAN_REVIEW   → spawn Reviewer (plan-review mode)
  REVIEW_REVISE → Reviewer flagged issues, spawn Executor to fix
  COMPLETE      → all verification/review passed
  PAUSED        → user chose abort or session ended

Transitions:
  INIT → WORKTREE (plan valid)
  INIT → ERROR (no plan found → prompt /jc:plan)

  WORKTREE → WAVE_START (worktree created)

  WAVE_START → TASK_EXECUTE (for each task, parallel if no file overlap)

  TASK_EXECUTE → TASK_VERIFY (executor reports done)
  TASK_EXECUTE → TASK_RETRY (executor hit error, retries < 3)
  TASK_EXECUTE → TASK_ESCALATE (executor hit error, retries = 3)

  TASK_VERIFY → TASK_DONE (verifier confirms)
  TASK_VERIFY → TASK_RETRY (verifier rejects, retries < 3)
  TASK_VERIFY → TASK_ESCALATE (verifier rejects, retries = 3)

  TASK_RETRY → TASK_VERIFY (executor re-reports done)

  TASK_ESCALATE → TASK_DONE (user chose skip/manual)
  TASK_ESCALATE → TASK_RETRY (user provided guidance, counter reset)
  TASK_ESCALATE → PAUSED (user chose abort)

  TASK_DONE → TASK_EXECUTE (more tasks in wave)
  TASK_DONE → WAVE_DONE (last task in wave)

  WAVE_DONE → WAVE_REVIEW (spawn Reviewer in wave-review mode)

  WAVE_REVIEW → WAVE_START (review clean, more waves)
  WAVE_REVIEW → WAVE_REVISE (convention issues found, 1 fix round)
  WAVE_REVIEW → PLAN_VERIFY + PLAN_REVIEW (last wave, review clean, parallel)

  WAVE_REVISE → WAVE_START (fixes applied, more waves)
  WAVE_REVISE → PLAN_VERIFY + PLAN_REVIEW (last wave, fixes applied, parallel)

  PLAN_REVIEW → REVIEW_REVISE (issues flagged, revisions < 3)
  PLAN_REVIEW → TASK_ESCALATE (issues flagged, revisions = 3)
  REVIEW_REVISE → PLAN_REVIEW (re-review after fix)

  PLAN_VERIFY + PLAN_REVIEW → COMPLETE (both pass)

  any state → PAUSED (session ends unexpectedly)
```

**Pre-flight file overlap check (WAVE_START):** Parse "files affected" from each task. Build file-to-task map. If overlap, run those tasks sequentially. Log the fallback.

**PLAN.md status tracking:**
- Each task: `pending | in_progress | passed | failed | skipped | manual`
- Each wave: `pending | in_progress | completed`
- Plan: `planning | executing | verifying | completed | paused`
- PAUSED state writes: current wave, current task, retry counter, last failure reason

**Escalation options (via AskUserQuestion):**
- **Skip task** — mark as `skipped`, continue. If downstream tasks depend on the skipped task, flag them immediately
- **Provide guidance** — user gives hints, retry with that context (resets retry counter)
- **Implement manually** — mark as `manual`, user fixes it, then `/jc:resume`
- **Abort execution** — save state, worktree persists, user can `/jc:resume` later

### Resume Skill

**File:** `skills/resume/SKILL.md`

- Checks worktree state:
  - Already in the task's worktree → proceed
  - In main tree and worktree exists → prompt user to start session in worktree and re-run
  - No worktree found → prompt user to run `/jc:implement` instead
- Reads PLAN.md to determine current state
- Identifies completed, in-progress, and remaining tasks
- Handles partially-updated PLAN.md: `in_progress` tasks with no verification report → re-execute
- Presents status summary, asks for confirmation to continue
- Executes remaining work using the same state machine as Implement (from WAVE_START onward)

### Status Skill

**File:** `skills/status/SKILL.md`

- Read-only — never modifies `.planning/` state
- Scans `.planning/` directory for all task-scoped directories
- For each task: reports phase, what's completed, what's in progress, what's remaining
- Reports codebase map status: exists/missing, last updated, commits since last map
- Shows latest verification/review results if they exist

### Cleanup Skill

**File:** `skills/cleanup/SKILL.md`

- Scans `.planning/` for task-scoped directories (excludes `codebase/`)
- Reads PLAN.md status for each to determine completion state
- Presents list to user via AskUserQuestion with status labels (completed, paused, no plan). User selects which to remove (multiSelect)
- Removes selected directories, commits the removal
- Does not touch `.planning/codebase/`

### Debug Skill

**File:** `skills/debug/SKILL.md`

- Accepts: problem description, error output, or "investigate current failure"
- Spawns Debugger subagent with context
- Returns: diagnosis and recommended fix

---

## Appendix C: Integration Test Specifications

### Test: Map Skill

- **Brownfield:** Run `/jc:map` on this repo. **Pass:** all 6 files exist in `.planning/codebase/`, each references actual file paths (grep for `plugins/jc/`), committed to git
- **Greenfield:** Run `/jc:map` on an empty directory. **Pass:** AskUserQuestion prompts for stack decisions, 6 files produced with prescriptive content, committed to git
- **Regeneration:** Run `/jc:map` on repo with existing map. **Pass:** AskUserQuestion offers regenerate/cancel before overwriting

### Test: Gate Enforcement

- Run `/jc:plan` with no codebase map. **Pass:** errors directing user to `/jc:map`
- Run `/jc:plan` with no research. **Pass:** errors directing user to `/jc:research`
- Run `/jc:plan` with stale map (>50 commits since map). **Pass:** AskUserQuestion warns, user can proceed or regenerate

### Test: E2E Workflow

- Run full chain: `/jc:map` → `/jc:research` → `/jc:plan` → `/jc:implement` on a small task (e.g., "add a health check endpoint")
- **Pass:** research produces 4 docs, plan passes critique loop, worktree created, executor completes task, verifier confirms, wave review passes, plan review produces `PLAN-REVIEW.md`, all PLAN.md statuses updated correctly

### Test: Pause/Resume

- Start `/jc:implement`, abort after first wave. Start new session in worktree, run `/jc:resume`
- **Pass:** PLAN.md shows correct paused state. Resume detects state, presents summary, continues from correct position
- Run `/jc:resume` from main tree when worktree exists. **Pass:** prompts user with worktree path

### Test: Failure Handling

- Provide a task designed to fail (e.g., task referencing nonexistent API). Let retries exhaust
- **Pass:** 3 retry attempts logged, AskUserQuestion with skip/guide/manual/abort options. Each option produces correct PLAN.md status
- Skip a task with downstream dependents. **Pass:** user warned about dependent tasks before proceeding

### Test: Critique Loop

- Submit a deliberately weak plan (vague success criteria, no NFR section, wrong file locations per `CONVENTIONS.md`)
- **Pass:** critique identifies specific objections referencing plan tasks and codebase map docs. Revision addresses objections. Critique docs persist

### Test: Wave Review

- After a wave completes, verify Reviewer runs in wave-review mode
- **Pass:** Reviewer checks convention adherence against `CONVENTIONS.md`. If issues found, executor fix round runs before next wave

### Test: Status & Cleanup

- Create multiple task directories in various states. Run `/jc:status`
- **Pass:** accurate reporting of each task's phase, codebase map status, commit count since last map
- Run `/jc:cleanup`. **Pass:** presents task list with status labels, removes only user-selected directories, commits removal

### Test: Debug

- Introduce a known bug (off-by-one causing test failure). Run `/jc:debug`
- **Pass:** debugger identifies root cause, writes session log to `.planning/{task-id}/debug/`, returns actionable fix

### Test: Team Leader

- Give Team Leader a small feature task on a repo with existing codebase map
- **Pass:** Team Leader checks map freshness, coordinates research → plan (with critique) → commits `.planning/` → creates worktree → executes → verifies → reviews. PLAN.md reflects final state

---

## Risk Considerations

- **Context window pressure:** The Implement skill orchestrates many subagents. Each spawned agent uses context. Monitor for cases where too many parallel executors exhaust available context
- **Agent prompt quality:** The effectiveness of this system hinges entirely on how well the agent `.md` files are written. Plan for iteration
- **Plan document schema stability:** The plan schema is consumed by 5 different consumers (Implement, Resume, Status, Verifier, Reviewer). Changes to the schema require updating all consumers. Get it right in Step 3
- **Error cascading:** If a researcher produces poor output, it cascades through planner → executor. Each agent needs to flag uncertainty rather than propagate garbage. The 3-retry limit with user escalation provides a safety net but doesn't prevent bad research from reaching the planner
- **Resume state consistency:** If the Implement skill crashes mid-update to `PLAN.md`, the plan doc could be in an inconsistent state. The Resume skill handles this by treating `in_progress` tasks with no verification report as needing re-execution
- **Worktree cross-session resume:** When a session ends mid-implementation, the worktree persists but the new session starts in the main tree. `/jc:resume` can detect the worktree but can't switch into it — it must prompt the user to start their session in the worktree directory. UX friction but unavoidable with current tooling
- **Replan state preservation:** When replanning mid-implementation, the Planner must correctly identify which completed tasks are still valid. Conservative approach: only preserve tasks explicitly marked `passed`
- **Codebase map staleness:** The commit-count threshold (50) is a rough proxy. For v1, the threshold is a simple heuristic. User can skip regeneration or run `/jc:map` manually. Can be tuned based on real usage
- **Codebase map size vs context:** The 6 map files will be loaded into the Planner, Reviewer, and Team Leader. Mapper agent should prioritise actionable patterns over exhaustive cataloguing — keep docs concise with file path references rather than inlining large code blocks
- **Plan critique loop cost:** The critique loop adds 2-4 planner invocations per planning cycle. The 1-revision cap prevents runaway loops
- **Critique mode pedantry:** The critic must distinguish between genuine gaps and stylistic preferences. Safeguards: (1) every objection must be backed by evidence, (2) the bar is "would an executor get stuck, build the wrong thing, produce inconsistent code, or fail verification?" If no, it's not an objection. Test 29 specifically validates this calibration
- **Wave review cost vs value:** Wave review adds a Reviewer invocation after each wave. Mitigated by keeping it lightweight (convention check only). Acceptable insurance against systematic drift
- **Greenfield map accuracy:** Prescriptive docs from user input depend on the user knowing what they want upfront. `/jc:map` is cheap to re-run and staleness check will catch drift
