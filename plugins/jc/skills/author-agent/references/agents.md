# Agents

> File format, YAML configuration, storage locations, execution models, tool security, model selection, and prompt caching for Claude Code agents.

## File Format
Agent file structure:

```markdown
---
name: your-agent-name
description: Description of when this agent should be invoked
tools: tool1, tool2, tool3 # Optional - inherits all tools if omitted
mcpServers: server1, server2 # Optional - MCP servers the agent needs access to
model: sonnet # Optional - specify model alias or 'inherit'
---

## Role
Your agent's system prompt using pure Markdown structure. This defines the agent's role, capabilities, and approach.

## Constraints
Hard rules using NEVER/MUST/ALWAYS for critical boundaries.

## Workflow
Step-by-step process for consistency.
```

**Critical**: Use pure Markdown structure in the body. Use Markdown headings (##, ###) for sections. Keep markdown formatting within content (bold, lists, code blocks).

### Configuration Fields
| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier using lowercase letters and hyphens |
| `description` | Yes | Natural language description of purpose. Include when Claude should invoke this. |
| `tools` | No | Comma-separated list. If omitted, inherits all tools from main thread |
| `skills` | No | Comma-separated list of skill identifiers the agent needs preloaded (e.g., `jc:test, jc:test-driven-development`). Without this field, the agent cannot invoke the listed skills |
| `mcpServers` | No | Comma-separated list of MCP server names the agent needs access to (e.g., `context7, time`). Each listed server requires at least one corresponding `mcp__{server}__*` tool in the `tools` field |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit`. If omitted, uses default agent model |

## Execution Models

Agents support one or more execution capabilities. See [execution-models.md](execution-models.md) for the full capabilities model.

### Subagent (One-Shot)
Agents execute in isolated contexts, receive input, do work, return result. No user interaction during execution.

**Key characteristics:**
- Agent receives input parameters from main chat or orchestrator
- Agent runs autonomously using available tools
- Agent returns final output/report
- User only sees final result, not intermediate steps

**This means:**
- Agents can use Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
- Agents can access MCP servers (non-interactive tools)
- Agents can make decisions based on their prompt and available data
- **Agents CANNOT use AskUserQuestion**
- **Agents CANNOT present options and wait for user selection**
- **Agents CANNOT request confirmations or clarifications from user**
- **User does not see agent's tool calls or intermediate reasoning**

### Team Member (Persistent)
Agents that participate in Agent Teams have additional coordination capabilities:

- **Can use** `SendMessage`, `TaskList`, `TaskUpdate`, `TaskGet`, `TaskCreate`
- **Can discover** teammates via `~/.claude/teams/{team-name}/config.json`
- **Must handle** shutdown requests gracefully
- **Must include** `## Team Behavior` section in prompt

### Workflow Implications
**When designing agent workflows:**

Keep user interaction in main chat:
```markdown
# Bad — Agent cannot do this
---
name: requirement-gatherer
description: Gathers requirements from user
tools: AskUserQuestion  # This won't work!
---

You ask the user questions to gather requirements...
```

```markdown
# Correct — Main chat handles interaction
Main chat: Uses AskUserQuestion to gather requirements
  ↓
Launch agent: Uses requirements to research/build (no interaction)
  ↓
Main chat: Present agent results to user
```

### Team Agent Frontmatter

Team agents use the same YAML frontmatter but their tools list must include coordination tools:

```yaml
---
name: team-executor
description: Implements tasks from PLAN.md using TDD. Use when spawned by the Implement skill or Team Leader.
tools: Read, Write, Edit, Bash, Grep, Glob, SendMessage, TaskList, TaskUpdate, TaskGet, TaskCreate
model: sonnet
---
```

## Storage Locations
| Type | Location | Scope | Priority |
|------|----------|-------|----------|
| **Project** | `.claude/agents/` | Current project only | Highest |
| **User** | `~/.claude/agents/` | All projects | Lower |
| **CLI** | `--agents` flag | Current session | Medium |
| **Plugin** | `{plugin-root}/agents/` | All projects using plugin | Lowest |
| **Marketplace** | `{selected-plugin}/agents/` | Resolved via marketplace.json | Lowest |

**Context resolution:** Use `references/path-resolution.md` to resolve `{agents-dir}` before any operation. The variable is set once during intake and used by all workflows.

### Plugin Directory Layout
```
plugin-root/
├── .claude-plugin/plugin.json
├── skills/{skill-name}/SKILL.md
├── agents/{agent-name}.md
├── commands/
└── .mcp.json
```

When agent names conflict, higher priority takes precedence.

### Troubleshooting Conflicts
**When the wrong version runs:**

1. Verify the resolved location: `ls {agents-dir}/{name}.md`
2. If edited mid-session: agents are cached. Start a new session to pick up changes.
3. To test current file content without restarting: use `subagent_type: "general-purpose"` with inlined prompt (Essential Principle #5).
4. To avoid future conflicts: remove or rename the lower-priority duplicate.

## Tool Configuration

### Inherit All Tools
Omit the `tools` field to inherit all tools from main thread:

```yaml
---
name: code-reviewer
description: Reviews code for quality and security
---
```

Agent has access to all tools, including MCP tools.

### Specific Tools
Specify tools as comma-separated list for granular control:

```yaml
---
name: read-only-analyzer
description: Analyzes code without making changes
tools: Read, Grep, Glob
---
```

Use `/agents` command to see full list of available tools.

## Model Selection

### Model Capabilities

| Model | Strengths | Use For |
|-------|-----------|---------|
| **Sonnet** (`sonnet`) | Strong agent capabilities, excellent planning and validation | Planning, complex reasoning, validation, critical decisions |
| **Haiku** (`haiku`) | Fast, cost-efficient, strong coding capabilities | Task execution, simple transformations, high-volume processing |
| **Opus** (`opus`) | Highest performance, most capable but slowest/most expensive | Highest-stakes decisions, most complex reasoning |
| **Inherit** (`inherit`) | Uses same model as main conversation | Ensuring consistent capabilities throughout session |

For Sonnet + Haiku orchestration patterns (optimal cost/performance), see [orchestration-patterns.md](orchestration-patterns.md).

### Decision Framework

| Task Type | Recommended Model | Rationale |
|-----------|------------------|-----------|
| Simple validation | Haiku | Fast, cheap, sufficient capability |
| Code execution | Haiku | Fast, capable |
| Complex analysis | Sonnet | Superior reasoning, worth the cost |
| Multi-step planning | Sonnet | Best for breaking down complexity |
| Quality validation | Sonnet | Critical checkpoint, needs intelligence |
| Batch processing | Haiku | Cost efficiency for high volume |
| Critical security | Sonnet | High stakes require best model |
| Complex debugging | Opus | Root cause analysis needs highest reasoning capability |
| Output synthesis | Sonnet | Ensuring coherence across inputs |

## Invocation

### Automatic
Claude automatically selects agents based on:
- Task description in user's request
- `description` field in agent configuration
- Current context

### Explicit
Users can explicitly request an agent:

```
> Use the code-reviewer agent to check my recent changes
> Have the test-runner agent fix the failing tests
```

## Management

### Using /agents Command
**Recommended**: Use `/agents` command for interactive management:
- View all available agents (built-in, user, project, plugin)
- Create new agents with guided setup
- Edit existing agents and their tool access
- Delete custom agents
- See which agents take priority when names conflict

### Direct File Management
**Alternative**: Edit agent files directly at `{agents-dir}/agent-name.md`.

`{agents-dir}` is resolved during path resolution — see `references/path-resolution.md`.

### CLI-Based Configuration
**Temporary**: Define agents via CLI for session-specific use:

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer. Use proactively after code changes.",
    "prompt": "You are a senior code reviewer. Focus on quality, security, and best practices.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

Useful for testing configurations before saving them.

## Tool Security

### Core Principle
**"Permission sprawl is the fastest path to unsafe autonomy."** - Anthropic

Treat tool access like production IAM: start from deny-all, allowlist only what's needed.

### Permission Patterns

| Trust Level | Tool Access | Example |
|-------------|-------------|---------|
| **Trusted** (user's own code) | Full tool access appropriate | Refactoring user's codebase |
| **Untrusted** (external inputs) | Read-only tools, no execution | Analyzing third-party API responses |

### Audit Checklist
- [ ] Does this agent need Write/Edit, or is Read sufficient?
- [ ] Should it execute code (Bash), or just analyze?
- [ ] Are all granted tools necessary for the task?
- [ ] What's the worst-case misuse scenario?
- [ ] Can we restrict further without blocking legitimate use?

**Default**: Grant minimum necessary. Add tools only when lack of access blocks task.

## Prompt Caching

### Benefits
Prompt caching for frequently-invoked agents:
- **90% cost reduction** on cached tokens
- **85% latency reduction** for cache hits
- Cached content: ~10% cost of uncached tokens
- Cache TTL: 5 minutes (default) or 1 hour (extended)

### Cache Structure
**Structure prompts for caching**:

```markdown
---
name: security-reviewer
description: ...
tools: ...
model: sonnet
---

[CACHEABLE SECTION - Stable content]
## Role
You are a senior security engineer...

## Focus Areas
- SQL injection
- XSS attacks
...

## Workflow
1. Read modified files
2. Identify risks
...

## Severity Ratings
...

--- [CACHE BREAKPOINT] ---

[VARIABLE SECTION - Task-specific content]
Current task: {dynamic context}
Recent changes: {varies per invocation}
```

**Principle**: Stable instructions at beginning (cached), variable context at end (fresh).

### When to Use
**Best candidates for caching**:
- Frequently-invoked agents (multiple times per session)
- Large, stable prompts (extensive guidelines, examples)
- Consistent tool definitions across invocations
- Long-running sessions with repeated agent use

**Not beneficial**:
- Rarely-used agents (once per session)
- Prompts that change frequently
- Very short prompts (caching overhead > benefit)

### Cache Management
**Cache lifecycle**:
- First invocation: Writes to cache (25% cost premium)
- Subsequent invocations: 90% cheaper on cached portion
- Cache refreshes on each use (extends TTL)
- Expires after 5 minutes of non-use (or 1 hour for extended TTL)

**Invalidation triggers**:
- Agent prompt modified
- Tool definitions changed
- Cache TTL expires

## Writing Prompts
See [writing-agent-prompts.md](writing-agent-prompts.md) for core principles, structure conventions, examples, and anti-patterns.
