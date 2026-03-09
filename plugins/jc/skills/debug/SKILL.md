---
name: debug
description: "Investigates bugs and failures by spawning the team-debugger agent. Use when encountering test failures, runtime errors, or executor escalations. Do NOT use for code review (use team-reviewer) or implementation (use /jc:implement)."
---

## Path Resolution

Resolve from the skill's base directory (the directory containing this SKILL.md):
- `{plugin-docs}` = `{skill-base-dir}/../../docs/`

## Essential Principles

1. **Always spawn the debugger.** Spawning `team-debugger` ensures a session log for audit trail and consistent scientific-method analysis — always route through it, even for bugs that look trivial.
2. **Collect context first.** Gather the problem description, error output, and any executor escalation details before spawning. The debugger cannot ask for more information — it runs autonomously.
3. **Follow the I/O contract.** Every debugger invocation uses the TaskCreate-with-metadata pattern from `{plugin-docs}/agent-io-contract.md`: create task with structured metadata, spawn agent with task ID only.
4. **One bug, one session.** Each invocation investigates one problem. For multiple failures, investigate sequentially — one spawn per bug.

## Quick Start

1. Identify the task-id from the active `.planning/` directory
2. Collect problem context (error output, failing tests, escalation details)
3. Determine if fix application is needed (`apply-fix: true` or diagnosis only)
4. Spawn `team-debugger` with the I/O contract
5. Present the diagnosis to the user

## Process

### Step 1: Identify Task Context

Determine the task-id for this debug session:

- If invoked during `/jc:implement` execution — use the active task-id from the plan
- If invoked standalone — check `.planning/` for existing task directories. If exactly one exists and is in-progress, use that. If multiple exist, list the available task-ids and ask the user which task via AskUserQuestion. If none exist, ask the user for a task-id or generate one from the problem description

Validate task-id: alphanumeric, hyphens, and underscores only.

### Step 2: Collect Problem Context

Gather all available information before spawning. The debugger runs autonomously — anything not provided in the prompt is unavailable to it.

**Required:**
- Problem description (from user or executor escalation)

**Include if available (omit fields that are not available — the debugger handles missing context):**
- Error output / stack trace (verbatim)
- Failing test name and output
- Executor escalation context: stash ref (from `team-executor` FAIL response), attempted fixes list, failure count
- Relevant file paths mentioned in the error

**Multiple failures:** If the user reports multiple distinct bugs, list them and ask which to investigate first via AskUserQuestion. Debug one at a time per Essential Principle 4.

### Step 3: Determine Fix Mode

Applying changes without consent can disrupt uncommitted work or conflict with an in-flight executor — ask the user via AskUserQuestion:
- **Diagnose only** — debugger investigates and recommends a fix but does not modify source files
- **Diagnose and fix** — debugger investigates, applies the fix if confidence is high or medium, and verifies it passes tests

Map to `apply-fix: true` or `apply-fix: false` in the prompt context.

### Step 4: Spawn Debugger

Create a task and spawn `team-debugger` via the Task tool:

1. `TaskCreate` with:
   - subject: `debug-{task-id}`
   - description: `Investigate: {brief problem description}`
   - metadata: `{"task_id": "{task-id}", "problem_description": "{user's description or executor escalation summary}", "apply_fix": {true|false}}` — also include optional fields if available: `"error_output": "{verbatim error output}"`, `"failing_test": "{test name and command}"`, `"escalation_context": "{stash ref, attempted fixes, failure count}"`

2. Spawn agent with `subagent_type: "team-debugger"`, prompt: `Your task is {task-id-from-TaskCreate}.`

After the agent completes, read results via `TaskGet` — check metadata for `verdict`, `confidence`, and `session_log_path`.

### Step 5: Present Results

Read the debugger's response and present to the user:

**If ROOT_CAUSE_FOUND:**
- Show the root cause, affected file, and recommended fix
- If fix was applied (`apply-fix: true`), confirm it was applied and tests pass
- Show path to the session log for audit trail

**If ESCALATE:**
- Show what was investigated and eliminated
- Show the debugger's best theory and suggested next steps
- Show path to the session log
- Ask the user how to proceed (provide guidance, investigate manually, or skip)

**If ERROR:**
- Show the error details
- Suggest corrective action (e.g., run `/jc:map` if codebase map is missing)

**If spawn fails** (agent not found, Task tool error):
- Report the error to the user
- Suggest checking that the jc plugin is loaded and the `team-debugger` agent exists

## Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|-------------|---------------|
| Debugging directly without spawning the agent | Bypasses session logging, loses audit trail, inconsistent methodology |
| Spawning without collecting error context first | Debugger runs autonomously — missing context means wasted investigation |
| Spawning multiple debuggers for one problem | Fragments the investigation — one bug, one session |
| Skipping the I/O contract format | Debugger may not parse task-id, project root, or context correctly |

## Success Criteria

- Debugger agent spawned with correct I/O contract format (Task, Context, Input, Expected Output)
- Task-id identified and validated before spawning
- All available error context collected and passed to the debugger
- Session log exists at `.planning/{task-id}/debug/` after completion
- Results presented to user with clear next steps
