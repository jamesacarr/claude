# JC Plugin — Agent Team Guide

How the agent team works together to take a feature from description to working code on a branch, or shape an epic into actionable tickets.

## Table of Contents

- [Agent Roster](#agent-roster)
  - [Implementation Agents](#implementation-agents)
  - [Refinement Agents](#refinement-agents)
- [Implementation](#implementation)
  - [Getting Started](#getting-started)
  - [Lifecycle](#lifecycle)
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
    - [Lead-Delegated Assignment](#lead-delegated-assignment)
    - [PLAN.md Status Ownership](#planmd-status-ownership)
    - [Message Inventory](#message-inventory)
    - [Stall Detection](#stall-detection)
  - [Failure Handling](#failure-handling)
    - [Per-Task Retries](#per-task-retries)
    - [Systematic Failure Detection](#systematic-failure-detection)
    - [Executor Escalation](#executor-escalation)
  - [Smart Resume](#smart-resume)
  - [Smart Routing](#smart-routing)
- [Epic Refinement](#epic-refinement)
  - [Getting Started (Refinement)](#getting-started-refinement)
  - [Lifecycle (Refinement)](#lifecycle-refinement)
  - [Shaper Personas](#shaper-personas)
  - [Phase Details (Refinement)](#phase-details-refinement)
    - [ASSESS (Refinement)](#assess-refinement)
    - [MAP (Refinement)](#map-refinement)
    - [Sufficiency Loop](#sufficiency-loop)
    - [Discussion — Round 1](#discussion--round-1)
    - [Discussion — Round 2](#discussion--round-2)
    - [Discussion — Round 3](#discussion--round-3)
    - [Retrospective (Refinement)](#retrospective-refinement)
  - [Coordination Model (Refinement)](#coordination-model-refinement)
    - [Convergence Detection](#convergence-detection)
    - [Stall Detection (Refinement)](#stall-detection-refinement)
    - [Spike Requests](#spike-requests)
  - [Output Artifacts](#output-artifacts)

---

## Agent Roster

### Implementation Agents

| Agent | Phase | Lifecycle | What it does |
|-------|-------|-----------|-------------|
| `team-leader` | All | Main session (always running) | Coordinates teammates, writes PLAN.md terminal-state checkpoints, escalates to user |
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

### Refinement Agents

| Agent | Lifecycle | What it does |
|-------|-----------|-------------|
| `team-refinement-leader` | Main session (always running during refinement) | Orchestrates shapers through sufficiency, discussion, and convergence. Never participates in shaping |
| `team-refinement-panelist` | 4 spawned initially, 5th joins in Round 2 → shut down after Round 3 | Analyses epics from a specific persona's lens (Product Analyst, Technical Architect, Delivery Strategist, Risk Analyst, Tech Debt Scout) |

---

## Implementation

### Getting Started

#### Start a new feature

Launch the team leader agent and describe the work:

```
claude --agent jc:team-leader
```

```
> Add a /health endpoint that returns service status and uptime
```

The leader will generate a task-id (e.g., `add-health-endpoint`), confirm it with you, then work through the full lifecycle: mapping the codebase, researching the task, planning, and executing.

#### Resume interrupted work

If a session is interrupted, start a new leader session in the same project. Smart Resume detects existing `.planning/` state and picks up where it left off:

```
claude --agent jc:team-leader
```

```
> Resume work on add-health-endpoint
```

#### Provide external context

You can reference Jira tickets, design docs, or other external inputs when describing the task. The leader passes these to researchers and the criteria generator:

```
> Implement the auth redesign from JIRA-1234. Here's the design doc: docs/auth-redesign.md
```

#### Mid-execution interaction

During execution, the leader may ask you to make decisions:

- **Vote tie-break** — if the 3 council planners split 1-1-1, you pick the approach
- **Task escalation** — if a task fails after 3 retries, you choose: skip, guide, fix manually, or abort
- **Systematic failure** — if the leader detects a pattern of failures, you choose: replan, guide, or continue

---

### Lifecycle

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

### Phase Details

#### ASSESS

The leader reads `.planning/` state and determines the entry point. If this is a fresh task, the leader generates a task-id (confirmed with you) and evaluates complexity for Smart Routing.

No source files are read — only `.planning/` and `git worktree list`.

#### MAP

Produces 6 structured documents in `.planning/codebase/`:

```
4 mapper teammates (parallel)
├── Technology   → STACK.md + INTEGRATIONS.md
├── Architecture → ARCHITECTURE.md
├── Quality      → CONVENTIONS.md + TESTING.md
└── Concerns     → CONCERNS.md
```

Skipped if the map already exists and isn't stale (>50 source commits = stale).

#### RESEARCH

Produces 4 research files in `.planning/{task-id}/research/`:

```
4 researcher teammates (parallel)
├── Approach             → approach.md
├── Codebase integration → codebase-integration.md
├── Quality & standards  → quality-standards.md
└── Risks & edge cases   → risks-edge-cases.md
```

#### SPIKE

Validates high-uncertainty assumptions flagged by research. The spiker writes minimal throwaway code, runs it, captures output, and cleans up — no code survives this phase.

**Signals that trigger a spike:**
- Research recommends an approach but notes no Context7 coverage or sparse API docs
- Risks flagged with high likelihood and unknown mitigation
- Research references library APIs marked "based on training data"
- Open questions that affect the plan's core approach

Skipped if research is confident (soft gate — you can also skip manually).

#### PLAN

Two sub-phases:

1. **Acceptance criteria** — a `team-criteria-generator` synthesises testable criteria from research and any external docs (Jira tickets, requirements). This is a hard gate for planning.

2. **Council planning** — 3 `team-council-planner` agents diverge, vote, then converge. See [Council Planning](#council-planning) for the full flow.

For **replanning** (mid-execution), a single `team-planner` is used instead of the council.

#### WORKTREE

The leader commits `.planning/` docs, shuts down all pre-execution teammates, and creates an isolated git worktree. From this point, all source changes happen in the worktree.

#### EXECUTE

Execution via a static task graph with `blockedBy` dependencies. See [Execution Pipeline](#execution-pipeline) for the full flow.

#### FINAL

After all waves complete, the leader runs plan-level verification and review in parallel:

- `team-verifier` checks all plan goals, success criteria, and acceptance criteria coverage
- `team-reviewer` does a cross-cutting quality review (test coverage gaps, fragile area impact)

If the reviewer flags blocking issues, the leader assigns an executor to fix them (max 3 rounds).

#### RETROSPECTIVE

The leader writes this itself — no teammate is spawned. It evaluates how the team and process performed (not the code), covering:

- Phase decision quality (what was skipped, what should have been)
- Planning accuracy (what the plan assumed vs what happened)
- Pipeline throughput (bounce-back patterns, escalation causes)
- Research effectiveness (did findings hold up during execution?)
- Coordination overhead (message volume, leader interventions)
- Concrete process improvement suggestions referencing specific agent files

---

### Execution Pipeline

All pipeline tasks are pre-created in a **static task graph** with `blockedBy` dependencies. Agents discover work by polling TaskList for unblocked tasks — no agent creates successor pipeline tasks.

```
┌────────────────────────────────────────────────────────┐
│                  STATIC TASK GRAPH                     │
│                                                        │
│  Per plan item:                                        │
│                                                        │
│  implement-{n.m}                                       │
│       │                                                │
│       ▼                                                │
│  verify-{n.m} ──── review-{n.m}   (parallel,           │
│       │               │            both blockedBy      │
│       │               │            implement)          │
│       ▼               ▼                                │
│         commit-{n.m}               (blockedBy          │
│               │                     verify + review)   │
│               │                                        │
│  Per wave:    ▼                                        │
│         wave-review-{n}            (blockedBy          │
│               │                     all wave commits)  │
│               ▼                                        │
│  Next wave's implement tasks unblock                   │
│                                                        │
│  Fix cycles (dynamic):                                 │
│  ┌────────────────────────────────────────────┐        │
│  │  Verifier FAIL → creates fix-{n.m}-v{n}    │        │
│  │    → blocks verify (held open)             │        │
│  │    → executor fixes → verify unblocks      │        │
│  │                                            │        │
│  │  Reviewer REVISE → creates fix-{n.m}-r{n}  │        │
│  │    → blocks review (held open)             │        │
│  │    → executor fixes → review unblocks      │        │
│  └────────────────────────────────────────────┘        │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Key design decisions:**

- **Graph-driven progression.** All pipeline tasks (implement, verify, review, commit, wave-review) are pre-created with `blockedBy` dependencies. No agent creates successor tasks — the graph handles progression.
- **Messages carry content only.** Direct messages between agents carry failure details or review findings — not status updates.
- **Fix tasks block the parent.** On FAIL/REVISE, verifier/reviewer holds their task open and creates a dynamic fix task that blocks it. When the executor completes the fix, the parent unblocks and re-checks automatically.
- **3-deviation limit.** All fix attempts (from any source) count toward the same 3-attempt limit per task. After 3, the executor escalates to the leader.
- **Persistent verifier and reviewer.** Spawned once at the start of wave 1 and persist across all waves, picking up unblocked tasks from TaskList.
- **On-demand debugger.** Only spawned when the first executor escalation occurs. Persists for the remainder of execution.

---

### Council Planning

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

### Coordination Model

#### Lead-Delegated Assignment

The leader explicitly assigns tasks to specific teammates. Executors receive exactly 1 task each. This prevents a fast agent from monopolising the task list.

#### PLAN.md Status Ownership

Only the leader writes PLAN.md status updates. PLAN.md receives terminal-state checkpoints only — execution state lives in TaskList.

```
Task:  pending → passed / skipped / manual   (terminal states only)
Plan:  planning → executing → completed / paused
```

#### Message Inventory

All messages carry actionable content. No status-only notifications.

| From → To | When | Content |
|-----------|------|---------|
| Executor → Leader | Task committed | Short hash + commit message |
| Executor → Leader | Escalation | Brief reason + learnings path |
| Verifier → Executor | Alongside fix task | Failure details + evidence |
| Reviewer → Executor | Alongside fix task | Structured findings (file, line, issue, suggestion) |
| Debugger → Leader | Escalation | Unresolved investigation |
| Any → Leader | Stall | "Stalled waiting for {role} on task {n.m}" |
| Council Author ↔ Critics | Plan/critique cycle | Objections or sign-off |

#### Stall Detection

Teammate-driven. Each teammate self-reports after 3 consecutive checks with no progress on an expected peer response. The leader intervenes: checks if the teammate is running, messages it, or re-spawns it.

---

### Failure Handling

#### Per-Task Retries

Max 3 retries per task (across all sources: verifier, reviewer, debugger). After 3:

| Option | Effect |
|--------|--------|
| **Skip task** | Mark `skipped`, flag downstream dependents |
| **Provide guidance** | User gives hints, retry counter resets |
| **Implement manually** | Mark `manual`, user fixes it |
| **Abort execution** | Pause plan, worktree persists for later resume |

#### Systematic Failure Detection

If 2+ consecutive tasks fail for the same root cause, the leader pauses execution and presents the pattern with options:

- Replan remaining tasks (execution learnings inform the replan)
- Provide guidance on the root issue
- Continue as-is

#### Executor Escalation

When an executor hits the deviation limit:

1. Writes execution learnings to `.planning/{task-id}/execution/task-{n.m}-learnings.md`
2. Stashes partial work (`git stash`)
3. Creates an investigation task for the debugger
4. Messages the leader

The debugger investigates using scientific method (observe → hypothesize → experiment → conclude) and either messages the executor with a diagnosis or escalates to the leader.

---

### Smart Resume

The leader checks `.planning/` state on startup and routes to the right phase:

| State | Entry Point |
|-------|-------------|
| No codebase map | MAP |
| Map exists, no task-id directory | ASSESS (fresh task) |
| Research exists, no spike report, no PLAN.md | SPIKE (evaluates signals — may skip to PLAN) |
| Research + spike report, no PLAN.md | PLAN |
| PLAN.md exists, no worktree | WORKTREE |
| Worktree exists, pending tasks or non-terminal TaskList tasks | EXECUTE (create/resume graph, spawn fresh teammates) |
| PLAN.md `status: paused` | EXECUTE (present summary, resume) |
| All wave-review tasks completed in TaskList | FINAL (plan-level verification) |
| PLAN.md `status: completed`, no retrospective | RETROSPECTIVE |
| PLAN.md `status: completed`, retrospective exists | Report completion |

If resuming cross-session (TaskList gone), the leader reads PLAN.md terminal states and recreates the graph for non-terminal tasks only. The leader writes a `LEADER-STATE.md` checkpoint at every wave boundary for crash recovery.

---

### Smart Routing

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

---

## Epic Refinement

A separate workflow from the implementation lifecycle. The refiner → shapers pipeline shapes epics into small, actionable, independently releasable tickets before implementation begins.

### Getting Started (Refinement)

The refiner is spawned as a team member — it's not invoked directly via a skill yet. The calling context provides an epic-id and description. All artifacts are written to `.planning/epics/{epic-id}/`.

### Lifecycle (Refinement)

```
ASSESS → MAP (if needed) → SUFFICIENCY LOOP → DISCUSSION (Round 1 → Round 2 → Round 3) → RETROSPECTIVE
```

The **team-refinement-leader** is the orchestration lead. It manages the process — spawning shapers, monitoring discussion, detecting convergence and stalls, writing ticket files, and producing the final epic overview. It never participates in shaping.

**team-refinement-panelist** agents are persona-bound analysts. Each evaluates the epic through one lens. See [Shaper Personas](#shaper-personas).

---

### Shaper Personas

| Persona | Focus |
|---------|-------|
| Product Analyst | User value, acceptance criteria, feature completeness |
| Technical Architect | System design, dependencies, integration points, feasibility |
| Delivery Strategist | Sequencing, dependency ordering, incremental deployability, ticket sizing |
| Risk Analyst | Edge cases, failure modes, security, performance, rollback |
| Tech Debt Scout | Existing debt in affected areas, cleanup opportunities, debt prevention |

The first four are spawned at the start of the sufficiency loop. The Tech Debt Scout joins at the start of Round 2 — it needs the other shapers' proposals to know which areas of the codebase to examine.

---

### Phase Details (Refinement)

#### ASSESS (Refinement)

The refiner checks for an existing codebase map and creates the output directory structure under `.planning/epics/{epic-id}/`.

#### MAP (Refinement)

If no codebase map exists, the refiner spawns 4 `team-mapper` agents (same as the implementation lifecycle). Skipped if the map already exists.

#### Sufficiency Loop

The refiner spawns 4 shapers (all except Tech Debt Scout) and asks each to assess whether there is enough information to break the epic into tickets. Unanimous consent is required. If any shaper says "Insufficient," the refiner consolidates and deduplicates their questions, reports them back to the caller (who relays to the user), and reassesses on receiving answers. Max 3 rounds — after 3, shapers proceed with stated assumptions.

#### Discussion — Round 1

Each shaper proposes their view of the ticket breakdown from their persona's lens. Proposals are broadcast to all peers.

#### Discussion — Round 2

The Tech Debt Scout joins as a 5th shaper. All shapers react to each other's proposals — challenging, agreeing, refining, and proposing new tickets. The refiner monitors for convergence and writes agreed tickets incrementally to disk as consensus forms. See [Coordination Model (Refinement)](#coordination-model-refinement) for convergence, stall, and spike mechanics.

#### Discussion — Round 3

The refiner writes `EPIC-OVERVIEW.md` with a summary, dependency graph, and noted dissent. All 5 shapers review the complete ticket set for completeness and correctness. 4/5 agreement is sufficient — dissent is recorded with reasoning.

#### Retrospective (Refinement)

The refiner shuts down all shapers and writes a retrospective evaluating:

- Sufficiency quality (right questions? too many rounds?)
- Discussion quality (did each persona contribute meaningfully?)
- Convergence smoothness (stalls, escalations, exchange count)
- Ticket quality (did Round 3 surface significant issues?)
- Spike effectiveness (did spikes change the outcome?)
- Tech debt integration (did the Scout add value?)
- Process improvements (referencing specific agent files and workflow steps)

---

### Coordination Model (Refinement)

```
┌──────────────────────────────────────────────────────────────────────┐
│                         EPIC REFINEMENT                              │
│                                                                      │
│  Refiner (orchestration only — never shapes)                         │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  SUFFICIENCY                                                   │  │
│  │  Spawns 4 shapers → collects assessments → unanimous consent   │  │
│  │  (max 3 rounds with user Q&A)                                  │  │
│  └──────────────────────┬─────────────────────────────────────────┘  │
│                         │                                            │
│                         ▼                                            │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  ROUND 1: Each shaper proposes ticket breakdown                │  │
│  └──────────────────────┬─────────────────────────────────────────┘  │
│                         │                                            │
│                         ▼                                            │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  ROUND 2: Tech Debt Scout joins → all 5 shapers discuss        │  │
│  │                                                                │  │
│  │  Shapers ←→ Shapers (broadcast messages)                       │  │
│  │     │                                                          │  │
│  │     ├─ Agree → refiner writes ticket file                      │  │
│  │     ├─ Stall → refiner escalates to user                       │  │
│  │     └─ Spike needed → refiner spawns spiker, relays results    │  │
│  │                                                                │  │
│  │  Converged when: no new proposals, no concerns, no challenges  │  │
│  └──────────────────────┬─────────────────────────────────────────┘  │
│                         │                                            │
│                         ▼                                            │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  ROUND 3: All 5 shapers review complete ticket set             │  │
│  │  4/5 agreement sufficient — dissent recorded                   │  │
│  └──────────────────────┬─────────────────────────────────────────┘  │
│                         │                                            │
│                         ▼                                            │
│  RETROSPECTIVE: refiner evaluates process, shuts down all shapers    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

#### Convergence Detection

The refiner reads all shapers' latest messages. Converged when:
- No new ticket proposals in any shaper's latest Position section
- No open concerns listed (or all concerns are "None")
- No active challenges listed (or all challenges are "None")
- All shapers signal agreement or note dissent

#### Stall Detection (Refinement)

Same disagreement relitigated across 2+ exchanges with no new arguments. The refiner pauses discussion, reports the deadlock to the caller (which shapers, which ticket, each position), and waits for resolution guidance before resuming.

#### Spike Requests

Any shaper can create a `spike:` task via TaskCreate when an assumption can't be resolved through discussion or codebase reading. The refiner detects the task, pauses discussion, spawns a `team-spiker`, and relays results to all shapers before resuming.

---

### Output Artifacts

All artifacts are written to `.planning/epics/{epic-id}/`:

| Artifact | Description |
|----------|-------------|
| `EPIC-OVERVIEW.md` | Summary, dependency graph, noted dissent, spike results |
| `tickets/TICKET-{nn}-{slug}.md` | Individual ticket files with user statement, acceptance criteria, dependencies, approach, risk flags |
| `CONSENSUS-BOARD.md` | Ticket agreement tracking (internal to refiner) |
| `REFINER-STATE.md` | Phase state for compression recovery |
| `RETROSPECTIVE.md` | Process evaluation across 7 dimensions |
| `spikes/spike-{n}.md` | Spike reports (if any were run) |
