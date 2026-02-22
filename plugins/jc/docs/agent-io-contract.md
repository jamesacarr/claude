# Agent I/O Contract

Standard calling convention for all JC team agents. Every agent invocation — whether via Task tool (skill orchestration) or Agent Team (Team Leader coordination) — follows this structure.

## Invocation Format

When spawning an agent via the Task tool, the prompt MUST include these sections in order:

```
## Task
<What the agent should do — one sentence>

## Context
<Background the agent needs>
- Task ID: <task-id>
- Project root: <absolute path>
- Planning directory: <absolute path to .planning/>
- <Additional context fields specific to the agent>

## Input
<Specific data the agent operates on — file paths, descriptions, configuration>

## Expected Output
<What the agent should produce — file paths, formats, return values>
```

### Section Rules

| Section | Required | Content |
|---------|----------|---------|
| **Task** | Always | Single imperative sentence. No ambiguity — the agent should know exactly what to do |
| **Context** | Always | Task ID, project root, planning directory. Additional fields vary by agent |
| **Input** | Always | Concrete data. File paths use absolute paths. Descriptions are verbatim from the plan or user |
| **Expected Output** | Always | Exact file paths for written output. Return format for stdout responses |

## Output Convention

Agents produce output in two ways:

### File output (primary)
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

When agents are coordinated by the Team Leader as an Agent Team (rather than spawned via Task tool), the same information structure applies — the Team Leader shares equivalent context through team coordination rather than prompt sections. The contract defines _what_ information flows between agents, not the transport mechanism.
