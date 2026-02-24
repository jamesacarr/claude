---
name: implement
description: "Orchestrates plan execution through wave-based parallelization with verification, review, and failure handling. Handles both fresh execution and resuming interrupted/paused plans. Use when a PLAN.md exists and the user wants to execute or resume it. Do NOT use for planning (use jc:plan)."
---

## Essential Principles

1. **Worktree-first.** Commit `.planning/` to current branch, THEN create worktree via `EnterWorktree`. All source changes happen in the worktree — never in the main tree. When resuming, route to the existing worktree — never create a new one over it
2. **State machine discipline.** Follow the exact step sequence. Never skip verification, never skip wave review, never improvise transitions
3. **PLAN.md is the source of truth.** Update frontmatter and task/wave status at every state transition. If the session dies, PLAN.md must reflect the last known state for recovery
4. **Verify before re-executing.** When resuming, an `in_progress` task without a verification report is an information gap, not evidence of failure. Run the verifier first — only re-execute if verification fails. Preserve the existing retry counter
5. **Pre-flight before every wave.** Parse "Files affected" from each task. Build file→task map. Sequential fallback for overlapping tasks. Log the fallback
6. **Hard retry limits.** 3 per task (execute→verify→fix loop). 3 per plan-review revision round. After limit: escalate to user via AskUserQuestion — never override
7. **I/O contract compliance.** Every agent invocation includes: Task, Context (task-id, project root, planning directory), Input, Expected Output. Agents read/write files directly — do not relay file contents through the orchestrator

## Quick Start

```
/jc:implement {task-id}

Fresh:  INIT → WORKTREE → [WAVE_START → EXECUTE → VERIFY → WAVE_REVIEW] × N → PLAN_VERIFY + PLAN_REVIEW → COMPLETE
Resume: INIT → ROUTE → RECOVER → [WAVE_START → ...] × remaining → PLAN_VERIFY + PLAN_REVIEW → COMPLETE
```

## Process

### Step 1: INIT — Validate Plan

1. Parse task-id from arguments. If missing, scan `.planning/` for task directories and ask via AskUserQuestion
2. Validate task-id: alphanumeric, hyphens, underscores only
3. Read `.planning/{task-id}/plans/PLAN.md`
   - Missing → error, prompt user to run `/jc:plan`
   - `status: completed` → inform user plan already completed
   - `status: planning` with no `passed` tasks → error, prompt: "Plan not yet executed. Check the plan and re-run `/jc:implement`"
   - `status: planning` with `passed` tasks → replanned mid-execution, go to Step 1a (Resume)
   - `status: executing` or `status: paused` → go to Step 1a (Resume)
   - `status: verifying` → go to Step 7 (PLAN_VERIFY + PLAN_REVIEW) directly — session died during final verification
4. Go to Step 2 (WORKTREE)

### Step 1a: ROUTE — Worktree Detection (Resume Only)

Determine the current environment and route accordingly:

| Condition | Action |
|-----------|--------|
| Already in the task's worktree | Go to Step 1b |
| In main tree, worktree exists (`git worktree list` shows `{task-id}`) | Prompt user: `"Worktree exists at {path}. Start a new session there and re-run: claude --cwd {path}"`. Stop |
| In main tree, no worktree found | Prompt user: `"No worktree found for {task-id}. The previous worktree may have been removed. Re-running will create a fresh worktree."` Go to Step 2 (WORKTREE) |
| In a DIFFERENT worktree | Prompt user: `"You're in worktree {current} but plan is for {task-id}. Switch to the correct worktree."` Stop |

**Detecting worktree:** Run `git worktree list` and check if any entry's path contains `{task-id}`. Check if the current directory is inside a worktree via `git rev-parse --show-toplevel` compared against worktree paths. If `git worktree list` fails with non-zero exit, stop and present the error.

### Step 1b: RECOVER — Build Status Summary (Resume Only)

Parse PLAN.md to determine the exact resume point:

1. **Scan all tasks** — build summary counts:
   - `passed`: completed successfully
   - `skipped` / `manual`: user-resolved
   - `in_progress`: needs recovery (see below)
   - `pending`: not yet started
   - `failed`: exhausted retries

2. **Handle `in_progress` tasks** — check for verification report at `.planning/{task-id}/verification/task-{n}-VERIFICATION.md`:
   - Report exists with PASS → mark task `passed`, update PLAN.md
   - Report exists with FAIL → task needs re-execution (preserve retry counter)
   - No report exists → spawn verifier (`mode: task`) to check current state. If PASS → mark `passed`. If FAIL → re-execute with retry counter preserved. If ERROR → surface error to user with options: retry verification, skip to execution, or abort

3. **Determine resume wave:** First wave with any non-terminal task (`pending`, `in_progress`, `failed`)

