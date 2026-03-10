# Agent I/O Contract

Standard calling convention for all JC team agents. Every agent invocation — whether via Task tool (skill orchestration) or Agent Team (Team Leader coordination) — uses Task metadata as the primary assignment and result channel.

## Invocation Format

When spawning an agent via the Task tool, the orchestrator (skill or leader) follows this two-step pattern:

### Step 1: Create task with metadata

```
TaskCreate(
  subject: "<descriptive subject>",
  description: "<what the agent should do>",
  metadata: {
    "<key>": "<value>",
    ...
  }
)
```

Metadata contains all structured parameters the agent needs — paths, focus areas, mode flags, descriptions. Each agent's `.md` file defines an **Assignment** section with the metadata keys it expects (required and optional).

### Step 2: Spawn agent with task ID only

```
Agent tool with subagent_type: "<agent-type>", prompt: "Your task is <task-id-from-TaskCreate>."
```

The spawn prompt is minimal — just the task ID. The agent calls `TaskGet` to read its full assignment from the task metadata.

### Reading results

After the agent completes, the orchestrator reads results via `TaskGet` on the same task. Agents call `TaskUpdate` on completion with structured result metadata (verdicts, paths, hashes, etc.). Each agent's `.md` file documents its completion metadata contract.

## Output Convention

Agents produce output in three ways:

### Task metadata (primary for structured results)
Agents report completion via `TaskUpdate(taskId, status: completed, metadata: {...})`. The orchestrator reads results via `TaskGet`. This is the canonical channel for structured data (verdicts, commit hashes, report paths, etc.).

### File output (primary for documents)
Agents write structured documents directly to `.planning/`. The orchestrator does NOT relay file content — agents write files themselves to minimise context transfer.

After writing, agents return a **short confirmation** to the orchestrator:
```
Done. Wrote:
- .planning/codebase/STACK.md
- .planning/codebase/INTEGRATIONS.md
```

### Stdout output (secondary)
Some responses are transient (e.g., wave review findings, verification pass/fail). These return structured text to the orchestrator for immediate action.

Format for stdout responses:
```
## Result
<PASS | FAIL | OBJECTIONS | ERROR>

## Summary
<1-3 sentence summary>

## Details
<Structured findings, if any>
```

## Error Reporting

When an agent encounters a blocking issue:

```
## Result
ERROR

## Summary
<What went wrong>

## Details
- Attempted: <what was tried>
- Failed because: <root cause>
- Suggestion: <what the orchestrator should do>
```

The orchestrator decides whether to retry, escalate, or abort. Agents do NOT retry themselves unless their spec explicitly says otherwise.

## Agent Team Mode

When agents are coordinated by the Team Leader (or Refinement Lead) as an Agent Team, the spawning mechanism differs from skill mode. Team members are persistent Claude Code sessions that stay alive, poll TaskList, and receive messages — unlike skill-mode subprocess agents that exit on completion.

### Spawning Pattern

```
1. TeamCreate(team_name: "{id}")              → create team + task list (once per workflow)
2. TaskCreate(subject: "...", metadata: {...}) → create task with structured assignment
3. TaskUpdate(taskId, owner: "{name}")         → assign task to teammate by name
4. Agent(subagent_type: "...", team_name: "{id}", name: "{name}", prompt: "Your task is {task-id}.") → spawn teammate
```

**Contrast with skill mode** (steps 2 + 4 only, no TeamCreate, no `team_name`/`name` on Agent):

```
1. TaskCreate(subject: "...", metadata: {...}) → create task
2. Agent(subagent_type: "...", prompt: "Your task is {task-id}.") → spawn subprocess agent
```

Key differences:
- **Subprocess agents** (skill mode): complete and exit. Cannot receive messages after spawn. Cannot poll TaskList for new work.
- **Team members** (team mode): stay alive between turns, wake on messages via SendMessage, poll TaskList for new work assignments.

### Team-Mode Detection

Agents detect whether they are running in a team by checking for team context — if a team name is available, the agent is in a team. Agents with dual behavior (team mode vs subagent mode) use this to branch:

- **Team context available** → follow Team Behavior (persistent polling, message-based coordination, wait for pipeline tasks)
- **No team context** → follow standard subagent workflow (one-shot execution, return result to caller)

### blockedBy Discipline

The Task API's `blockedBy` is **advisory, not enforced** — the API will let an agent mark a task `in_progress` or `completed` while its blockers are still open. Agents MUST enforce the constraint themselves:

1. **NEVER pick up a task that shows `[blocked by ...]` in TaskList.** A blocked task's dependencies are incomplete. Working on it produces results built on unfinished prerequisites
2. **NEVER mark a task `in_progress` or `completed` while it has unresolved blockers** — unless the agent itself owns the blocked task and is deliberately holding it open during a fix cycle (verifier/reviewer holding verify/review `in_progress` while a fix task blocks it)
3. **Before acting on any task from TaskList, confirm it has no `[blocked by]` annotation.** If it does, skip it and poll for the next unblocked task
4. **The only exception** is the fix-cycle hold pattern: a verifier/reviewer may keep a task `in_progress` and add a new blocker to it (the fix task). This is the held-open model — the task was already in progress before the blocker was added. The agent does not complete the task until the blocker resolves

