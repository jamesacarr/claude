---
name: implement
description: "Orchestrates plan execution through a static task graph with poll-spawn loop. Handles both fresh execution and resuming interrupted/paused plans. Use when a PLAN.md exists and the user wants to execute or resume it. Do NOT use for planning (use jc:plan)."
---

# Implement

## Essential Principles

1. **Worktree-first.** Commit `.planning/` to current branch, THEN create worktree via `EnterWorktree` — so PLAN.md is visible from the worktree without a separate sync step. All source changes happen in the worktree — never in the main tree. When resuming, route to the existing worktree — never create a new one over it
2. **Static task graph.** Create all pipeline tasks upfront with `blockedBy` dependencies. The graph encodes the full pipeline including wave boundaries. Agents discover work by polling TaskList for unblocked tasks — no explicit state machine steps for verify/review/wave-review
3. **TaskList is the execution state.** PLAN.md receives terminal-state checkpoints only (`passed`, `skipped`, `manual`) for crash recovery. No `in_progress` or `failed` writes during execution
4. **Verify before re-executing.** When resuming same-session, TaskList is live — continue from current state. Cross-session: recreate graph from PLAN.md terminal states
5. **Pre-flight at graph creation.** Parse "Files affected" from each task in a wave. Build file→task map. Add `blockedBy` between overlapping implement tasks to force sequential execution. Encoded in the graph, not checked at runtime
6. **Hard retry limits.** 3 per task (fix cycle limit). 3 per plan-review revision round. After limit: escalate to user via AskUserQuestion — never override
7. **I/O contract compliance.** Every agent invocation uses the TaskCreate-with-metadata pattern: create task with structured parameters, spawn agent with task ID only, read results via TaskGet. Agents read/write files directly — do not relay file contents through the orchestrator

## Quick Start

```text
/jc:implement {task-id}

Fresh:  INIT → WORKTREE → GRAPH → EXECUTE (poll-spawn loop) → PLAN_VERIFY + PLAN_REVIEW → COMPLETE
Resume: INIT → WORKTREE → RECOVER → EXECUTE (poll-spawn loop) → PLAN_VERIFY + PLAN_REVIEW → COMPLETE
```

## Process

### Step 1: INIT — Validate Plan

1. Parse task-id from arguments. If missing, scan `.planning/` for task directories and ask via AskUserQuestion
2. If task-id contains characters other than alphanumeric, hyphens, or underscores, stop and ask the user for a valid task-id
3. Read `.planning/{task-id}/plans/PLAN.md`
   - Missing → error, prompt user to run `/jc:plan`
   - `status: completed` → inform user plan already completed
   - `status: planning` with no `passed` tasks → fresh execution, go to Step 2 (WORKTREE)
   - `status: planning` with `passed` tasks → replanned mid-execution, go to Step 1a (Resume)
   - `status: executing` or `status: paused` → go to Step 1a (Resume)
4. Go to Step 2 (WORKTREE)

### Step 1a: ROUTE — Worktree Detection (Resume Only)

Determine the current environment and route accordingly:

| Condition | Action |
|-----------|--------|
| Already in the task's worktree | Go to Step 1b |
| In main tree, worktree exists for `{task-id}` branch | Prompt user: `"Worktree exists at {worktree-path}. Start a new session there and re-run: claude --cwd {worktree-path}"`. Stop |
| In main tree, no worktree found | Prompt user: `"No worktree found for {task-id}. The previous worktree may have been removed. Re-running will create a fresh worktree."` Go to Step 2 (WORKTREE) |
| In a DIFFERENT worktree | Prompt user: `"You're in worktree {current} but plan is for {task-id}. Switch to the correct worktree."` Stop |

**Detecting worktree:** Run `git worktree list` and match by **branch name** — each line has the format `{path}  {commit} [{branch}]`. Find the line where `{branch}` matches `{task-id}` and extract `{path}` from that line. Check if the current directory is inside a worktree via `git rev-parse --show-toplevel` compared against worktree paths. If `git worktree list` fails with non-zero exit, stop and present the error.

### Step 1b: RECOVER — Resume from Existing State

1. **Check TaskList** — if tasks exist matching the task-id patterns (`implement-*`, `verify-*`, `review-*`, `commit-*`, `wave-review-*`):
   - Same-session resume: TaskList is live. Derive state from task statuses and continue to Step 4 (EXECUTE)
2. **If no tasks in TaskList** (cross-session resume):
   - Read PLAN.md terminal states (`passed`, `skipped`, `manual`)
   - Recreate task graph for non-terminal tasks only (Step 3: GRAPH, skipping terminal tasks)
   - Completed tasks from prior waves don't need commit tasks, so next wave's implement tasks unblock immediately
3. Present status summary to user via AskUserQuestion:

```
Resume Summary for {task-id}: {title}

Completed: {n} passed, {n} skipped, {n} manual
Remaining: {n} pending
Resume from: Wave {n}
Pause reason: {pause_reason}

Continue execution?
```