4. **Present status summary** to user via AskUserQuestion:

```
Resume Summary for {task-id}: {title}

Completed: {n} passed, {n} skipped, {n} manual
Remaining: {n} pending, {n} in_progress, {n} failed
Resume from: Wave {n}, Task {n.m}
Pause reason: {pause_reason}

Continue execution?
```

Options: "Continue" / "Abort". If user chooses Abort → stop.

5. Get timestamp: call `mcp__time__get_current_time`
6. Update PLAN.md frontmatter: `status: executing`, `updated: <timestamp>`, `current_wave` to resume wave, `current_task: null`
7. Go to Step 3 (WAVE_START) — skip completed waves, within partially-completed waves only execute tasks not `passed`/`skipped`/`manual`. For `failed` tasks: present escalation (Step 5) immediately. Preserve all existing retry counters

### Step 2: WORKTREE — Isolate Execution

1. Stage and commit all `.planning/` files if there are changes: `git add .planning/ && git commit -m "chore: commit planning docs for {task-id}"`. If no `.planning/` changes exist, skip the commit. If commit fails (GPG error, dirty state, no repo): stop and present the error to the user. Do not proceed
2. Call `EnterWorktree` with name `{task-id}`. If it fails (name conflict, git error): stop and present the error. User must resolve or choose a different task-id. If name conflict: suggest `git worktree list` to inspect, `git worktree remove --force {task-id}` to clean up
3. Get timestamp: call `mcp__time__get_current_time`. Update PLAN.md frontmatter: `status: executing`, `current_wave: 1`, `updated: <timestamp>`
4. **Install dependencies** — spawn a `general-purpose` subagent. If install fails, stop and present the error. Do not spawn executors without a working dependency tree

```
## Task
Install project dependencies in the worktree.

## Context
- Project root: {absolute-path}

## Input
- Read {absolute-path}/.planning/codebase/STACK.md to identify the package manager and its install command
- Run the install command from the project root
- If STACK.md doesn't specify a package manager, inspect project files (lock files, manifests) to determine the correct command

## Expected Output
- Dependencies installed successfully
- Structured PASS/FAIL/ERROR result via stdout with the command that was run
```
5. Session is now in the worktree — all subsequent work happens here

### Step 3: WAVE_START — Pre-flight and Execute

For each wave (starting from `current_wave`):

1. Update PLAN.md: wave status → `in_progress`
2. **Pre-flight file overlap check:**
   - For each pending task in this wave, parse "Files affected" into a set
   - Build map: `{file-path} → [task-numbers]`
   - If any file maps to 2+ tasks → those tasks must run sequentially. Log: `"File overlap detected: {file} in tasks {list}. Running sequentially."`
   - If any task has empty or missing "Files affected" → run that task sequentially. Log: `"Task {n.m} has no declared files. Running sequentially as precaution."`
   - Group tasks: parallel group (no overlaps between them) + sequential chain (overlapping tasks in order)
3. Execute each task group:

**For each task:**

a. Update PLAN.md: task status → `in_progress`, `current_task: {n.m}`, `updated: <timestamp>`

b. Spawn `team-executor` via Task tool (`subagent_type: "team-executor"`):

```
## Task
Execute task {n.m} from PLAN.md.

## Context
- Task ID: {task-id}
- Project root: {absolute-path}
- Planning directory: {absolute-path}/.planning

## Input
- Task number: {n.m}
- Plan path: .planning/{task-id}/plans/PLAN.md

## Expected Output
- Atomic commit with files from "Files affected"
- Structured PASS/FAIL/ERROR result via stdout
```

c. Parse executor response:

| Result | Action |
|--------|--------|
| **PASS** | Proceed to verification |
| **FAIL** | If retries < 3: retry (Step 4). If retries ≥ 3: escalate (Step 5) |
| **ERROR** | Escalate (Step 5) |

d. **Verify** — Spawn `team-verifier` (`subagent_type: "team-verifier"`, mode: `task`). Include task number, task-id, project root, planning directory, mode: task. Expected output: verification report + PASS/FAIL/PARTIAL stdout result.

| Result | Action |
|--------|--------|
| **PASS** | Update task status → `passed`. Advance to next task |
| **FAIL** | If retries < 3: retry (Step 4). If retries ≥ 3: escalate (Step 5) |
| **PARTIAL** | Treat as PASS with warning logged. Advance to next task |

### Step 4: TASK_RETRY

1. Increment `Retries` in PLAN.md for this task
2. Record failure in `Last failure` field
3. Update `updated` timestamp
4. Re-spawn executor with previous failure context appended:
   - Add to Input: `- Previous failure: {failure description from verifier/executor}`
   - Add to Input: `- Retry attempt: {n} of 3`
5. Parse executor result at Step 3c (if FAIL and retries ≥ 3 → Step 5, otherwise proceed to verification at Step 3d)

