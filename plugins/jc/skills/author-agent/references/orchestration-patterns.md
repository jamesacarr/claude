# Orchestration Patterns

> Defines how multiple agents coordinate to complete complex tasks.

## Contents

- [Core Concept](#core-concept)
- [Pattern Selection](#pattern-selection)
- [Pattern Catalog](#pattern-catalog)
- [Team Agent Orchestration](#team-agent-orchestration)
- [Hybrid Approaches](#hybrid-approaches)
- [Implementation Guidance](#implementation-guidance)
- [Anti-Patterns](#anti-patterns)
- [Best Practices](#best-practices)

## Core Concept

Orchestration defines how multiple agents coordinate to complete complex tasks.

**Single agent**: Sequential execution within one context.
**Multi-agent**: Coordination between multiple specialized agents, each with focused expertise.

## Pattern Selection

### Decision Tree

```markdown
Is task decomposable into independent subtasks?
├─ Yes: Parallel pattern (fastest)
└─ No: ↓

Do subtasks depend on each other's outputs?
├─ Yes: Sequential pattern (clear dependencies)
└─ No: ↓

Is task large/complex requiring decomposition AND oversight?
├─ Yes: Hierarchical pattern (structured delegation)
└─ No: ↓

Do agents need persistent coordination across turns?
├─ Yes: Agent Teams pattern (team lifecycle)
└─ No: ↓

Do task requirements vary dynamically?
├─ Yes: Coordinator pattern (adaptive routing)
└─ No: Single agent sufficient
```

### Pattern Comparison

| Pattern | Flow | Best For | Speed | Complexity |
|---------|------|----------|-------|------------|
| Sequential | A -> B -> C (linear) | Dependent stages | Slow | Low |
| Parallel | A + B + C (concurrent) | Independent analyses | Fast | Medium |
| Hierarchical | Top -> delegates -> integrates | Complex decomposition | Medium | High |
| Coordinator | Central router -> dynamic agents | Diverse/dynamic tasks | Medium | High |
| Orchestrator-Worker | Orchestrator -> batch workers | Batch processing | Fast | Medium |
| Agent Teams | Lead -> teammates via messaging | Multi-turn collaboration | Medium | High |

**Trade-off**: Choose the simplest pattern that meets requirements.

## Pattern Catalog

### Sequential

Agents chained in a predefined, linear order. Each agent processes output from the previous agent, forming a pipeline of specialized transformations. The flow is deterministic (A -> B -> C) and straightforward to debug.

#### When To Use

- Document review workflows (security -> performance -> style)
- Data processing pipelines (extract -> transform -> validate -> load)
- Multi-stage reasoning (research -> analyze -> synthesize -> recommend)

#### Example

```markdown
Task: Comprehensive code review

Flow:
1. security-reviewer: Check for vulnerabilities
   ↓ (security report)
2. performance-analyzer: Identify performance issues
   ↓ (performance report)
3. test-coverage-checker: Assess test coverage
   ↓ (coverage report)
4. report-synthesizer: Combine all findings into actionable review
```

#### Implementation

```markdown
Main chat orchestrates:
1. Launch security-reviewer with code changes
2. Wait for security report
3. Launch performance-analyzer with code changes + security report context
4. Wait for performance report
5. Launch test-coverage-checker with code changes
6. Wait for coverage report
7. Synthesize all reports for user
```

### Parallel

Multiple specialized agents perform tasks simultaneously. Agents execute independently and concurrently, with outputs synthesized into a final response. Requires synchronization but yields significant speed improvements.

**Performance data**: Anthropic's research system with 3-5 agents in parallel achieved 90% time reduction.

#### When To Use

- Independent analyses of same input (security + performance + quality)
- Processing multiple independent items (review multiple files)
- Research tasks (gather information from multiple sources)

#### Example

```markdown
Task: Comprehensive code review (parallel approach)

Launch simultaneously:
- security-reviewer (analyzes auth.ts)
- performance-analyzer (analyzes auth.ts)
- test-coverage-checker (analyzes auth.ts test coverage)

Wait for all three to complete → synthesize findings.

Time: max(agent_1, agent_2, agent_3) vs sequential: agent_1 + agent_2 + agent_3
```

#### Implementation

```markdown
Main chat orchestrates:
1. Launch all agents simultaneously with same context
2. Collect outputs as they complete
3. Synthesize results when all complete

Synchronization challenges:
- Handling different completion times
- Dealing with partial failures (some agents fail, others succeed)
- Combining potentially conflicting outputs
```

### Hierarchical

Agents organized in layers with a tree-like structure. Higher-level agents break down tasks and delegate to lower-level agents, which execute specific subtasks and report back. Establishes clear master-worker relationships with built-in oversight.

#### When To Use

- Large, complex problems requiring decomposition
- Tasks with natural hierarchy (system design -> component design -> implementation)
- Situations requiring oversight and quality control

#### Example

```markdown
Task: Implement complete authentication system

Hierarchy:
- architect (top-level): Designs overall auth system, breaks into components
  ↓ delegates to:
  - backend-dev: Implements API endpoints
  - frontend-dev: Implements login UI
  - security-reviewer: Reviews both for vulnerabilities
  - test-writer: Creates integration tests
  ↑ reports back to:
- architect: Integrates components, ensures coherence
```

#### Implementation

```markdown
Top-level agent (architect):
1. Analyze requirements
2. Break into subtasks
3. Delegate to specialized agents
4. Monitor progress
5. Integrate results
6. Validate coherence across components

Lower-level agents:
- Receive focused subtask
- Execute with deep expertise
- Report results to coordinator
- No awareness of other agents' work
```

### Coordinator

A central LLM agent dynamically routes tasks to specialized sub-agents based on task characteristics and intermediate results. Unlike hierarchical, routing decisions are made at runtime rather than following a fixed structure.

#### When To Use

- Diverse task types requiring different expertise
- Dynamic workflows where next step depends on results
- User-facing systems with varied requests

#### Example

```markdown
Task: "Help me improve my codebase"

Coordinator analyzes request → determines relevant agents:
- code-quality-analyzer: Assess overall code quality
  ↓ findings suggest security issues
- Coordinator: Route to security-reviewer
  ↓ security issues found
- Coordinator: Route to auto-fixer to generate patches
  ↓ patches ready
- Coordinator: Route to test-writer to create tests for fixes
  ↓
- Coordinator: Synthesize all work into improvement plan
```

#### Implementation

```markdown
Coordinator agent prompt:

## Role
You are a workflow coordinator. Route tasks to specialized agents based on:
- Task characteristics
- Available agents and their capabilities
- Results from previous agents
- User goals

## Decision Process
1. Analyze incoming task
2. Identify relevant agents (may be multiple)
3. Determine execution strategy (sequential, parallel, conditional)
4. Launch agents with appropriate context
5. Analyze results
6. Decide next step (more agents, synthesis, completion)
7. Repeat until task complete
```

### Orchestrator Worker

Central orchestrator assigns tasks and manages execution across distributed workers. Workers focus on specific, independent tasks with clear separation of planning (orchestrator) and execution (workers). Similar to distributed computing master-worker pattern.

#### When To Use

- Batch processing (process 100 files)
- Independent tasks that can be distributed (analyze multiple API endpoints)
- Load balancing across workers

#### Example

```markdown
Task: Security review of 50 microservices

Orchestrator:
1. Identifies all 50 services
2. Breaks into batches of 5
3. Assigns batches to worker agents
4. Monitors progress
5. Aggregates results

Workers (5 concurrent instances of security-reviewer):
- Each reviews assigned services
- Reports findings to orchestrator
- Independent execution (no inter-worker communication)
```

#### Sonnet Haiku Orchestration

**Sonnet + Haiku orchestration**: Optimal cost/performance pattern.

Research findings:
- Sonnet: Exceptional at planning and validation
- Haiku: ~90% of Sonnet performance, fast and cost-efficient

**Pattern**:
```markdown
1. Sonnet (Orchestrator):
   - Analyzes task
   - Creates plan
   - Breaks into subtasks
   - Identifies what can be parallelized

2. Multiple Haiku instances (Workers):
   - Each completes assigned subtask
   - Executes in parallel for speed
   - Returns results to orchestrator

3. Sonnet (Orchestrator):
   - Integrates results from all workers
   - Validates output quality
   - Ensures coherence
   - Delivers final output
```

**Cost/performance optimization**: Expensive Sonnet only for planning/validation, cheap Haiku for execution.

## Team Agent Orchestration

> Claude Code's Agent Teams model provides persistent, multi-turn coordination between agents using `TeamCreate`, `SendMessage`, `TaskList/Update`, and shared team config. This section covers orchestration patterns specific to team agents.

### When To Use Agent Teams (vs Subagents)

```markdown
Do agents need to communicate with each other?
├─ No: Use subagents (one-shot, I/O contract)
└─ Yes: ↓

Is the communication just sequential handoffs?
├─ Yes: Sequential subagents with context passing
└─ No: ↓

Do agents need to coordinate dynamically across turns?
├─ Yes: Agent Teams
└─ No: Parallel subagents with synthesis
```

Agent Teams add overhead (team creation, messaging, task list management, shutdown). Only use when the coordination benefit outweighs that cost.

### Team Lifecycle

```markdown
1. TeamCreate: Create team with name and description
2. TaskCreate: Create tasks for the team's task list
3. Task tool (team_name): Spawn teammates that join the team
4. TaskUpdate: Assign tasks to teammates (or teammates self-assign)
5. Work loop: Teammates execute tasks, communicate via SendMessage
6. SendMessage (shutdown_request): Gracefully terminate teammates
7. TeamDelete: Clean up team resources
```

### Team Lead Pattern

The team lead orchestrates work by creating tasks and coordinating teammates via messaging. This maps naturally to the Hierarchical pattern but with persistent communication.

```markdown
Team Lead:
1. Creates team (TeamCreate)
2. Breaks work into tasks (TaskCreate with dependencies)
3. Spawns specialized teammates (Task tool + team_name)
4. Assigns tasks (TaskUpdate with owner)
5. Monitors progress (receives messages from teammates)
6. Handles blockers (sends guidance via SendMessage)
7. Integrates results
8. Shuts down teammates (shutdown_request)
9. Cleans up (TeamDelete)

Teammates:
1. Read team config to discover peers
2. Check TaskList for assigned work
3. Execute tasks
4. Mark tasks completed (TaskUpdate)
5. Send status to lead (SendMessage)
6. Check TaskList for next work
7. Handle shutdown requests
```

**Canonical example**: `team-leader` agent coordinates `team-executor`, `team-reviewer`, and `team-verifier`.

### Wave-Based Execution

Group tasks into waves — sets of tasks that can run in parallel within a wave but must complete before the next wave starts.

```markdown
Wave 1 (parallel): research-1, research-2, research-3
  ↓ all complete
Wave 2 (parallel): implement-a, implement-b
  ↓ all complete
Wave 3 (sequential): integrate, verify
```

**Implementation:**
```markdown
Team Lead:
1. Analyze task dependencies to form waves
2. For each wave:
   a. Spawn/assign teammates for all tasks in wave
   b. Wait for all wave tasks to complete
   c. Handle any failures (retry, reassign, escalate)
3. Move to next wave
```

This is how `/jc:implement` orchestrates plan execution — tasks within a wave run concurrently across teammates, waves execute sequentially.

### Peer Communication

Team members communicate through two mechanisms:

1. **Task creation** — pipeline coordination. Each agent creates the next step on completion:
```markdown
Executor completes → TaskCreate(verify-1.1-1, assigned: verifier)
Verifier PASS → TaskCreate(review-1.1-1, assigned: reviewer)
Reviewer PASS → TaskCreate(commit-1.1, assigned: executor)
```

2. **Messages** — content-carrying feedback only. Messages are for rich, actionable content that doesn't fit in a task description:
```markdown
Verifier → Executor: FAIL details with evidence references
Reviewer → Executor: Structured findings (file, line, issue, suggestion)
Debugger → Executor: Root cause diagnosis + recommended fix
```

**Design considerations:**
- Pipeline progression is task-driven, not message-driven
- Messages carry only actionable content — no CC messages, no status-only notifications
- The team lead receives only committed/escalation messages and stall self-reports
- Teammates self-report stalls after 3 checks with no progress on expected peer responses

### Task-Driven Coordination

The shared task list is the primary coordination mechanism. Each agent creates the next step in the pipeline on completion — no pre-created chains, no orphaned tasks.

**Task-chain pipeline pattern:**
```markdown
Lead: TaskCreate(implement-1.1, assigned: executor)
  Executor completes → TaskCreate(verify-1.1-1, assigned: verifier)
    Verifier PASS → TaskCreate(review-1.1-1, assigned: reviewer)
      Reviewer PASS → TaskCreate(commit-1.1, assigned: executor)
        Executor commits → messages lead
```

**Task naming convention:**
- `implement-{n.m}` — implementation task
- `verify-{n.m}-{attempt}` — verification (attempt starts at 1)
- `review-{n.m}-{attempt}` — review (attempt starts at 1)
- `commit-{n.m}` — commit (no attempt number — only created on reviewer PASS)
- `investigate-{n.m}-{attempt}` — investigation (attempt starts at 1)

**Tiered state model:**
- **Same session:** TaskList is primary source of truth
- **Fresh session (after pause):** PLAN.md is primary (TaskList is gone). Lead creates fresh task chains for non-terminal tasks
- **LEADER-STATE.md:** Supplementary — captures session context (active teammates, guidance, patterns) that neither TaskList nor PLAN.md can

**Rule**: Prefer task list state over messages for tracking progress. Messages supplement — they don't replace — task state. Pipeline coordination uses TaskCreate; messages carry only content-rich feedback.

## Hybrid Approaches

Real-world systems often combine patterns for different workflow phases.

### Sequential Then Parallel

**Sequential for initial processing -> Parallel for analysis**:

```markdown
Task: Comprehensive feature implementation review

Sequential phase:
1. requirements-validator: Check requirements completeness
   ↓
2. implementation-reviewer: Verify feature implemented correctly
   ↓

Parallel phase (once implementation validated):
3. Launch simultaneously:
   - security-reviewer
   - performance-analyzer
   - accessibility-checker
   - test-coverage-validator
   ↓

Sequential synthesis:
4. report-generator: Combine all findings
```

**Rationale**: Early stages have dependencies (can't validate implementation before requirements), later stages are independent analyses.

### Coordinator With Hierarchy

**Coordinator orchestrating hierarchical teams**:

```markdown
Top level: Coordinator receives "Build payment system"

Coordinator creates hierarchical teams:

Team 1 (Backend):
- Lead: backend-architect
  - Workers: api-developer, database-designer, integration-specialist

Team 2 (Frontend):
- Lead: frontend-architect
  - Workers: ui-developer, state-management-specialist

Team 3 (DevOps):
- Lead: infra-architect
  - Workers: deployment-specialist, monitoring-specialist

Coordinator:
- Manages team coordination
- Resolves inter-team dependencies
- Integrates deliverables
```

**Benefit**: Combines dynamic routing (coordinator) with team structure (hierarchy).

### Subagents Within Teams

**Constraint: Team members cannot spawn subagents** (see [execution-models.md](execution-models.md)). Team members that need subagent-like work must request it from the team lead.

**Correct pattern — team lead spawns on behalf of members:**

```markdown
Team Lead creates plan → assigns to Executor teammate
Executor (team member):
  - Receives task via TaskList
  - Executes work directly (no subagent spawning)
  - Reports completion via SendMessage + TaskUpdate

If Executor needs research or testing subagents:
  - Executor sends message to Team Lead: "Need research on X before proceeding"
  - Team Lead spawns subagent, collects result
  - Team Lead sends result to Executor via SendMessage
```

**Alternative — pre-create dedicated tasks:**

```markdown
Team Lead:
  - Creates "Research X" task (assigned to researcher teammate)
  - Creates "Implement Y" task (assigned to executor, blockedBy: research)
  - Researcher completes research, marks task done
  - Executor's task unblocks, proceeds with research available in task context
```

**Rationale**: Design workflows so the team lead (main context) orchestrates all subagent work directly. See [execution-models.md](execution-models.md) for the `name` vs `subagent_type` distinction and spawning constraints.

## Implementation Guidance

### Coordinator Agent

**Example coordinator implementation**:

```markdown
---
name: workflow-coordinator
description: Orchestrates multi-agent workflows. Use when task requires multiple specialized agents in coordination.
tools: all
model: sonnet
---

## Role

You are a workflow coordinator. Analyze tasks, identify required agents, orchestrate their execution.

## Available Agents

{list of specialized agents with capabilities}

## Orchestration Strategies

**Sequential**: When agents depend on each other's outputs
**Parallel**: When agents can work independently
**Hierarchical**: When task needs decomposition with oversight
**Agent Teams**: When agents need persistent multi-turn coordination
**Adaptive**: Choose pattern based on task characteristics

## Workflow

1. Analyze incoming task
2. Identify required capabilities
3. Select agents and pattern
4. Launch agents (sequentially or parallel as appropriate)
5. Monitor execution
6. Handle errors (retry, fallback, escalate)
7. Integrate results
8. Validate coherence
9. Deliver final output

## Error Handling

If agent fails:
- Retry with refined context (1-2 attempts)
- Try alternative agent if available
- Proceed with partial results if acceptable
- Escalate to human if critical
```

### Handoff Protocol

**Clean handoffs between agents**:

```markdown
## Agent Handoff Format

From: {source_agent}
To: {target_agent}
Task: {specific task}
Context:
  - What was done: {summary of prior work}
  - Key findings: {important discoveries}
  - Constraints: {limitations or requirements}
  - Expected output: {what target agent should produce}

Attachments:
  - {relevant files, data, or previous outputs}
```

**Why explicit format matters**: Prevents information loss, ensures target agent has full context, enables validation.

For subagents, use the [I/O contract]({plugin-docs}/agent-io-contract.md) TaskCreate-with-metadata pattern instead — structured parameters go in task metadata, spawn prompt is just the task ID.

### Synchronization

**Handling parallel execution**:

```markdown
## Parallel Synchronization

Launch pattern:
1. Initiate all parallel agents with shared context
2. Track which agents have completed
3. Collect outputs as they arrive
4. Wait for all to complete OR timeout
5. Proceed with available results (flag missing if timeout)

Partial failure handling:
- If 1 of 3 agents fails: Proceed with 2 results, note gap
- If 2 of 3 agents fail: Consider retry or workflow failure
- Always communicate what was completed vs attempted
```

### Team Shutdown

**Graceful team teardown**:

```markdown
## Shutdown Protocol

1. Wait for all active tasks to complete
2. Send shutdown_request to each teammate
3. Wait for shutdown_response (approve/reject)
4. If rejected: resolve blocker, retry shutdown
5. After all teammates shut down: TeamDelete
```

Never force-kill teammates with active work. The shutdown handshake ensures no work is lost.

## Anti-Patterns

### Over Orchestration

Using multiple agents when single agent would suffice.

**Example**: Three agents to review 10 lines of code (overkill).

**Fix**: Reserve multi-agent for genuinely complex tasks. Single capable agent often better than coordinating multiple simple agents.

### No Coordination

Launching multiple agents with no coordination or synthesis.

**Problem**: User gets conflicting reports, no coherent output, unclear which to trust.

**Fix**: Always synthesize multi-agent outputs into coherent final result.

### Sequential When Parallel

Running independent analyses sequentially.

**Example**: Security review -> performance review -> quality review (each independent, done sequentially).

**Fix**: Parallel execution for independent tasks. 3x speed improvement in this case.

### Unclear Handoffs

Agent outputs that don't provide sufficient context for next agent.

**Example**:
```markdown
Agent 1: "Found issues"
Agent 2: Receives "Found issues" with no details on what, where, or severity
Agent 2: Can't effectively act on vague input
```

**Fix**: Structured handoff format with complete context.

### No Error Recovery

Orchestration with no fallback when agent fails.

**Problem**: One agent failure causes entire workflow failure.

**Fix**: Graceful degradation, retry logic, alternative agents, partial results (see [error-handling-and-recovery.md](error-handling-and-recovery.md)).

### Teams For One-Shot Work

Using Agent Teams (TeamCreate, SendMessage, TaskList) when simple subagent calls would suffice.

**Problem**: Team setup/teardown overhead for work that doesn't need persistent coordination. Extra context consumed by team infrastructure.

**Fix**: Use teams only when agents need multi-turn coordination. For independent, one-shot work, use parallel subagents with I/O contract prompts.

### Missing Shutdown

Spawning team members without ever shutting them down.

**Problem**: Orphaned agents consuming resources, stale team state files.

**Fix**: Every team creation must have a corresponding shutdown path. Use `shutdown_request` for each teammate, then `TeamDelete`.

## Best Practices

### Right Granularity

**Agent granularity**: Not too broad, not too narrow.

Too broad: "general-purpose-helper" (defeats purpose of specialization)
Too narrow: "checks-for-sql-injection-in-nodejs-express-apps-only" (too specific)
Right: "security-reviewer specializing in web application vulnerabilities"

### Clear Responsibilities

**Each agent should have clear, non-overlapping responsibility**.

Bad: Two agents both "review code for quality" (overlap, confusion)
Good: "security-reviewer" + "performance-analyzer" (distinct concerns)

### Minimize Handoffs

**Minimize information loss at boundaries**.

Each handoff is opportunity for context loss. Structured handoff formats prevent this.

### Parallel Where Possible

**Parallelize independent work**.

If agents don't depend on each other's outputs, run them concurrently.

### Coordinator Lightweight

**Keep coordinator logic lightweight**.

Heavy coordinator = bottleneck. Coordinator should route and synthesize, not do deep work itself.

### Cost Optimization

**Use model tiers strategically**.

- Planning/validation: Sonnet (needs intelligence)
- Execution of clear tasks: Haiku (fast, cheap, still capable)
- Highest stakes decisions: Opus
- Bulk processing: Haiku

### Task List As Source Of Truth

**For Agent Teams, the task list is the canonical state within a session**.

Messages are ephemeral context. Task state (pending/in_progress/completed, owner, blockedBy) is the durable record within a session. For cross-session durability, PLAN.md serves as the backup — updated per-task, not at wave boundaries. LEADER-STATE.md captures session context (active teammates, guidance, retry patterns) that neither TaskList nor PLAN.md can. Design workflows around task state transitions, not message exchanges.

### Prefer Subagents Over Teams

**Default to subagents. Upgrade to teams only when needed.**

Subagents are simpler, cheaper, and easier to debug. Teams add messaging, task management, and lifecycle complexity. Use teams when agents genuinely need to coordinate across turns — not just because the task involves multiple agents.