Options: "Continue" / "Abort". If user chooses Abort → stop.

4. Get timestamp: call `mcp__time__get_current_time`
5. Update PLAN.md frontmatter: `status: executing`, `updated: <timestamp>`
6. Go to Step 4 (EXECUTE)

### Step 2: WORKTREE — Isolate Execution

1. Stage and commit all `.planning/` files if there are changes: first `git add .planning/`, then `git commit -m 'chore: commit planning docs for {task-id}'`. If no `.planning/` changes exist, skip the commit. If commit fails (GPG error, dirty state, no repo): stop and present the error to the user. Do not proceed
2. Call `EnterWorktree` with name `{task-id}`. If it fails (name conflict, git error): stop and present the error. User must resolve or choose a different task-id. If name conflict: suggest `git worktree list` to inspect, `git worktree remove --force {task-id}` to clean up
3. **Install dependencies** — spawn a `general-purpose` subagent. If install fails, stop immediately and escalate to the user via AskUserQuestion. Do not retry, do not apply workarounds, do not attempt to fix the issue — even if the fix is known. The user controls dependency decisions. Present the exact error output and offer options: retry with user-provided flags, provide guidance, or abort. Do not spawn executors without a working dependency tree

```
subagent_type: "general-purpose"

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
4. Session is now in the worktree — all subsequent work happens here
5. Go to Step 3 (GRAPH)

### Step 3: GRAPH — Create Static Task Graph

1. Parse all tasks from PLAN.md — extract wave structure and task definitions
2. **Pre-flight file overlap check** for each wave — build `{file-path} → [task-numbers]` map. If any file maps to 2+ tasks, record the sequential fallback
3. Create the full static task graph (all waves) using the creation sequence from agent-io-contract.md:

   For each plan item {n.m}:
   - `TaskCreate(subject: "implement-{n.m}", metadata: {"task_id": "{task-id}", "task_number": "{n.m}", "plan_path": ".planning/{task-id}/plans/PLAN.md"})`
   - `TaskCreate(subject: "verify-{n.m}", metadata: {"mode": "task", "task_id": "{task-id}", "task_number": "{n.m}"})`
   - `TaskCreate(subject: "review-{n.m}", metadata: {"mode": "task", "task_id": "{task-id}", "task_number": "{n.m}"})`
   - `TaskCreate(subject: "commit-{n.m}", metadata: {"task_id": "{task-id}", "task_number": "{n.m}"})`
   - `TaskUpdate(verify-{n.m}, addBlockedBy: [implement-{n.m}])`
   - `TaskUpdate(review-{n.m}, addBlockedBy: [implement-{n.m}])`
   - `TaskUpdate(commit-{n.m}, addBlockedBy: [verify-{n.m}, review-{n.m}])`

   For each wave {n}:
   - `TaskCreate(subject: "wave-review-{n}", metadata: {"mode": "wave", "task_id": "{task-id}", "wave_number": {n}, "files_changed": [<union of "Files affected" for all tasks in wave>]})`
   - `TaskUpdate(wave-review-{n}, addBlockedBy: [commit-{n.1}, commit-{n.2}, ...])` (all commits in wave)

   For cross-wave deps (wave N+1 items):
   - `TaskUpdate(implement-{n+1.m}, addBlockedBy: [wave-review-{n}])`

   For file overlap within a wave:
   - `TaskUpdate(implement-{n.m2}, addBlockedBy: [implement-{n.m1}])` (sequential fallback)

   No owner assignment — the skill tracks which task to spawn next

4. Get timestamp: call `mcp__time__get_current_time`
5. Update PLAN.md: `status: executing`, `updated: <timestamp>`
6. Go to Step 4 (EXECUTE)

### Step 4: EXECUTE — Poll-Spawn Loop

Run a generic poll-spawn loop driven by TaskList. The task graph encodes the full pipeline including wave boundaries — no explicit state machine steps needed.

**Loop:**
1. Poll TaskList for unblocked, non-completed tasks (no `[blocked by]` annotation)
2. Determine subagent type from task subject prefix:

   | Prefix | Subagent | Notes |
   |--------|----------|-------|
   | `implement-*` | `team-executor` | Implementation |
   | `verify-*` | `team-verifier` | Task verification |
   | `review-*` | `team-reviewer` | Per-task review (mode: task) |
   | `commit-*` | `team-executor` | Commit after verify+review pass |
   | `wave-review-*` | `team-reviewer` | Wave review (mode: wave) |
   | `fix-*` | `team-executor` | Fix from verifier/reviewer |
   | `investigate-*` | `team-debugger` | Debug investigation |

3. Spawn subagent: `Agent(subagent_type, prompt: "Your task is {task-id}.")`

   **Parallelism within a wave:** Multiple implement tasks in the same wave may be unblocked simultaneously (if no file overlap). Spawn executor subagents in parallel. Similarly, verify and review for the same plan item are both unblocked after implement completes — spawn both in parallel.

4. On subagent completion: read `TaskGet` for result metadata

5. **Handle results by task type:**
   - **commit task completed:** update PLAN.md task status to `passed` (terminal checkpoint), update `updated` timestamp
   - **investigate task completed:** check metadata verdict — if ESCALATE, present user with options (skip/guidance/manual/abort). If ROOT_CAUSE_FOUND, the executor's task auto-unblocks and will appear in the next poll
   - **wave-review REVISE:** spawn executor to fix, re-spawn reviewer (max 3 rounds). If still REVISE: present remaining issues to user, then advance
   - **skip/manual:** complete all 4 static tasks in the chain (implement, verify, review, commit) with `metadata: {"verdict": "skipped"}` or `{"verdict": "manual"}`. Update PLAN.md task status. If ALL tasks in a wave are skipped/manual, also complete the wave-review task

6. **Escalation** (deviation limit or user request):

   | Option | Label | Action |
   |--------|-------|--------|
   | 1 | **Skip task** | Complete all 4 static tasks + wave-review with verdict, mark PLAN.md `skipped`. Warn about downstream dependents |
   | 2 | **Provide guidance** | User enters guidance. Relevant fix task gets context in metadata |
   | 3 | **Implement manually** | Complete all 4 static tasks, mark PLAN.md `manual` |
   | 4 | **Abort execution** | Update PLAN.md: `status: paused`, `pause_reason`. Stop |

7. Repeat until all tasks completed (graph gates wave progression automatically)
8. Proceed to Step 5 (PLAN_VERIFY + PLAN_REVIEW)

### Step 5: PLAN_VERIFY + PLAN_REVIEW (parallel)

**Plan verification:**

1. `TaskCreate` with:
   - subject: `verify-plan-{task-id}`
   - description: `Verify plan for {task-id}`
   - metadata: `{"mode": "plan", "task_id": "{task-id}"}`

2. Spawn agent with `subagent_type: "team-verifier"`, prompt: `Your task is {task-id-from-TaskCreate}.`

**Plan review:**

1. `TaskCreate` with:
   - subject: `review-plan-{task-id}`
   - description: `Review plan for {task-id}`
   - metadata: `{"mode": "plan", "task_id": "{task-id}"}`

2. Spawn agent with `subagent_type: "team-reviewer"`, prompt: `Your task is {task-id-from-TaskCreate}.`

Spawn both in parallel. After each completes, read results via `TaskGet` — check metadata for `verdict`.

**Handle results:**

| Verification | Review | Action |
|-------------|--------|--------|
| PASS | PASS | → COMPLETE (Step 6) |
| PASS | REVISE | Create task and spawn executor to fix blocking issues via TaskCreate (include reviewer findings in metadata as `previous_failure`). Re-run plan review via TaskCreate + spawn. Max 3 revision rounds, then escalate to user |
| FAIL | any | Escalate to user with verification report. Present options: fix manually, provide guidance, abort |
| PARTIAL | PASS | Warn user about unverifiable criteria. Proceed to COMPLETE |
| PARTIAL | REVISE | Fix review issues via TaskCreate + executor spawn (max 3 rounds), then warn about unverifiable criteria |

### Step 6: COMPLETE

1. Get timestamp: call `mcp__time__get_current_time`
2. Update PLAN.md: `status: completed`, `updated: <timestamp>`
3. Report to user:
   - Task-id and plan title
   - Worktree branch name (for merging)
   - Summary: tasks passed / skipped / manual
   - Paths to verification and review reports
4. Determine the worktree path by running `git worktree list` and matching the `{task-id}` branch name. Suggest: `"Merge the worktree branch back to main when ready. Clean up with: git worktree remove {worktree-path}"`

## Anti-Patterns

| Anti-Pattern | Correct Behavior |
|-------------|-----------------|
| Executing in main tree "to save time" | Always create worktree — isolation protects main branch |
| Explicit state machine for verify/review/wave-review | Use the poll-spawn loop — the task graph encodes progression |
| Tracking `current_wave` / `current_task` in PLAN.md | TaskList is execution state. PLAN.md gets terminal checkpoints only |
| Parallelizing without pre-flight check | Always check file overlap at graph creation time |
| Writing `in_progress` or `failed` to PLAN.md | Only write terminal states: `passed`, `skipped`, `manual` |
| Creating verify/review/commit tasks dynamically | All pipeline tasks are pre-created in the static graph |
| Spawning debugger autonomously on failure | Escalate to user — they choose whether to debug, skip, or guide |
| Creating a new worktree when one already exists | Prompt user to switch to existing worktree |
| Retrying dependency install failures | Stop immediately, escalate to user |

## Success Criteria

- Every task in PLAN.md has terminal status (`passed`, `skipped`, or `manual`) — none left `pending`
- Verification reports exist for every `passed` task and for the plan overall
- Wave review ran after each wave (via `wave-review-{n}` tasks in the graph)
- Plan review report exists at `.planning/{task-id}/reviews/PLAN-REVIEW.md`
- TaskList shows all tasks completed at end of execution
