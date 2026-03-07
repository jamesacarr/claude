# Plan Document Schema

Specification for `PLAN.md` — the central plan document produced by the Planner agent and consumed by Implement, Resume, Status, Verifier, and Reviewer.

Location: `.planning/{task-id}/plans/PLAN.md`

## Structure

```markdown
---
task_id: <string>
title: <string>
status: planning | executing | verifying | completed | paused
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
current_wave: <number | null>
current_task: <number | null>
pause_reason: <string | null>
---

# <Title>

## Goal
<1-3 sentences: what must be true when this plan is complete>

## Success Criteria
<Numbered list of observable, testable outcomes>
<When acceptance criteria exist, reference AC IDs in brackets>
1. <criterion> [AC-1]
2. <criterion> [AC-2, AC-3]

## Non-Functional Requirements
<Numbered list of security, performance, a11y criteria — or "None identified" with rationale>
<Each NFR must be testable — not aspirational>
1. <NFR criterion>

## Wave <n>: <Wave Title>
Status: pending | in_progress | completed

### Task <n.m>: <Task Title>
- **Status:** pending | in_progress | passed | failed | skipped | manual
- **Files affected:** <comma-separated file paths>
- **Action:** <What to do — specific enough for an executor to act without interpretation>
- **Verification:** <Command or check to confirm the task is done>
- **Done when:** <Observable condition — not "code is written" but "test X passes">
- **Retries:** <number, default 0>
- **Last failure:** <string | null>

### Task <n.m+1>: <Task Title>
...

## Wave <n+1>: <Wave Title>
...
```

## Field Definitions

### Frontmatter

| Field | Type | Set by | Description |
|-------|------|--------|-------------|
| `task_id` | string | Planner | Matches the `.planning/{task-id}/` directory name |
| `title` | string | Planner | Human-readable task title |
| `status` | enum | Implement/Resume | Overall plan execution status |
| `created` | ISO 8601 | Planner | When the plan was first written |
| `updated` | ISO 8601 | Any writer | Updated on every modification |
| `current_wave` | number \| null | Implement/Resume | Wave currently being executed. Null when not executing |
| `current_task` | number \| null | Implement/Resume | Task currently being executed within the wave. Null when not executing |
| `pause_reason` | string \| null | Implement/Resume | Why execution was paused. Null when not paused |

### Plan-level sections

| Section | Required | Written by | Description |
|---------|----------|------------|-------------|
| **Goal** | Yes | Planner | Goal-backward statement. What must be true when done |
| **Success Criteria** | Yes | Planner | Numbered, testable outcomes. Verifier checks each one. When acceptance criteria exist (`.planning/{task-id}/ACCEPTANCE-CRITERIA.md`), each should reference the AC it satisfies (e.g., `[AC-1]`). All ACs must be covered by at least one success criterion |
| **Non-Functional Requirements** | Yes | Planner | Security, performance, a11y criteria. "None identified" is valid but must include rationale. Cannot be omitted |

### Wave fields

| Field | Values | Set by |
|-------|--------|--------|
| Status | `pending` \| `in_progress` \| `completed` | Implement/Resume |

Waves execute sequentially. All tasks in a wave must complete before the next wave starts.

### Task fields

| Field | Required | Description |
|-------|----------|-------------|
| **Status** | Yes | Execution state of this task |
| **Files affected** | Yes | All files this task will create or modify. Used for pre-flight overlap detection within a wave |
| **Action** | Yes | Specific instructions for the executor. Must include file paths, patterns to follow, and enough detail that the executor does not need to interpret intent |
| **Verification** | Yes | Command to run or check to perform. Typically a test command |
| **Done when** | Yes | Observable condition tied to verification. Not "code is written" — something provable |
| **Retries** | Yes | Number of retry attempts so far. Starts at 0 |
| **Last failure** | No | Most recent failure description. Set by Implement skill on retry |

### Task status values

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in_progress` | Executor currently working on it |
| `passed` | Executor completed, Verifier confirmed |
| `failed` | Exhausted retries, not resolved |
| `skipped` | User chose to skip after escalation |
| `manual` | User implementing manually |

## Constraints

1. **Task numbering** follows `{wave}.{task}` format (e.g., `1.1`, `1.2`, `2.1`). Sequential within each wave
2. **File overlap prohibition:** No two tasks within the same wave may list the same file in "Files affected". The Planner must ensure this. The Implement skill enforces it at runtime as a fallback
3. **Wave ordering:** Tasks across waves may depend on each other. Tasks within a wave are independent and may run in parallel
4. **Action specificity:** The Action field must not require the executor to make architectural decisions. It should reference specific files, patterns from the codebase map, and exact locations
5. **Verification commands** should be runnable from the project root and produce a clear pass/fail signal

## Consumers

| Consumer | Reads | Writes |
|----------|-------|--------|
| **Implement skill** | Full document | Frontmatter status, wave status, task status, retries, last failure |
| **Resume skill** | Full document | Same as Implement |
| **Status skill** | Full document | Nothing (read-only) |
| **Verifier agent** | Success Criteria, NFRs, individual tasks | Nothing (writes separate verification reports) |
| **Reviewer agent** | Success Criteria, NFRs, task structure | Nothing (writes separate review reports) |
| **Planner (revise)** | Full document + CRITIQUE.md | Overwrites full document |
