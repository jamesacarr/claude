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

### Task Ownership

`TaskCreate` creates tasks with no owner. Ownership is set via `TaskUpdate`:

```
task = TaskCreate(subject: "verify-1.2-1", metadata: {...})
TaskUpdate(taskId: task.id, owner: "verifier")
```

All task assignment flows through `TaskUpdate(owner: "{name}")` — there is no `assigned` parameter on `TaskCreate`.
