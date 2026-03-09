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

When agents are coordinated by the Team Leader as an Agent Team (rather than spawned via Task tool), the same Task metadata mechanism applies — the Team Leader creates tasks with metadata via `TaskCreate`, and agents pick up assignments via `TaskList` + `TaskGet`. Persistent agents (executor, verifier, reviewer, debugger) poll `TaskList` in a loop for new work rather than receiving a single task at spawn time.