### Step 5: TASK_ESCALATE

1. Update PLAN.md: task status → `failed`, `updated: <timestamp>`
2. Present via AskUserQuestion with these options:

| Option | Label | Action |
|--------|-------|--------|
| 1 | **Skip task** | Mark task `skipped`. Check if downstream tasks (later waves) reference any of this task's "Files affected". If so, warn: `"Tasks {list} may be affected by skipping {n.m}"` |
| 2 | **Provide guidance** | User enters guidance text. Update task: status → `in_progress`, retry counter → 0. Re-execute with guidance appended to Input |
| 3 | **Implement manually** | Mark task `manual`. Inform user to make changes, then re-run `/jc:implement {task-id}` to resume |
| 4 | **Abort execution** | Update PLAN.md: `status: paused`, `pause_reason: "user abort after task {n.m} escalation"`. Stop execution. Worktree persists — re-run `/jc:implement {task-id}` to resume |

### Step 6: WAVE_REVIEW

After all tasks in a wave complete:

1. Update PLAN.md: wave status → `completed`
2. Collect all files changed in this wave (union of "Files affected" from all tasks)
3. Spawn `team-reviewer` (`subagent_type: "team-reviewer"`, mode: `wave`). Include task-id, project root, planning directory, wave number, files changed list. Expected output: PASS/REVISE stdout result.

| Result | Action |
|--------|--------|
| **PASS** | If more waves: increment `current_wave`, go to Step 3. If last wave: go to Step 7 |
| **REVISE** | Spawn executor to fix blocking issues (1 fix round max). Re-run wave review. If still REVISE after fix round: present remaining issues to user, then proceed |

### Step 7: PLAN_VERIFY + PLAN_REVIEW (parallel)

**Plan verification:** Spawn `team-verifier` (`subagent_type: "team-verifier"`, mode: `plan`). Include task-id, project root, planning directory. Expected output: plan verification report + PASS/FAIL/PARTIAL result.

**Plan review:** Spawn `team-reviewer` (`subagent_type: "team-reviewer"`, mode: `plan`). Include task-id, project root, planning directory. Expected output: plan review report + PASS/REVISE result.

**Handle results:**

| Verification | Review | Action |
|-------------|--------|--------|
| PASS | PASS | → COMPLETE (Step 8) |
| PASS | REVISE | Spawn executor to fix blocking issues. Re-run plan review. Max 3 revision rounds, then escalate to user |
| FAIL | any | Escalate to user with verification report. Present options: fix manually, provide guidance, abort |
| PARTIAL | PASS | Warn user about unverifiable criteria. Proceed to COMPLETE |
| PARTIAL | REVISE | Fix review issues first (max 3 rounds), then warn about unverifiable criteria |

### Step 8: COMPLETE

1. Get timestamp: call `mcp__time__get_current_time`
2. Update PLAN.md: `status: completed`, `current_wave: null`, `current_task: null`, `updated: <timestamp>`
3. Report to user:
   - Task-id and plan title
   - Worktree branch name (for merging)
   - Summary: tasks passed / skipped / manual
   - Paths to verification and review reports
4. Suggest: `"Merge the worktree branch back to main when ready. Clean up with: git worktree remove {task-id}"`

## Anti-Patterns

| Anti-Pattern | Correct Behavior |
|-------------|-----------------|
| Executing in main tree "to save time" | Always create worktree — isolation protects main branch |
| Skipping wave review "because tests pass" | Wave review catches convention drift that tests don't cover |
| Retrying past the limit "just one more try" | Hard limit at 3 — escalate to user, never override |
| Parallelizing without pre-flight check | Always check file overlap before spawning executors |
| Updating PLAN.md only at completion | Update at every state transition — crash recovery depends on it |
| Relaying file contents through orchestrator | Agents read/write files directly — send I/O contract fields only |
| Spawning debugger autonomously on failure | Escalate to user — they choose whether to debug, skip, or guide |
| Re-executing `in_progress` tasks without verifying first | Verify first — the executor may have succeeded before the session died |
| Resetting retry counters "for a fresh start" on resume | Preserve counters — they reflect real failure history |
| Creating a new worktree when one already exists for the task | Prompt user to switch to existing worktree — new one loses committed progress |

## Success Criteria

- All source changes exist in a worktree branch, not the main tree
- Every task in PLAN.md has status `passed`, `skipped`, or `manual` — none left `pending` or `in_progress`
- Verification reports exist for every `passed` task and for the plan overall
- Wave review ran after each wave (PASS or issues surfaced to user)
- Plan review report exists at `.planning/{task-id}/reviews/PLAN-REVIEW.md`
- PLAN.md `status: completed` with `current_wave: null`, `current_task: null`
- User received worktree branch name and merge instructions
