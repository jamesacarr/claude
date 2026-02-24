# Context Management

> Strategies for managing LLM context windows, memory architecture, and state persistence in agents.

## Contents

- [Core Problem](#core-problem)
- [Memory Architecture](#memory-architecture)
- [Context Strategies](#context-strategies)
- [Agent Patterns](#agent-patterns)
- [Team Agent Context](#team-agent-context)
- [Anti-Patterns](#anti-patterns)
- [Best Practices](#best-practices)

## Core Problem

"Most agent failures are not model failures, they are context failures."

### Stateless Nature

LLMs are stateless by default. Each invocation starts fresh with no memory of previous interactions.

**For agents, this means**:
- Long-running tasks lose context between tool calls
- Repeated information wastes tokens
- Important decisions from earlier in workflow forgotten
- Context window fills with redundant information

### Context Window Limits

Full conversation history leads to:
- Degraded performance (important info buried in noise)
- High costs (paying for redundant tokens)
- Context limits exceeded (workflow fails)

**Critical threshold**: When context approaches limit, quality degrades before hard failure.

## Memory Architecture

| Type | Scope | Implementation | Use For |
|------|-------|----------------|---------|
| Short-term | Last 5-9 interactions | Preserved in context window | Current task state, recent tool results, immediate decisions |
| Long-term | Persistent across sessions | External storage (files, databases, vector stores) | Historical patterns, accumulated knowledge, user preferences |
| Working | Current context + retrieved memories | STM + retrieved LTM + current tool outputs | Active reasoning -- what fits in the context window |
| Core | Actively used in current interaction | Minimal subset kept always present | Task goal, constraints, critical requirements, workflow state |
| Archival | Persistent, rarely accessed | Searchable external storage | Full transcripts, tool logs, historical metrics, deprecated approaches |

## Context Strategies

### Summarization

**Pattern**: Move information from context to searchable database, keep summary in memory.

#### When To Summarize

Trigger summarization when:
- Context reaches 75% of limit
- Task transitions to new phase
- Information is important but no longer actively needed
- Repeated information appears multiple times

#### Summary Quality

**Quality guidelines**:

1. **Highlight important events**
```markdown
Bad: "Reviewed code, found issues, provided fixes"
Good: "Identified critical SQL injection in auth.ts:127, provided parameterized query fix. High-priority: requires immediate attention before deployment."
```

2. **Include timing for sequential reasoning**
```markdown
"First attempt: Direct fix failed due to type mismatch.
Second attempt: Added type conversion, introduced runtime error.
Final approach: Refactored to use type-safe wrapper (successful)."
```

3. **Structure into categories vs long paragraphs**
```markdown
Issues found:
- Security: SQL injection (Critical), XSS (High)
- Performance: N+1 query (Medium)
- Code quality: Duplicate logic (Low)

Actions taken:
- Fixed SQL injection with prepared statements
- Added input sanitization for XSS
- Deferred performance optimization (noted in TODOs)
```

**Benefit**: Organized grouping improves relationship understanding.

#### Example Workflow

```markdown
## Context Management

When conversation history exceeds 15 turns:
1. Identify information that is:
   - Important (must preserve)
   - Complete (no longer actively changing)
   - Historical (not needed for next immediate step)
2. Create structured summary with categories
3. Store full details in file (archival memory)
4. Replace verbose history with concise summary
5. Continue with reduced context load
```

### Sliding Window

**Pattern**: Recent interactions in context, older interactions as vectors for retrieval.

#### Implementation

```markdown
## Sliding Window Strategy

Maintain in context:
- Last 5 tool calls and results (short-term memory)
- Current task state and goals (core memory)
- Key facts from user requirements (core memory)

Move to vector storage:
- Tool calls older than 5 steps
- Completed subtask results
- Historical debugging attempts
- Exploration that didn't lead to solution

Retrieval trigger:
- When current issue similar to past issue
- When user references earlier discussion
- When pattern matching suggests relevant history
```

**Benefit**: Bounded context growth, relevant history still accessible.

### Semantic Context Switching

**Pattern**: Detect context changes, respond appropriately.

#### Example

```markdown
## Context Switch Detection

Monitor for topic changes:
- User switches from "fix bug" to "add feature"
- Agent transitions from "analysis" to "implementation"
- Task scope changes mid-execution

On context switch:
1. Summarize current context state
2. Save state to working memory/file
3. Load relevant context for new topic
4. Acknowledge switch: "Switching from bug analysis to feature implementation. Bug analysis results saved for later reference."
```

**Prevents**: Mixing contexts, applying wrong constraints, forgetting important info when switching tasks.

### Scratchpads

**Pattern**: Record intermediate results outside LLM context.

#### Use Cases

**When to use scratchpads**:
- Complex calculations with many steps
- Exploration of multiple approaches
- Detailed analysis that may not all be relevant
- Debugging traces
- Intermediate data transformations

**Implementation**:
```markdown
## Scratchpad Workflow

For complex debugging:
1. Create scratchpad file: `.claude/scratch/debug-session-{timestamp}.md`
2. Log each hypothesis and test result in scratchpad
3. Keep only current hypothesis and key findings in context
4. Reference scratchpad for full debugging history
5. Summarize successful approach in final output
```

**Benefit**: Context contains insights, scratchpad contains exploration. User gets clean summary, full details available if needed.

### Smart Memory Management

**Pattern**: Auto-add key data, retrieve on demand.

#### Smart Write

```markdown
## Auto Capture

Automatically save to memory:
- User-stated preferences: "I prefer TypeScript over JavaScript"
- Project conventions: "This codebase uses Jest for testing"
- Critical decisions: "Decided to use OAuth2 for authentication"
- Frequent patterns: "API endpoints follow REST naming: /api/v1/{resource}"

Store in structured format for easy retrieval.
```

#### Smart Read

```markdown
## Auto Retrieval

Automatically retrieve from memory when:
- User asks about past decision: "Why did we choose OAuth2?"
- Similar task encountered: "Last time we added auth, we used..."
- Pattern matching: "This looks like the payment flow issue from last week"

Inject relevant memories into working context.
```

### Compaction

**Pattern**: Summarize near-limit conversations, reinitiate with summary.

#### Workflow

```markdown
## Compaction Workflow

When context reaches 90% capacity:
1. Identify essential information:
   - Current task and status
   - Key decisions made
   - Critical constraints
   - Important discoveries
2. Generate concise summary (max 20% of context size)
3. Save full context to archival storage
4. Create new conversation initialized with summary
5. Continue task in fresh context

Summary format:
**Task**: [Current objective]
**Status**: [What's been completed, what remains]
**Key findings**: [Important discoveries]
**Decisions**: [Critical choices made]
**Next steps**: [Immediate actions]
```

**When to use**: Long-running tasks, exploratory analysis, iterative debugging.

## Agent Patterns

### Stateful Agent

**For long-running or frequently-invoked agents**:

```markdown
---
name: code-architect
description: Maintains understanding of system architecture across multiple invocations
tools: Read, Write, Grep, Glob
model: sonnet
---

## Role

You are a system architect maintaining coherent design across project evolution.

## Memory Management

On each invocation:
1. Read `.claude/memory/architecture-state.md` for current system state
2. Perform assigned task with full context
3. Update architecture-state.md with new components, decisions, patterns
4. Maintain concise state (max 500 lines), summarize older decisions

State file structure:
- Current architecture (always up-to-date)
- Recent changes (last 10 modifications)
- Key design decisions (why choices were made)
- Active concerns (issues to address)
```

### Stateless Agent

**For simple, focused agents**:

```markdown
---
name: syntax-checker
description: Validates code syntax without maintaining state
tools: Read, Bash
model: haiku
---

## Role

You are a syntax validator. Check code for syntax errors.

## Workflow

1. Read specified files
2. Run syntax checker (language-specific linter)
3. Report errors with line numbers
4. No memory needed - each invocation is independent
```

**When to use stateless**: Single-purpose validators, formatters, simple transformations.

### Context Inheritance

**Inheriting context from main chat**:

Agents automatically have access to:
- User's original request
- Any context provided in invocation

```markdown
Main chat: "Review the authentication changes for security issues.
           Context: We recently switched from JWT to session-based auth."

Agent receives:
- Task: Review authentication changes
- Context: Recent switch from JWT to session-based auth
- This context informs review focus without explicit memory management
```

## Team Agent Context

> Team members face unique context challenges because they persist across turns, coordinate with peers, and manage shared state. This section covers patterns specific to the Agent Teams model.

### Context Sources For Team Members

Team members draw context from multiple sources:

| Source | When Loaded | Contents |
|--------|------------|----------|
| Agent prompt | On spawn | Role, capabilities, workflow instructions |
| Initial task prompt | On spawn | I/O contract (Task/Context/Input/Expected Output) |
| Team config | On demand | Teammate names, types, IDs (`~/.claude/teams/{name}/config.json`) |
| Task list | On demand | Task descriptions, status, owners, dependencies |
| Messages | Delivered async | Instructions, status updates, peer context |
| Files | On demand | Shared artifacts, plan files, codebase |

### Context Budget Per Turn

Team members go idle between turns. Each turn they receive:
- Their full conversation history (grows over time)
- Any queued messages from teammates
- System idle notifications

**Risk**: Long-lived team members accumulate context from many turns. Unlike subagents (fresh context each time), team members carry all prior turns.

**Mitigation strategies**:
- Keep messages concise — avoid dumping full file contents in SendMessage
- Use file references instead of inline content: "See `.planning/task-3/RESEARCH.md`" not the full file
- Task descriptions carry the permanent context; messages carry transient updates
- Complex data goes in files, not messages

### Shared State via Task List

The task list serves as externalized working memory for the team:

```markdown
Task description = durable context (what needs doing, acceptance criteria)
Task status = current state (pending/in_progress/completed)
Task owner = who's responsible
Task dependencies = what blocks what

Pattern: Write context into task descriptions, not messages.
```

This keeps context discoverable by any teammate, not buried in pairwise message history.

### Context Isolation Between Teammates

Each teammate has its own context window. They cannot see each other's internal reasoning or tool call history — only what's explicitly shared via:
- SendMessage (direct communication)
- Task list (shared state)
- Files (shared artifacts)

**Design implication**: When an executor discovers something that affects another executor, it must explicitly share via message or file. Shared understanding doesn't happen automatically.

### Team Lead Context Load

The team lead is the most context-heavy role because it:
- Receives messages from all teammates
- Tracks task state across all work
- Makes routing and escalation decisions
- Integrates results

**Mitigation**:
- Keep lead logic lightweight (route and synthesize, don't do deep work)
- Teammates write detailed results to files, send brief summaries via message
- Use task state (not message history) as the source of truth for progress
- Delegate analysis to subagents when the lead needs to process complex output

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Context Dumping | Including everything "just in case" buries important info, wastes tokens, degrades performance | Include only what is relevant for current task; everything else is retrievable |
| No Summarization | Unbounded context growth causes sudden overflow mid-task and quality degradation before failure | Proactive summarization at 75% capacity, continuous compaction |
| Lossy Summarization | Summaries that discard critical info (e.g. "tried several approaches, fixed bug" with no details) | Preserve essential facts, decisions, and rationale; send details to archival storage |
| No Memory Structure | Unstructured memory (long paragraphs, no organization) is hard to retrieve from and poor for LLM reasoning | Use structured memory with categories, bullet points, clear sections |
| Context Failure Ignorance | Assuming all failures are model limitations instead of checking whether relevant info is present, organized, or buried | Audit context quality (presence, organization, signal-to-noise) before blaming the model |
| Verbose Team Messages | Sending full file contents or detailed analysis via SendMessage instead of writing to files and sending references | Write artifacts to shared files; send brief summaries with file paths via messages |
| No Team State Externalization | Tracking team progress purely through messages with no task list updates | Use TaskUpdate for state transitions; messages supplement, they don't replace task state |

## Best Practices

| Practice | Rule | Benefit |
|----------|------|---------|
| Core Memory Minimal | If information is not needed for the next 3 steps, it does not belong in core memory | Keeps context focused and high-signal |
| Summaries Structured | Use categorized templates (Status, Completed, Active, Decisions, Next) | Scannable summaries improve retrieval and reasoning |
| Timing Matters | Include sequence in summaries: "First tried X (failed), then tried Y (worked)" | Preserves causal reasoning that flat summaries lose |
| Retrieval Over Retention | Retrieve information on-demand rather than keeping it in context always | Frees context for active work; exception: frequently-used core facts |
| External Storage | Use filesystem for logs, traces, exploration results, historical data; use context for task state, decisions, active workflow | Right data in the right place -- context stays lean, nothing is lost |
| Files Over Messages | Share complex data via files, not SendMessage; messages carry references and summaries | Prevents context bloat in team member windows |
| Task Descriptions As Context | Write durable context into task descriptions, not ephemeral messages | Any teammate can discover context by reading the task list |

For prompt caching strategies, see [agents.md](agents.md#prompt-caching).