Completing a task with unresolved blockers corrupts the pipeline by unblocking downstream tasks prematurely.

### Task Ownership

`TaskCreate` creates tasks with no owner. Ownership is set via `TaskUpdate`:

```
task = TaskCreate(subject: "verify-1.2", metadata: {...})
TaskUpdate(taskId: task.id, owner: "verifier")
```

All task assignment flows through `TaskUpdate(owner: "{name}")` — there is no `assigned` parameter on `TaskCreate`.

## Unified Task Graph

Both the Team Leader (EXECUTE phase) and `/jc:implement` skill (GRAPH step) create the same static task graph. All pipeline tasks are created upfront with `blockedBy` dependencies. Agents hold their tasks open until satisfied. Fix cycles create dynamic fix tasks that block the parent task.

### Per plan item (4 static tasks):

```
implement-{n.m}
       |
       v
verify-{n.m} ──── review-{n.m}      (parallel, both blockedBy implement)
       |               |
       v               v
         commit-{n.m}                (blockedBy verify AND review)
```

### Per wave (1 static wave review task):

```
commit-{n.1} ──┐
commit-{n.2} ──┤
               v
        wave-review-{n}              (blockedBy: all commit tasks in wave)
               |
               v
Wave N+1: implement-{n+1.m}         (blockedBy: wave-review-{n})
```

### Graph creation sequence:

```
For each plan item {n.m}:
  1. TaskCreate(subject: "implement-{n.m}", metadata: {"task_id": "{task-id}", "task_number": "{n.m}", "plan_path": "..."})
  2. TaskCreate(subject: "verify-{n.m}", metadata: {"mode": "task", "task_id": "{task-id}", "task_number": "{n.m}"})
  3. TaskCreate(subject: "review-{n.m}", metadata: {"mode": "task", "task_id": "{task-id}", "task_number": "{n.m}"})
  4. TaskCreate(subject: "commit-{n.m}", metadata: {"task_id": "{task-id}", "task_number": "{n.m}"})
  5. TaskUpdate(verify-{n.m}, addBlockedBy: [implement-{n.m}])
  6. TaskUpdate(review-{n.m}, addBlockedBy: [implement-{n.m}])
  7. TaskUpdate(commit-{n.m}, addBlockedBy: [verify-{n.m}, review-{n.m}])

For each wave {n}:
  8. TaskCreate(subject: "wave-review-{n}", metadata: {"mode": "wave", "task_id": "{task-id}", "wave_number": {n}, "files_changed": [<union of "Files affected" for all tasks in wave>]})
  9. TaskUpdate(wave-review-{n}, addBlockedBy: [commit-{n.1}, commit-{n.2}, ...])

For cross-wave deps (wave N+1 items):
  10. TaskUpdate(implement-{n+1.m}, addBlockedBy: [wave-review-{n}])

For file overlap within a wave:
  11. TaskUpdate(implement-{n.m2}, addBlockedBy: [implement-{n.m1}])
```

### On-demand tasks (not pre-created):

- `fix-{n.m}-v{attempt}` — created by verifier on FAIL, blocks verify-{n.m}
- `fix-{n.m}-r{attempt}` — created by reviewer on REVISE, blocks review-{n.m}
- `investigate-{n.m}` — created by executor on escalation, blocks executor's current task

### Task naming convention:

- `implement-{n.m}` — implementation (static, one per plan item)
- `verify-{n.m}` — verification (static, held open through fix cycles)
- `review-{n.m}` — per-task review (static, held open through fix cycles)
- `commit-{n.m}` — commit (static, unblocks when verify + review complete)
- `wave-review-{n}` — wave-level review (static, one per wave, blockedBy all wave commits)
- `fix-{n.m}-v{attempt}` — fix from verifier (dynamic, blocks verify)
- `fix-{n.m}-r{attempt}` — fix from reviewer (dynamic, blocks review)
- `investigate-{n.m}` — debugger investigation (dynamic, blocks executor's current task)

### Owner assignment:

- **Team mode:** `TaskUpdate(owner: "executor-{n.m}")`, `TaskUpdate(owner: "verifier")`, `TaskUpdate(owner: "reviewer")`
- **Subagent mode:** No owner assignment — the Implement skill tracks which task to spawn next

### Fix-task-blocks-parent pattern:

Fix cycles use a held-open model: the verifier/reviewer keeps their task `in_progress` and creates a dynamic fix task that blocks the parent:

```
Verifier FAIL:
  1. TaskCreate(fix-{n.m}-v{attempt}, metadata: {...})
  2. TaskUpdate(verify-{n.m}, addBlockedBy: [fix-{n.m}-v{attempt}])
  → verify stays in_progress but blocked; executor picks up fix
  → executor completes fix → verify unblocks → verifier re-checks

Reviewer REVISE:
  1. TaskCreate(fix-{n.m}-r{attempt}, metadata: {...})
  2. TaskUpdate(review-{n.m}, addBlockedBy: [fix-{n.m}-r{attempt}])
  → review stays in_progress but blocked; executor picks up fix
  → executor completes fix → review unblocks → reviewer re-reviews
```

Messages are optional collaboration alongside fix tasks — they accelerate the executor's work but the fix task + referenced file contains everything needed.
