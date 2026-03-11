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

The spawn prompt is minimal — just the task ID. The agent calls `TaskGet` to read its full assignment from the task metadata. For the team-mode equivalent (spawn-then-assign), see the Agent Team Mode section below.

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
3. Agent(subagent_type: "...", team_name: "{id}", name: "{name}", prompt: "...wait for task assignment...") → spawn teammate
4. TaskUpdate(taskId, owner: "{name}")         → assign task — agent is notified on assignment
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

- **Team context available** → follow Team Behavior (notification-driven re-assignment, message-based collaboration, persistent across waves)
- **No team context** → follow standard subagent workflow (one-shot execution, return result to caller)

### blockedBy Discipline

The Task API's `blockedBy` is **advisory, not enforced** — the API will let an agent mark a task `in_progress` or `completed` while its blockers are still open. Agents MUST enforce the constraint themselves:

1. **NEVER pick up a task that shows `[blocked by ...]` in TaskList.** A blocked task's dependencies are incomplete. Working on it produces results built on unfinished prerequisites
2. **NEVER mark a task `in_progress` or `completed` while it has unresolved blockers.** No exceptions
3. **Before acting on any task from TaskList, confirm it has no `[blocked by]` annotation.** If it does, skip it and poll for the next unblocked task

Completing a task with unresolved blockers corrupts the pipeline by unblocking downstream tasks prematurely.

### Task Ownership

`TaskCreate` creates tasks with no owner. Ownership is assigned via `TaskUpdate` **after the target agent is spawned** — agents are notified when tasks are assigned to them:

```
task = TaskCreate(subject: "implement-1.2", metadata: {...})
# ... spawn agent first ...
TaskUpdate(taskId: task.id, owner: "executor-1.2")  → agent receives notification
```

All task assignment flows through `TaskUpdate(owner: "{name}")` — there is no `assigned` parameter on `TaskCreate`. In team mode, owners are always assigned after agents are spawned. In subagent mode, no owner is assigned — the skill tracks task progression directly.

## Unified Task Graph

Both the Team Leader (EXECUTE phase) and `/jc:implement` skill (GRAPH step) create the same static task graph. Each plan item gets a single `implement-{n.m}` task that moves through the pipeline via re-assignment (`TaskUpdate(owner, metadata)`). No separate verify, review, or commit tasks are created. This produces N+W tasks (N implement + W wave-review) instead of 4N+W.

### Per plan item (1 task, re-assigned through chain):

```
implement-{n.m}   (re-assigned: executor → verifier → reviewer → executor → completed)
```

### Per wave (1 static wave review task):

```
implement-{n.1} ──┐
implement-{n.2} ──┤
                   v
            wave-review-{n}              (blockedBy: all implement tasks in wave)
                   |
                   v
Wave N+1: implement-{n+1.m}             (blockedBy: wave-review-{n})
```

### Graph creation sequence:

```
For each plan item {n.m}:
  1. TaskCreate(subject: "implement-{n.m}", metadata: {"task_id": "{task-id}", "task_number": "{n.m}", "plan_path": "...", "stage": "implement"})

For each wave {n}:
  2. TaskCreate(subject: "wave-review-{n}", metadata: {"mode": "wave", "task_id": "{task-id}", "wave_number": {n}, "files_changed": [<union of "Files affected" for all tasks in wave>]})
  3. TaskUpdate(wave-review-{n}, addBlockedBy: [implement-{n.1}, implement-{n.2}, ...])

For cross-wave deps (wave N+1 items):
  4. TaskUpdate(implement-{n+1.m}, addBlockedBy: [wave-review-{n}])

For file overlap within a wave:
  5. TaskUpdate(implement-{n.m2}, addBlockedBy: [implement-{n.m1}])
```

### On-demand tasks (not pre-created):

- `investigate-{n.m}` — created by executor on escalation, blocks executor's implement task
- `wave-fix-{n}-{attempt}` — created by reviewer on wave-review REVISE, assigned to lead for routing

### Task naming convention:

- `implement-{n.m}` — implementation (static, one per plan item, re-assigned through pipeline stages)
- `wave-review-{n}` — wave-level review (static, one per wave, blockedBy all implement tasks in wave)
- `investigate-{n.m}` — debugger investigation (dynamic, blocks executor's implement task)
- `wave-fix-{n}-{attempt}` — wave-review fix (dynamic, created by reviewer on REVISE, assigned to lead)

### Owner assignment:

In team mode, owners are assigned **after all agents are spawned** (spawn-then-assign pattern). Agents are notified on assignment and begin work:

```
After spawning all agents for the current wave:
  TaskUpdate(implement-{n.m}, owner: "executor-{n.m}")   (current wave only)
  TaskUpdate(wave-review-{n}, owner: "reviewer")          (all waves)
```

- **Subagent mode:** No owner assignment — the Implement skill tracks stage-based dispatch directly

### Re-assignment chain:

The implement task moves through pipeline stages via `TaskUpdate(owner, metadata)`. Each agent re-assigns the task to the next agent in the chain on completion:

```
executor completes impl  → TaskUpdate(owner: "verifier", metadata: {stage: "verify"})
verifier PASS             → TaskUpdate(owner: "reviewer", metadata: {stage: "review"})
verifier FAIL             → TaskUpdate(owner: "executor-{n.m}", metadata: {stage: "fix", fix_source: "verifier", report_path: "...", deviation_count: N+1})
executor completes fix    → TaskUpdate(owner: <fix_source>, metadata: {stage: "verify" if fix_source is verifier, "review" if reviewer})
reviewer PASS             → TaskUpdate(owner: "executor-{n.m}", metadata: {stage: "commit"})
reviewer REVISE           → TaskUpdate(owner: "executor-{n.m}", metadata: {stage: "fix", fix_source: "reviewer", findings_path: "...", deviation_count: N+1})
executor commits          → TaskUpdate(status: completed, metadata: {stage: "committed", commit_hash: "...", commit_msg: "..."})
```

**Stage values:** `implement` (initial), `verify`, `review`, `fix`, `commit`, `committed` (terminal).

**Metadata merging:** `TaskUpdate(metadata: {...})` **merges** with existing metadata — it does not replace it. Original keys (`task_id`, `task_number`, `plan_path`) persist through all re-assignments. Agents adding stage-specific keys (e.g., `fix_source`, `report_path`) extend the metadata; they do not need to re-include the original keys.

**deviation_count:** Tracked in task metadata, incremented by the verifier (on FAIL) and reviewer (on REVISE) when re-assigning with `stage: "fix"`. The executor reads it to decide whether to escalate (limit: 3). The orchestrator resets it to 0 when the user provides guidance after an escalation.

**Subagent mode:** Agents do NOT re-assign tasks. They return verdicts to the skill, and the skill handles stage transitions externally via `TaskUpdate`.

Messages are optional collaboration alongside re-assignment — they accelerate the executor's work but the task metadata contains everything needed.
