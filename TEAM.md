# JC Plugin — Agent Team Guide

How the agent team works together to take a feature from description to working code on a branch.

## Table of Contents

- [Getting Started](#getting-started)
- [Team Lifecycle](#team-lifecycle)
- [Agent Roster](#agent-roster)
- [Phase Details](#phase-details)
  - [ASSESS](#assess)
  - [MAP](#map)
  - [RESEARCH](#research)
  - [SPIKE](#spike)
  - [PLAN](#plan)
  - [WORKTREE](#worktree)
  - [EXECUTE](#execute)
  - [FINAL](#final)
  - [RETROSPECTIVE](#retrospective)
- [Execution Pipeline](#execution-pipeline)
- [Council Planning](#council-planning)
- [Coordination Model](#coordination-model)
- [Failure Handling](#failure-handling)
- [Smart Resume](#smart-resume)
- [Smart Routing](#smart-routing)

---

## Getting Started

### Start a new feature

Launch the team leader agent and describe the work:

```
claude --agent jc:team-leader
```

```
> Add a /health endpoint that returns service status and uptime
```

The leader will generate a task-id (e.g., `add-health-endpoint`), confirm it with you, then work through the full lifecycle: mapping the codebase, researching the task, planning, and executing.

### Resume interrupted work

If a session is interrupted, start a new leader session in the same project. Smart Resume detects existing `.planning/` state and picks up where it left off:

```
claude --agent jc:team-leader
```

```
> Resume work on add-health-endpoint
```

### Provide external context

You can reference Jira tickets, design docs, or other external inputs when describing the task. The leader passes these to researchers and the criteria generator:

```
> Implement the auth redesign from JIRA-1234. Here's the design doc: docs/auth-redesign.md
```

### Mid-execution interaction

During execution, the leader may ask you to make decisions:

- **Vote tie-break** — if the 3 council planners split 1-1-1, you pick the approach
- **Task escalation** — if a task fails after 3 retries, you choose: skip, guide, fix manually, or abort
- **Systematic failure** — if the leader detects a pattern of failures, you choose: replan, guide, or continue

---

## Team Lifecycle

```
ASSESS ─→ MAP ─→ RESEARCH ─→ SPIKE ─→ PLAN ─→ WORKTREE ─→ EXECUTE ─→ FINAL ─→ RETROSPECTIVE
  │         │        │          │                              │
  │         │        │          └─ skipped if research         │
  │         │        │             is confident                │
  │         │        │                                         │
  │         └─ skipped if map    ┌─────────────────────────────┘
  │            already exists    │
  │                              ▼
  │                        ┌────────────┐
  │                        │ Per wave:  │
  │                        │   EXECUTE  │──→ repeat for
  │                        │   VERIFY   │    each wave
  │                        │   REVIEW   │
  │                        └────────────┘
  │
  └─ determines entry point via Smart Resume
```

**Pre-execution phases** (ASSESS through PLAN) produce documentation only. All source changes happen in an **isolated git worktree** created at the WORKTREE phase.

---

## Agent Roster

### Lifecycle Agents

| Agent | Phase | Lifecycle | What it does |
|-------|-------|-----------|-------------|
| `team-leader` | All | Main session (always running) | Coordinates teammates, owns PLAN.md status, escalates to user |
| `team-mapper` | MAP | 4 spawned in parallel → shut down | Analyses one dimension of the codebase (technology, architecture, quality, concerns) |
| `team-researcher` | RESEARCH | 4 spawned in parallel → shut down | Investigates one dimension of the task (approach, integration, quality, risks) |
| `team-criteria-generator` | PLAN | 1 spawned → shut down | Synthesises acceptance criteria from research and external docs |
| `team-spiker` | SPIKE | 1 spawned → shut down | Validates uncertain assumptions with throwaway PoC code |
| `team-council-planner` | PLAN | 3 spawned → self-manage → shut down | Diverge on approaches, vote, then converge through authorship and critique |
| `team-planner` | PLAN (replan only) | 1 spawned → shut down | Creates revised plan preserving completed work |
| `team-executor` | EXECUTE | N per wave → shut down per wave | Implements a single task using TDD |
| `team-verifier` | EXECUTE, FINAL | 1 spawned on wave 1 → persists all waves | Verifies each task against its spec, then the full plan |
| `team-reviewer` | EXECUTE, FINAL | 1 spawned on wave 1 → persists all waves | Reviews code quality per task, then cross-cutting concerns |
| `team-debugger` | EXECUTE | 1 spawned on first escalation → persists | Investigates failures using scientific method |

### Audit & Authoring Agents

These are not part of the team lifecycle. They're invoked standalone via `/jc:author-skill` and `/jc:author-agent`.

| Agent | What it does |
|-------|-------------|
| `audit-skill-auditor` | Audits skill files for structure, quality, and compliance |
| `audit-agent-auditor` | Audits agent files for structure, completeness, and security |
| `wording-reviewer` | Reviews instructional writing quality in .md files |

---

## Phase Details

### ASSESS

The leader reads `.planning/` state and determines the entry point. If this is a fresh task, the leader generates a task-id (confirmed with you) and evaluates complexity for Smart Routing.

No source files are read — only `.planning/` and `git worktree list`.

### MAP

Produces 6 structured documents in `.planning/codebase/`:

```
4 mapper teammates (parallel)
├── Technology   → STACK.md + INTEGRATIONS.md
├── Architecture → ARCHITECTURE.md
├── Quality      → CONVENTIONS.md + TESTING.md
└── Concerns     → CONCERNS.md
```

Skipped if the map already exists and isn't stale (>50 source commits = stale).

### RESEARCH

Produces 4 research files in `.planning/{task-id}/research/`:

```
4 researcher teammates (parallel)
├── Approach             → approach.md
├── Codebase integration → codebase-integration.md
├── Quality & standards  → quality-standards.md
└── Risks & edge cases   → risks-edge-cases.md
```

### SPIKE

Validates high-uncertainty assumptions flagged by research. The spiker writes minimal throwaway code, runs it, captures output, and cleans up — no code survives this phase.

**Signals that trigger a spike:**
- Research recommends an approach but notes no Context7 coverage or sparse API docs
- Risks flagged with high likelihood and unknown mitigation
- Research references library APIs marked "based on training data"
- Open questions that affect the plan's core approach

Skipped if research is confident (soft gate — you can also skip manually).

### PLAN

Two sub-phases:

1. **Acceptance criteria** — a `team-criteria-generator` synthesises testable criteria from research and any external docs (Jira tickets, requirements). This is a hard gate for planning.

2. **Council planning** — 3 `team-council-planner` agents diverge, vote, then converge. See [Council Planning](#council-planning) for the full flow.

For **replanning** (mid-execution), a single `team-planner` is used instead of the council.

### WORKTREE

The leader commits `.planning/` docs, shuts down all pre-execution teammates, and creates an isolated git worktree. From this point, all source changes happen in the worktree.

### EXECUTE

Wave-by-wave execution with a per-task pipeline. See [Execution Pipeline](#execution-pipeline) for the full flow.

### FINAL

After all waves complete, the leader runs plan-level verification and review in parallel:

- `team-verifier` checks all plan goals, success criteria, and acceptance criteria coverage
- `team-reviewer` does a cross-cutting quality review (test coverage gaps, fragile area impact)

If the reviewer flags blocking issues, the leader assigns an executor to fix them (max 3 rounds).

### RETROSPECTIVE

The leader writes this itself — no teammate is spawned. It evaluates how the team and process performed (not the code), covering:

- Phase decision quality (what was skipped, what should have been)
- Planning accuracy (what the plan assumed vs what happened)
- Pipeline throughput (bounce-back patterns, escalation causes)
- Research effectiveness (did findings hold up during execution?)
- Coordination overhead (message volume, leader interventions)
- Concrete process improvement suggestions referencing specific agent files

---

## Execution Pipeline

Each task flows through a pipeline driven by task creation (not message relaying):

```
┌───────────────────────────────────────────────────┐
│               EXECUTION PIPELINE                  │
│                                                   │
│  Executor                                         │
│  ┌────────────────────────┐                       │
│  │  1. RED   (fail test)  │                       │
│  │  2. GREEN (make pass)  │                       │
│  │  3. REFACTOR           │                       │
│  └────────────┬───────────┘                       │
│               │                                   │
│               ▼ creates verify task               │
│  ┌────────────────────────┐                       │
│  │  Verifier              │                       │
│  │  (goal-backward        │                       │
│  │   evidence check)      │                       │
│  └────────────┬───────────┘                       │
│               │                                   │
│          PASS │           FAIL                    │
│               │        ┌─────→ message executor   │
│               │        │       (fix + re-verify)  │
│               ▼        │                          │
│  ┌────────────────────────┐                       │
│  │  Reviewer              │                       │
│  │  (quality check)       │                       │
│  └────────────┬───────────┘                       │
│               │                                   │
│          PASS │           REVISE                  │
│               │        ┌─────→ message executor   │
│               │        │       (fix + re-verify)  │
│               ▼        │                          │
│  ┌────────────────────────┐                       │
│  │  Executor commits      │                       │
│  │  Messages leader:      │                       │
│  │  "Task N.M committed"  │                       │
│  └────────────────────────┘                       │
│                                                   │
└───────────────────────────────────────────────────┘
```

**Key design decisions:**

- **Task-driven progression.** Each agent creates the next step in the pipeline via `TaskCreate`. The leader doesn't relay between agents.
- **Messages carry content only.** Direct messages between agents carry failure details, review findings, or diagnoses — not status updates.
- **Any fix restarts from verification.** Whether the fix came from the verifier, reviewer, or debugger, the executor always creates a new verify task. The full pipeline re-runs.
- **3-deviation limit.** All fix attempts (from any source) count toward the same 3-attempt limit per task. After 3, the executor escalates to the leader.
- **Persistent verifier and reviewer.** Spawned once at the start of wave 1 and persist across all waves, picking up tasks from TaskList as they appear.
- **On-demand debugger.** Only spawned when the first executor escalation occurs. Persists for the remainder of execution.

---

## Council Planning

Fresh plans use a 3-planner council that diverges, votes, then converges:

```
Phase 1: DIVERGE (parallel)           Phase 2: VOTE (parallel)
┌─────────────┐                      ┌─────────────┐
│  Planner 1  │──→ PROPOSAL-1.md     │  Planner 1  │──→ votes for 2 or 3
│  Planner 2  │──→ PROPOSAL-2.md     │  Planner 2  │──→ votes for 1 or 3
│  Planner 3  │──→ PROPOSAL-3.md     │  Planner 3  │──→ votes for 1 or 2
└─────────────┘                      └─────────────┘
                                            │
                                   ┌────────┴────────┐
                                   │  Resolve vote   │
                                   │  2-1 or 3-0:    │
                                   │   winner leads  │
                                   │  1-1-1:         │
                                   │   user picks    │
                                   └────────┬────────┘
                                            │
Phase 3: CONVERGE (self-managing)           ▼
┌─────────────────────────────────────────────────┐
│  Winner → Author (writes PLAN.md)               │
│  Losers → Critics (write CRITIQUE-{n}.md each)  │
│                                                 │
│  Plan → Critique → [Revise → Re-critique] × 2   │
│                                                 │
│  Both critics sign off → converged              │
│  Unresolved after 2 rounds → escalate to user   │
└─────────────────────────────────────────────────┘
```

Each planner votes for the best proposal **that is not their own**. The council self-manages the plan-critique-revise loop — the leader waits for convergence or escalation.

---

## Coordination Model

### Lead-Delegated Assignment

The leader explicitly assigns tasks to specific teammates. Executors receive exactly 1 task each. This prevents a fast agent from monopolising the task list.

### PLAN.md Status Ownership

Only the leader writes PLAN.md status updates. Teammates report via messaging; the leader writes the status. This prevents race conditions.

```
Task:  pending → in_progress → passed / failed / skipped / manual
Wave:  pending → in_progress → completed
Plan:  planning → executing → verifying → completed / paused
```

### Message Inventory

All messages carry actionable content. No status-only notifications.

| From → To | When | Content |
|-----------|------|---------|
| Executor → Leader | Task committed | Short hash + commit message |
| Executor → Leader | Escalation | Brief reason + learnings path |
| Verifier → Executor | Verify FAIL | Failure details + evidence |
| Reviewer → Executor | Review REVISE | Structured findings (file, line, issue, suggestion) |
| Debugger → Executor | Diagnosis | Root cause + recommended fix |
| Debugger → Leader | Escalation | Unresolved investigation |
| Any → Leader | Stall | "Stalled waiting for {role} on task {n.m}" |
| Council Author ↔ Critics | Plan/critique cycle | Objections or sign-off |

### Stall Detection

Teammate-driven. Each teammate self-reports after 3 consecutive checks with no progress on an expected peer response. The leader intervenes: checks if the teammate is running, messages it, or re-spawns it.

---

## Failure Handling

### Per-Task Retries

Max 3 retries per task (across all sources: verifier, reviewer, debugger). After 3:

| Option | Effect |
|--------|--------|
| **Skip task** | Mark `skipped`, flag downstream dependents |
| **Provide guidance** | User gives hints, retry counter resets |
| **Implement manually** | Mark `manual`, user fixes it |
| **Abort execution** | Pause plan, worktree persists for later resume |

### Systematic Failure Detection

If 2+ consecutive tasks fail for the same root cause, the leader pauses execution and presents the pattern with options:

- Replan remaining tasks (execution learnings inform the replan)
- Provide guidance on the root issue
- Continue as-is

### Executor Escalation

When an executor hits the deviation limit:

1. Writes execution learnings to `.planning/{task-id}/execution/task-{n.m}-learnings.md`
2. Stashes partial work (`git stash`)
3. Creates an investigation task for the debugger
4. Messages the leader

The debugger investigates using scientific method (observe → hypothesize → experiment → conclude) and either messages the executor with a diagnosis or escalates to the leader.

---

## Smart Resume

The leader checks `.planning/` state on startup and routes to the right phase:

| State | Entry Point |
|-------|-------------|
| No codebase map | MAP |
| Map exists, no task-id directory | ASSESS (fresh task) |
| Research exists, no spike report, no PLAN.md | SPIKE (evaluates signals — may skip to PLAN) |
| Research + spike report, no PLAN.md | PLAN |
| PLAN.md exists, no worktree | WORKTREE |
| Worktree exists, pending tasks | EXECUTE (spawn fresh teammates) |
| PLAN.md `status: paused` | EXECUTE (present summary, resume) |
| PLAN.md `status: verifying` | FINAL |
| PLAN.md `status: completed`, no retrospective | RETROSPECTIVE |
| PLAN.md `status: completed`, retrospective exists | Report completion |

Tasks with `status: in_progress` but no verification report are treated as needing re-execution. The leader writes a `LEADER-STATE.md` checkpoint at every wave boundary for crash recovery.

---

## Smart Routing

The leader evaluates task complexity to decide which phases to run:

| Signal | Decision |
|--------|----------|
| Small, single file, well-scoped | May skip research |
| Touches multiple systems or modules | Never skip research |
| References unfamiliar APIs or libraries | Never skip research |
| Ambiguous requirements | Never skip research |
| **Unsure** | **Never skip research** |
| Research confident, all sources cited | Skip spike |
| Research flags "based on training data" | Run spike |
| Unresolved open questions affecting scope | Run spike |
| High-likelihood risks with unknown mitigation | Run spike |
| **Unsure about research confidence** | **Run spike** |

The default is full lifecycle. When a phase is skipped, the leader tells you what was skipped and why.
