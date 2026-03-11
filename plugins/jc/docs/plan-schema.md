# Plan Document Schema

Specification for `PLAN.md` — the central planning document produced by the Planner agent.

PLAN.md is a planning document. Execution state lives in TaskList. PLAN.md receives terminal-state checkpoints (`passed`, `skipped`, `manual`) for crash recovery. Both the Implement skill and Team Leader use TaskList for execution and write terminal states to PLAN.md.

Location: `.planning/{task-id}/plans/PLAN.md`

## Structure

```markdown
---
task_id: <string>
title: <string>
status: planning | executing | completed | paused
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
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

## MR Boundaries
<Only present when estimated scope exceeds 200 lines of non-test, non-generated change>
<Groups waves into independently mergeable units — each MR ships a coherent slice>

### MR <n>: <Title>
- **Waves:** <wave numbers included, e.g., 1-2>
- **Estimated lines:** ~<n>
- **Ships:** <what this MR delivers — independently releasable value>
- **Depends on:** <MR number, or "none">

### MR <n+1>: <Title>
...

## Wave <n>: <Wave Title>

### Task <n.m>: <Task Title>
- **Status:** pending | passed | skipped | manual
- **Files affected:** <comma-separated file paths>
- **Action:** <What to do — specific enough for an executor to act without interpretation>
- **Verification:** <Command or check to confirm the task is done>
- **Done when:** <Observable condition — not "code is written" but "test X passes">

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
| `status` | enum | Implement/Leader | Overall plan execution status |
| `created` | ISO 8601 | Planner | When the plan was first written |
| `updated` | ISO 8601 | Any writer | Updated on every modification |
| `pause_reason` | string \| null | Implement/Leader | Why execution was paused. Null when not paused |

### Plan-level sections

| Section | Required | Written by | Description |
|---------|----------|------------|-------------|
| **Goal** | Yes | Planner | Goal-backward statement. What must be true when done |
| **Success Criteria** | Yes | Planner | Numbered, testable outcomes. Verifier checks each one. When acceptance criteria exist (`.planning/{task-id}/ACCEPTANCE-CRITERIA.md`), each should reference the AC it satisfies (e.g., `[AC-1]`). All ACs must be covered by at least one success criterion |
| **Non-Functional Requirements** | Yes | Planner | Security, performance, a11y criteria. "None identified" is valid but must include rationale. Cannot be omitted |

### MR Boundaries section

| Section | Required | Written by | Description |
|---------|----------|------------|-------------|
| **MR Boundaries** | Conditional | Planner | Present only when estimated total scope exceeds 200 lines of non-test, non-generated change. Groups waves into independently mergeable MRs. Each MR must deliver coherent, independently releasable value |

### MR Boundary fields

| Field | Required | Description |
|-------|----------|-------------|
| **Waves** | Yes | Which waves are included in this MR |
| **Estimated lines** | Yes | Rough estimate of non-test, non-generated lines of change |
| **Ships** | Yes | What independently releasable value this MR delivers |
| **Depends on** | Yes | Which prior MR(s) must merge first, or "none" |

### Task fields

| Field | Required | Description |
|-------|----------|-------------|
| **Status** | Yes | Execution state of this task |
| **Files affected** | Yes | All files this task will create or modify. Used for pre-flight overlap detection within a wave |
| **Action** | Yes | Specific instructions for the executor. Must include file paths, patterns to follow, and enough detail that the executor does not need to interpret intent |
| **Verification** | Yes | Command to run or check to perform. Typically a test command |
| **Done when** | Yes | Observable condition tied to verification. Not "code is written" — something provable |

### Task status values

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `passed` | Executor completed, Verifier confirmed |
| `skipped` | User chose to skip after escalation |
| `manual` | User implementing manually |

## Constraints

1. **Task numbering** follows `{wave}.{task}` format (e.g., `1.1`, `1.2`, `2.1`). Sequential within each wave
2. **File overlap prohibition:** No two tasks within the same wave may list the same file in "Files affected". The Planner must ensure this. The Implement skill enforces it at runtime as a fallback
3. **Wave ordering:** Tasks across waves may depend on each other. Tasks within a wave are independent and may run in parallel
4. **Action specificity:** The Action field must not require the executor to make architectural decisions. It should reference specific files, patterns from the codebase map, and exact locations
5. **Verification commands** should be runnable from the project root and produce a clear pass/fail signal
6. **MR Boundaries** are required when estimated total non-test, non-generated lines of change exceed 200. Each MR groups consecutive waves into an independently mergeable unit. MR ordering must respect wave dependencies — a later MR cannot depend on waves in an earlier MR that hasn't been listed as a dependency

## Consumers

| Consumer | Reads | Writes |
|----------|-------|--------|
| **Implement skill** | Full document | Frontmatter status, task terminal status (`passed`, `skipped`, `manual`) |
| **Team Leader** | Full document | Same as Implement |
| **Status skill** | Plan title, pause reason, task count fallback | Nothing (read-only). Reads TaskList for execution state |
| **Verifier agent** | Success Criteria, NFRs, individual tasks | Nothing (writes separate verification reports) |
| **Reviewer agent** | Success Criteria, NFRs, task structure | Nothing (writes separate review reports) |
| **Planner (revise)** | Full document + CRITIQUE.md | Overwrites full document |
