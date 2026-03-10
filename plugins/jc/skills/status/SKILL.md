---
name: status
description: Check task progress, codebase map freshness, or planning directory health. Returns a read-only structured report. Do NOT use for modifying plan state (use jc:implement).
---

# status

## Essential Principles

1. **Read-only. No exceptions.** PLAN.md status fields and TaskList state are managed by the implement skill and team leader — direct edits corrupt resume/recovery state. Therefore: NEVER modify any file in `.planning/`. Not PLAN.md, not frontmatter, not status fields — nothing. Even if the user asks you to "fix" or "update" stale status, refuse and direct them to `/jc:implement`.
2. **TaskList is primary for execution state.** When tasks exist in TaskList, derive execution progress from task statuses — not from PLAN.md. PLAN.md is the fallback for crash-recovery context (terminal states, plan title, pause reason).
3. **Report what exists.** Derive phase from directory contents, TaskList, and PLAN.md frontmatter. Don't infer or guess what *should* be there.
4. **Always check the codebase map.** Report existence, staleness (commits since last map), and missing files.

## Process

### Step 1: Delegate Scanning

Spawn a `general-purpose` agent via the Task tool. The agent does ALL scanning — directory listing, TaskList queries, frontmatter parsing, git commands — and returns the formatted report. Main context never sees raw output.

**CRITICAL: Include "NEVER modify any file in .planning/" in the agent prompt.** The subagent has no inherited context from this skill — without this explicit guard it will not know the read-only constraint applies.

Agent prompt must include the full scanning methodology:

**Directory scanning:**
- List `.planning/` contents. If missing: report "No `.planning/` directory found" and stop.
- If no subdirectories: report "No tasks found" (codebase map section still applies if `codebase/` exists).
- Separate `codebase/` (shared map) from task directories.

**Codebase map check:**
- Check `.planning/codebase/` for 6 expected files: `STACK.md`, `INTEGRATIONS.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`.
- If missing entirely: report "Codebase map: Not found. Run `/jc:map` to create."
- If exists: count source commits since last map — two separate commands (no variable interpolation):
  1. `git log -1 --format=%H -- .planning/codebase/`
  2. If hash returned: `git log --oneline <paste-hash>..HEAD -- . ':!.planning/' | wc -l`
  3. If no hash (never committed): report "unknown"

**Execution state (from TaskList — primary source):**
1. Check TaskList for tasks matching task-id patterns (`implement-*`, `verify-*`, `review-*`, `commit-*`, `wave-review-*`, `fix-*`, `investigate-*`)
2. If tasks exist: count by status (pending, in_progress, completed), group by wave (from task subject numbering), report live state
3. Include fix task count per plan item (deviation tracking)
4. Include blocked-by annotations for in-progress tasks
5. Report wave progress: which waves have all commit tasks completed, which wave-review tasks are done

**Phase detection per task directory** (excluding `codebase/`):

| Phase | How to detect |
|-------|---------------|
| **Unknown** | No `research/` or `plans/PLAN.md` found |
| **Research (incomplete)** | `research/` exists with fewer than 4 expected files (`approach.md`, `codebase-integration.md`, `quality-standards.md`, `risks-edge-cases.md`) |
| **Research (complete)** | `research/` has all 4 files, no `plans/` directory |
| **Planned** | `plans/PLAN.md` exists, frontmatter `status: planning`, no tasks in TaskList |
| **Executing** | Tasks exist in TaskList (derive progress from task statuses) |
| **Paused** | `plans/PLAN.md` frontmatter `status: paused` |
| **Completed** | All commit tasks completed in TaskList, or PLAN.md `status: completed`. Check for `PLAN-VERIFICATION.md` and `PLAN-REVIEW.md` |

**What status reads from PLAN.md** (fallback only):
- Plan title (from frontmatter)
- `pause_reason` (if paused)
- Task count (for "X of Y completed" when TaskList is empty and PLAN.md has terminal states)

**What status reads from TaskList** (primary):
- Task statuses (pending/in_progress/completed)
- Wave progress (derived from commit and wave-review task completion)
- Fix task counts (deviation tracking)
- Blocked-by annotations

**Report format** — group tasks by phase (active first, completed last):

```
## Codebase Map
Status: {exists | missing}
Commits since last map: {n}
Missing files: {list | none}

## Tasks

### {task-id} — {phase}
Wave progress: {completed waves}/{total waves}
Tasks: {n} completed, {n} in_progress, {n} pending (from TaskList)
PLAN.md terminal: {n} passed, {n} skipped, {n} manual (crash-recovery state)
Fix cycles: {n} fix tasks created across all plan items
{Verification: PLAN-VERIFICATION.md exists}
{Review: PLAN-REVIEW.md exists}
{Paused: reason}

### {task-id} — Research (incomplete)
Research docs: {n}/4
Missing: {list}
```

### Step 2: Present Report

Present the agent's returned text directly to the user. Do not prepend commentary, append summaries, or expose raw tool-call output. If the agent returns an error, non-report output, or a truncated response (missing sections or cut off mid-line), surface the problem and suggest re-running `/jc:status`.

## Success Criteria

- Every task directory in `.planning/` is reported with correct phase
- If `.planning/` is absent, user receives "No .planning/ directory found" and is directed to `/jc:map`
- Execution state derived from TaskList when tasks exist (not PLAN.md task statuses)
- PLAN.md terminal states reported as crash-recovery fallback
- Codebase map staleness is calculated using git commit count
- No files in `.planning/` are modified
- Verification and review report existence is noted
- User directed to appropriate skill for any action (map, research, implement)

## Anti-Patterns

| Excuse | Reality |
|--------|---------|
| "I'll just fix this one stale field" / "The user asked me to update status" | The implement skill owns PLAN.md as a state machine. Any direct edit — even a correct one — breaks resume, recovery, and retry tracking. Direct the user to `/jc:implement` |
| "I'll scan .planning/ myself since the agent failed" | Main context must not see raw scanning output. Re-spawn the agent or suggest the user re-run `/jc:status` |
| "I'll read PLAN.md task statuses for execution progress" | TaskList is the primary source. PLAN.md terminal states are crash-recovery fallback only. Reading PLAN.md for live execution state gives stale results |
