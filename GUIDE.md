# JC Plugin — Skill Guide

A complete reference for every skill in the `jc` plugin. Skills are invoked as `/jc:<skill-name>` in Claude Code.

## Table of Contents

- [Planning Directory](#planning-directory)
- [Workflow Lifecycle](#workflow-lifecycle)
  - [map](#map) — Map a codebase to structured analysis documents
  - [research](#research) — Research a task across 4 dimensions
  - [plan](#plan) — Create an implementation plan with adversarial critique
  - [implement](#implement) — Execute a plan with wave-based parallelization
- [Quality & Debugging](#quality--debugging)
  - [test](#test) — Enforce test quality standards
  - [test-driven-development](#test-driven-development) — Enforce RED-GREEN-REFACTOR TDD discipline
  - [verify-completion](#verify-completion) — Evidence-based completion verification
  - [debug](#debug) — Investigate bugs using the scientific method
- [Release Management](#release-management)
  - [changelog](#changelog) — Generate changelog entries from git history
  - [release](#release) — Bump version, tag, and push a release
- [Housekeeping](#housekeeping)
  - [status](#status) — Report on planning state (read-only)
  - [cleanup](#cleanup) — Remove finished task directories
- [Authoring](#authoring)
  - [author-skill](#author-skill) — Create, edit, audit, and delete skills
  - [author-agent](#author-agent) — Create, edit, audit, and delete agents
- [Typical Workflows](#typical-workflows)

---

## Planning Directory

Skills coordinate through a shared `.planning/` directory at the project root:

```
.planning/
├── codebase/                    # /jc:map output
│   ├── STACK.md
│   ├── INTEGRATIONS.md
│   ├── ARCHITECTURE.md
│   ├── CONVENTIONS.md
│   ├── TESTING.md
│   └── CONCERNS.md
└── {task-id}/                   # one directory per task
    ├── research/                # /jc:research output
    │   ├── approach.md
    │   ├── codebase-integration.md
    │   ├── quality-standards.md
    │   └── risks-edge-cases.md
    ├── PLAN.md                  # /jc:plan output
    ├── PLAN-REVIEW.md           # /jc:implement output
    └── debug/                   # /jc:debug output
        └── session-*.md
```

The codebase map is generated once and tracked for staleness. Task directories are created per feature or bugfix and cleaned up with `/jc:cleanup`.

---

## Workflow Lifecycle

The core pipeline for taking a feature from discovery to implementation. Each skill feeds into the next — see [Typical Workflows](#typical-workflows) for common combinations.

### map

Maps a codebase to produce 6 structured analysis documents in `.planning/codebase/`. Run this once when starting work on a new codebase or when onboarding to a project.

**What it does:**
- Detects whether the project is **brownfield** (existing code) or **greenfield** (empty/new project)
- Brownfield: spawns 4 parallel `team-mapper` agents, each analyzing one dimension
- Greenfield: prompts you for stack decisions and writes prescriptive guides
- Produces 6 files covering technology, architecture, conventions, and concerns
- Commits the map to git for staleness tracking

**Output files:**

| Focus Area | Files |
|-----------|-------|
| Technology | `STACK.md`, `INTEGRATIONS.md` |
| Architecture | `ARCHITECTURE.md` |
| Quality | `CONVENTIONS.md`, `TESTING.md` |
| Concerns | `CONCERNS.md` |

**Usage:**

```
/jc:map
```

No arguments. If `.planning/codebase/` already exists, you'll be asked whether to regenerate or keep the current map.

---

### research

Researches a task across 4 dimensions by spawning parallel `team-researcher` agents. Run this before `/jc:plan` to ensure the plan is grounded in real analysis.

**What it does:**
- Assigns a **task-id** (confirmed with you before proceeding)
- Spawns 4 researcher agents in parallel, each investigating one dimension
- Writes findings to `.planning/{task-id}/research/`
- Commits research output to git

**Default focus areas (customizable):**

| Focus Area | Question |
|-----------|----------|
| approach | What are the viable implementation approaches? |
| codebase-integration | What existing code is affected and how? |
| quality-standards | What are the security, performance, a11y, and testing implications? |
| risks-edge-cases | What could go wrong? |

You can override any focus area before agents are spawned.

**Usage:**

```
/jc:research                          # prompted for task description
/jc:research add OAuth2 support       # task description inline
```

---

### plan

Creates an implementation plan through a plan-critique-revise loop. The planner reads the codebase map and research output — it does not explore the codebase directly.

**What it does:**
- **Hard gates:** Requires both a codebase map (`/jc:map`) and research (`/jc:research`). Won't proceed without them.
- Spawns a `team-planner` agent to create the plan
- Spawns a second planner invocation for **adversarial critique**
- If the critique raises objections, runs one revision round (max 4 planner invocations total)
- Presents a plan summary with critique status

**Plan-critique loop:**

```
Plan → Critique → [if objections] Revise → Re-critique → done
```

**Usage:**

```
/jc:plan                    # auto-detects task-id from .planning/
/jc:plan add-oauth2-support # explicit task-id
```

---

### implement

Orchestrates plan execution through wave-based parallelization with verification, review, and failure handling. This is the most complex skill — it manages the full execution state machine.

**What it does:**
- Commits `.planning/` docs, then creates an **isolated git worktree** for all source changes
- Executes tasks wave-by-wave, respecting file-overlap constraints
- After each task: spawns a `team-verifier` to verify the work
- After each wave: spawns a `team-reviewer` for code review
- After all waves: runs plan-level verification and review in parallel
- Handles retries (max 3 per task), escalation, pause/resume, and crash recovery
- Updates `PLAN.md` at every state transition for reliable recovery

**Execution flow:**

```
INIT → WORKTREE → [WAVE_START → EXECUTE → VERIFY → WAVE_REVIEW] × N → PLAN_VERIFY + PLAN_REVIEW → COMPLETE
```

**Failure handling:**

When a task fails after 3 retries, you're presented with options:
1. **Skip task** — mark it skipped, warns about downstream impact
2. **Provide guidance** — give the executor specific instructions, resets retry counter
3. **Implement manually** — make changes yourself, then resume
4. **Abort execution** — pauses the plan, worktree persists for later resumption

**Usage:**

```
/jc:implement                    # auto-detects task-id
/jc:implement add-oauth2-support # explicit task-id
```

Resuming a paused or interrupted plan uses the same command — the skill detects existing state and resumes from where it left off.

---

## Quality & Debugging

### test

Enforces test quality standards. Use this when writing, reviewing, or evaluating tests. Principles are language-agnostic; the examples below use TypeScript for illustration. For implementation process discipline, use `/jc:test-driven-development`.

**What it does:**
- Guides you toward **behavioral assertions** over internal state checks
- Enforces **minimal mocking** — real code over mocks wherever possible
- Requires **descriptive naming** that describes what broke
- Ensures **no duplicate coverage** — each test verifies a unique behavior
- Provides mock discipline gates and assertion quality checks

**Core rules:**

| Principle | Bad | Good |
|-----------|-----|------|
| Assert behavior | `expect(fn).toHaveBeenCalledTimes(3)` | `expect(attempts).toBe(3)` via real counter |
| Descriptive names | `respects maxAttempts` | `stops retrying after N failures and throws` |
| Real code over mocks | `vi.fn().mockResolvedValue()` | Pass a real async function |
| One behavior per test | `handles retries and logging` | Split into two tests |

**Usage:**

```
/jc:test
```

Not a standalone automation — this is an advisory skill that shapes how tests are written. Often used alongside `/jc:test-driven-development`.

---

### test-driven-development

Enforces the RED-GREEN-REFACTOR TDD cycle. Use when implementing features or bugfixes. For test quality guidance alone, use `/jc:test` instead.

**What it does:**
- **RED:** Write a failing test first. Confirm it fails for the right reason (missing behavior, not syntax error).
- **GREEN:** Write the minimum code to pass the failing test. Nothing more.
- **REFACTOR:** Clean up while tests stay green. No new behavior.
- Enforces strict phase boundaries — no interleaving tests and implementation

**Phase rules:**

| Boundary | Rule |
|----------|------|
| RED → GREEN | Test must be failing before writing implementation |
| GREEN → REFACTOR | All tests must pass before refactoring |
| REFACTOR → RED | No new behavior during refactoring |

**Usage:**

```
/jc:test-driven-development
```

Advisory skill that enforces process discipline during implementation. Works in combination with `/jc:test` for quality.

---

### verify-completion

Evidence-based completion verification. Use when you want to confirm that completed work actually meets its success criteria — not just "looks right."

**What it does:**
- Extracts every success criterion from the plan or task
- Spawns a `general-purpose` agent to **independently gather evidence** (run tests, execute commands, check files)
- Produces a summary table with status per criterion: VERIFIED, PARTIALLY VERIFIED, UNVERIFIED, or FAILED
- Never accepts another agent's claim that "tests pass" — runs them independently

**Usage:**

```
/jc:verify-completion
```

---

### debug

Investigates bugs and failures by spawning the `team-debugger` agent. Follows the scientific method: hypothesis → evidence → conclusion.

**What it does:**
- Collects problem context (error output, stack traces, failing tests) before spawning
- Spawns the debugger agent with a complete I/O contract
- Two modes: **diagnose only** or **diagnose and fix**
- Debugger writes a session log for audit trail
- Returns ROOT_CAUSE_FOUND (with fix details) or ESCALATE (with investigation notes)

**Usage:**

```
/jc:debug                           # prompted for context
/jc:debug tests failing in auth.ts  # problem description inline
```

---

## Release Management

### changelog

Generates CHANGELOG.md entries from git history using [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) format.

**What it does:**
- Finds all commits between the latest git tag and HEAD
- Maps conventional commit prefixes to changelog categories (Added, Changed, Fixed, etc.)
- Deduplicates against existing entries in the Unreleased section
- Rewrites commit messages as clean, user-facing descriptions
- Maintains comparison links at the bottom of the file
- Skips maintenance commits (`chore:`, `ci:`, `test:`, `docs:`, `style:`, `build:`) by default

**Commit prefix mapping:**

| Prefix | Category |
|--------|----------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:`, `perf:` | Changed |
| `deprecated:` | Deprecated |
| `security:` | Security |
| `revert:` | Removed |

Breaking changes (`feat!:`, `fix!:`) are appended with **BREAKING**.

**Usage:**

```
/jc:changelog
```

No arguments. If >100 commits since the last tag, you'll be warned and asked to confirm.

---

### release

Bumps the version, finalizes the changelog, commits, tags, and pushes. Atomic: one commit + one annotated tag per release.

**What it does:**
- Validates a clean working tree (no uncommitted changes)
- Detects the project manifest (`package.json`, `Cargo.toml`, `pyproject.toml`, etc.)
- Resolves the target version from arguments or auto-detects from CHANGELOG.md
- Bumps the version in manifest(s)
- Moves Unreleased entries into a new version section with today's date
- Creates a `release: {version}` commit and `v{version}` annotated tag
- Pushes commit and tag to remote

**Auto-detection logic:**

| Unreleased content | Bump |
|-------------------|------|
| Any `**BREAKING**` entry | major |
| `### Added` section has entries | minor |
| Otherwise | patch |

**Usage:**

```
/jc:release           # auto-detect bump type, confirm with user
/jc:release patch     # explicit patch bump
/jc:release minor     # explicit minor bump
/jc:release major     # explicit major bump
/jc:release 2.0.0     # explicit version
```

---

## Housekeeping

### status

Reports on `.planning/` state without modifying anything. Strictly read-only.

**What it does:**
- Scans `.planning/` for the codebase map (existence, staleness, missing files) and task directories
- Reports each task's phase (Research, Planned, Executing, Paused, Completed) with wave progress, task counts, and verification status
- Directs you to the appropriate skill for any action

**Usage:**

```
/jc:status
```

---

### cleanup

Removes finished task directories from `.planning/` with interactive selection and confirmation. Never touches `codebase/`.

**What it does:**
- Presents a multi-select list of task directories with status labels — you choose which to remove
- Deletes selected directories and commits the removal
- Always asks for confirmation

**Usage:**

```
/jc:cleanup
```

---

## Authoring

### author-skill

Interactive skill for creating, editing, auditing, upgrading, and deleting Claude Code skills.

**What it does:**
- **Create:** Guides you through building a new skill with TDD (baseline without skill → skill works → close loopholes)
- **Edit:** Modify an existing skill with the same TDD discipline
- **Audit:** Run a structural audit via the `audit-skill-auditor` agent
- **Upgrade:** Convert a simple skill to the router pattern (with workflows and references)
- **Delete:** Remove a skill directory with confirmation

Enforces pure Markdown structure, token efficiency, and subagent I/O contract compliance.

**Usage:**

```
/jc:author-skill                                       # prompted for action
/jc:author-skill create a skill for linting PR titles  # create with description
/jc:author-skill edit the changelog skill              # edit existing skill
/jc:author-skill audit the release skill               # run structural audit
/jc:author-skill upgrade the debug skill to router     # convert to router pattern
/jc:author-skill delete the old migration skill        # remove with confirmation
```

---

### author-agent

Interactive skill for creating, editing, auditing, and deleting Claude Code agents.

**What it does:**
- **Create:** Build a new agent with proper execution capability (subagent, forked skill, or team member)
- **Edit:** Modify an existing agent definition
- **Audit:** Run a structural audit via the `audit-agent-auditor` agent
- **Delete:** Remove an agent file with confirmation

Enforces least-privilege tool access, description-driven routing, pure Markdown structure, and I/O contract compliance.

**Usage:**

```
/jc:author-agent                                         # prompted for action
/jc:author-agent create an agent for database migrations # create with description
/jc:author-agent edit the team-executor agent            # edit existing agent
/jc:author-agent audit the team-debugger agent           # run structural audit
/jc:author-agent delete the deprecated formatter agent   # remove with confirmation
```

---

## Typical Workflows

### Full feature implementation

```
/jc:map                              # once per codebase
/jc:research add user dashboard      # research the feature
/jc:plan add-user-dashboard          # create and critique the plan
/jc:implement add-user-dashboard     # execute the plan
```

### Bugfix with TDD

```
/jc:debug session cookie not set     # diagnose the issue
/jc:test-driven-development          # fix with TDD discipline
/jc:verify-completion                # verify the fix meets criteria
```

### Release cycle

```
/jc:changelog                        # generate entries from recent commits
/jc:release                          # bump, tag, push
```

### Check progress

```
/jc:status                           # see where everything stands
/jc:cleanup                          # remove finished tasks
```
