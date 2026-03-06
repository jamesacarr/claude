# Error Handling and Recovery

> Failure modes, recovery strategies, observability, and anti-patterns for agent systems.

## Contents

- [Common Failure Modes](#common-failure-modes)
- [Recovery Checklist](#recovery-checklist)
- [Recovery Strategies](#recovery-strategies)
- [Structured Communication](#structured-communication)
- [Team Agent Error Patterns](#team-agent-error-patterns)
- [Observability](#observability)
- [Anti-Patterns](#anti-patterns)

## Common Failure Modes

Industry research identifies these failure patterns:

| Mode | Frequency | Causes | Prevention |
|------|-----------|--------|------------|
| Specification Problems | 32% | Vague role, missing workflow, unclear criteria | Explicit `## Role`, `## Workflow`, `## Focus Areas`, `## Output Format` |
| Inter-Agent Misalignment | 28% | Conflicting objectives, unclear handoffs | Clear orchestration patterns, explicit handoff protocols |
| Verification Gaps | 24% | No validation step, no output spec | Verification steps, evaluator agents |
| Error Cascading | Critical | No error handling downstream | Defensive prompts, graceful degradation, boundary validation |
| Non-Determinism | Inherent | LLM sampling, latency, context ordering | Lower temperature, comprehensive testing, robust validation |

**Specification Problems** -- Agents don't know what to do. Symptoms: asks clarifying questions (can't if it's an agent), makes incorrect assumptions, produces partial outputs, or fails to complete task.

**Inter-Agent Misalignment** -- Coordination breakdowns in multi-agent workflows. Symptoms: duplicate work, contradictory outputs, infinite loops, tasks falling through cracks. See [orchestration-patterns.md](orchestration-patterns.md) for prevention patterns.

**Verification Gaps** -- Nobody checks quality. Symptoms: incorrect results silently propagated, hallucinations undetected, format errors break downstream processes.

**Error Cascading** -- Failures in one agent propagate to others. Symptoms: single failure causes entire workflow to fail.

**Non-Determinism** -- Same prompt can produce different outputs. Symptoms: inconsistent behavior across invocations, tests pass sometimes and fail other times.

## Recovery Checklist

Include these patterns in agent prompts:

**Error detection**:
- [ ] Validate inputs before processing
- [ ] Check tool call results for errors
- [ ] Verify outputs match expected format
- [ ] Test assumptions (file exists, data valid, etc.)

**Recovery mechanisms**:
- [ ] Define fallback approach for primary path failure
- [ ] Include retry logic for transient failures
- [ ] Graceful degradation (partial results better than none)
- [ ] Clear error messages with diagnostic context

**Failure communication**:
- [ ] Explicitly state when task cannot be completed
- [ ] Explain what was attempted and why it failed
- [ ] Provide partial results if available
- [ ] Suggest remediation or next steps

**Quality gates**:
- [ ] Validation steps before returning output
- [ ] Self-checking (does output make sense?)
- [ ] Format compliance verification
- [ ] Completeness check (all required components present?)

## Recovery Strategies

### Graceful Degradation

**Pattern**: Workflow produces useful result even when ideal path fails.

#### Example

```markdown
## Workflow

1. Attempt to fetch latest API documentation from web
2. If fetch fails, use cached documentation (flag as potentially outdated)
3. If no cache available, use local stub documentation (flag as incomplete)
4. Generate code with best available information
5. Add TODO comments indicating what should be verified

## Fallback Hierarchy

- Primary: Live API docs (most accurate)
- Secondary: Cached docs (may be stale, flag date)
- Tertiary: Stub docs (minimal, flag as incomplete)
- Always: Add verification TODOs to generated code
```

**Key principle**: Partial success better than total failure. Always produce something useful.

### Autonomous Retry

**Pattern**: Agent retries failed operations with exponential backoff.

#### Example

```markdown
## Error Handling

When a tool call fails:
1. Attempt operation
2. If fails, wait 1 second and retry
3. If fails again, wait 2 seconds and retry
4. If fails third time, proceed with fallback approach
5. Document the failure in output

Maximum 3 retry attempts before falling back.
```

**Use case**: Transient failures (network issues, temporary file locks, rate limits).

**Anti-pattern**: Infinite retry loops without backoff or max attempts.

### Circuit Breakers

**Pattern**: Prevent cascading failures by stopping calls to failing components.

#### Conceptual Example

```markdown
## Circuit Breaker Logic

If API endpoint has failed 5 consecutive times:
- Stop calling the endpoint (circuit "open")
- Use fallback data source
- After 5 minutes, attempt one call (circuit "half-open")
- If succeeds, resume normal calls (circuit "closed")
- If fails, keep circuit open for another 5 minutes
```

**Application to agents**: Include in prompt when agent calls external APIs or services.

**Benefit**: Prevents wasting time/tokens on operations known to be failing.

### Timeouts

**Pattern**: Agents going silent shouldn't block workflow indefinitely.

#### Implementation

```markdown
## Timeout Handling

For long-running operations:
1. Set reasonable timeout (e.g., 2 minutes for analysis)
2. If operation exceeds timeout:
   - Abort operation
   - Provide partial results if available
   - Clearly flag as incomplete
   - Suggest manual intervention
```

**Note**: Claude Code has built-in timeouts for tool calls. Agent prompts should include guidance on what to do when operations approach reasonable time limits.

### Multiple Verification Paths

**Pattern**: Different validators catch different error types.

#### Example

```markdown
## Verification Strategy

After generating code:
1. Syntax check: Parse code to verify valid syntax
2. Type check: Run static type checker (if applicable)
3. Linting: Check for common issues and anti-patterns
4. Security scan: Check for obvious vulnerabilities
5. Test run: Execute tests if available

If any check fails, fix issue and re-run all checks.
Each check catches different error types.
```

**Benefit**: Layered validation catches more issues than single validation pass.

### Reassigning Tasks

**Pattern**: Invoke alternative agents or escalate to human when primary approach fails.

#### Example

```markdown
## Escalation Workflow

If automated fix fails after 2 attempts:
1. Document what was tried and why it failed
2. Provide diagnosis of the problem
3. Recommend human review with specific questions to investigate
4. DO NOT continue attempting automated fixes that aren't working

Know when to escalate rather than thrashing.
```

**Key insight**: Agents should recognize their limitations and provide useful handoff information.

## Structured Communication

Multi-agent systems fail when communication is ambiguous. Structured messaging prevents misunderstandings.

### Message Types

Every message between agents (or from agent to user) should have explicit type:

**Request**: Asking for something
```markdown
Type: Request
From: code-reviewer
To: test-writer
Task: Create tests for authentication module
Context: Recent security review found gaps in auth testing
Expected output: Comprehensive test suite covering auth edge cases
```

**Inform**: Providing information
```markdown
Type: Inform
From: debugger
To: Main chat
Status: Investigation complete
Findings: Root cause identified in line 127, race condition in async handler
```

**Commit**: Promising to do something
```markdown
Type: Commit
From: security-reviewer
Task: Review all changes in PR #342 for security issues
Deadline: Before responding to main chat
```

**Reject**: Declining request with reason
```markdown
Type: Reject
From: test-writer
Reason: Cannot write tests - no testing framework configured in project
Recommendation: Install Jest or similar framework first
```

### Schema Validation

**Pattern**: Validate every payload against expected schema.

#### Example

```markdown
## Output Validation

Expected output format:
{
  "vulnerabilities": [
    {
      "severity": "Critical|High|Medium|Low",
      "location": "file:line",
      "type": "string",
      "description": "string",
      "fix": "string"
    }
  ],
  "summary": "string"
}

Before returning output:
1. Verify JSON is valid
2. Check all required fields present
3. Validate severity values are from allowed list
4. Ensure location follows "file:line" format
```

**Benefit**: Prevents malformed outputs from breaking downstream processes.

## Team Agent Error Patterns

> Error handling for Agent Teams requires additional patterns beyond subagent error handling. Team members persist across turns, coordinate via messages, and share state through task lists.

### Teammate Failure

When a team member fails a task:

```markdown
## Teammate Failure Handling

Executor reports failure via SendMessage:
1. Team lead receives failure notification
2. Options:
   a. Reassign task to another teammate (TaskUpdate: owner = different-agent)
   b. Spawn a fresh teammate for the task
   c. Retry with refined context (send clarifying message)
   d. Mark task as blocked and move to next wave

Do NOT silently drop the task. Always update task state to reflect reality.
```

### Message Delivery Failures

Messages between teammates can fail or arrive out of order:

```markdown
## Message Resilience

- Use task state as source of truth, not messages
- If a teammate seems unresponsive, check if they are idle (normal) vs stuck
- Critical state transitions go through TaskUpdate, not just SendMessage
- Messages supplement task state — they don't replace it
```

### Shutdown Rejection

When a teammate rejects a shutdown request:

```markdown
## Shutdown Rejection Handling

1. Read the rejection reason (returned in shutdown_response)
2. If teammate has active work: wait for completion, retry
3. If teammate is stuck: investigate blocker, help resolve
4. If persistent rejection: escalate to user
5. Never force-kill — the shutdown handshake exists for a reason
```

### Task Dependency Deadlocks

Tasks with circular or unresolvable dependencies:

```markdown
## Deadlock Detection

Symptoms:
- Multiple tasks blocked, none making progress
- Circular blockedBy references (A blocks B, B blocks A)
- All teammates idle with no claimable tasks

Resolution:
1. Team lead reviews task dependencies
2. Identify the cycle or unresolvable blocker
3. Break the cycle: remove a dependency, merge tasks, or redefine scope
4. Update task states to unblock work
```

### Partial Team Failure

When some teammates succeed but others fail:

```markdown
## Partial Team Failure

Wave 2 has 3 tasks: A succeeds, B fails, C succeeds.

Options:
1. Retry B only (don't redo A and C)
2. Reassign B to a fresh agent with A and C results as context
3. Proceed to Wave 3 if B is non-critical (document the gap)
4. Pause and escalate if B is a dependency for Wave 3

Always preserve successful work. Never retry a full wave for a single failure.
```

## Observability

For structured logging, session tracing, correlation IDs, metrics monitoring, and evaluator agents, see [debugging-agents.md](debugging-agents.md#debugging-approaches).

## Anti-Patterns

### Silent Failures

Agent fails but doesn't indicate failure in output.

**Example**:
```markdown
Task: Review 10 files for security issues
Reality: Only reviewed 3 files due to errors, returned results anyway
Output: "No issues found" (incomplete review, but looks successful)
```

**Fix**: Explicitly state what was reviewed, flag partial completion, include error summary.

### No Fallback

When ideal path fails, agent gives up entirely.

**Example**:
```markdown
Task: Generate code from API documentation
Error: API docs unavailable
Output: "Cannot complete task, API docs not accessible"
```

**Better**:
```markdown
Error: API docs unavailable
Fallback: Using cached documentation (last updated: 2025-11-01)
Output: Code generated with note: "Verify against current API docs, using cached version"
```

**Principle**: Provide best possible output given constraints, clearly flag limitations.

### Infinite Retry

Retrying failed operations without backoff or limit.

**Risk**: Wastes tokens, time, and may hit rate limits.

**Fix**: Maximum retry count (typically 2-3), exponential backoff, fallback after exhausting retries.

### Error Cascading

Downstream agents assume upstream outputs are valid.

**Example**:
```markdown
Agent 1: Generates code (contains syntax error)
  ↓
Agent 2: Writes tests (assumes code is syntactically valid, tests fail)
  ↓
Agent 3: Runs tests (all tests fail due to syntax error in code)
  ↓
Total workflow failure from single upstream error
```

**Fix**: Each agent validates inputs before processing, includes error handling for invalid inputs.

### No Error Context

Error messages without diagnostic context.

**Bad**: "Failed to complete task"

**Good**: "Failed to complete task: Unable to access file src/auth.ts (file not found). Attempted to review authentication code but file missing from expected location. Recommendation: Verify file path or check if file was moved/deleted."

**Principle**: Error messages should help diagnose root cause and suggest remediation.

### Orphaned Team State

Team lead crashes or disconnects without cleaning up.

**Problem**: Team config, task list, and idle teammates persist with no coordinator.

**Fix**: Design agents to detect stale team state. If team lead is unreachable, teammates should surface the issue to the user rather than waiting indefinitely.
