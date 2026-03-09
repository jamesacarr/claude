# Validation Gates

> Mandatory validation gates run at the end of every workflow that creates or modifies agent content.

## Structural Audit

Launch the `audit-agent-auditor` agent via Task tool using the I/O contract format:

```
Task tool parameters:
  subagent_type: "jc:audit-agent-auditor"
  prompt: |
    ## Task
    Audit the agent for structural correctness, content quality, execution capability compliance, and coverage gaps.

    ## Context
    - **Prior work:** {summary of what triggered the audit — new agent, edit, or standalone audit}
    - **Key findings:** {any known issues or areas of concern, or "None yet"}
    - **Constraints:** {scope — e.g., "structural only" or "full audit"}

    ## Input
    Agent file: {agents-dir}/{name}.md

    ## Expected Output
    Per your standard output format.
```

Review the report. Fix any critical issues before proceeding.

**Fallback (if audit-agent-auditor unavailable):** Run the structural checklist manually — verify YAML frontmatter, headings match template, no XML tags. The structural requirements are in references/agents.md.

## YAML & Tool Validation

**YAML syntax check** — re-read the file and verify:
- `---` delimiters present (opening and closing)
- All keys have colons (`name:`, not `name`)
- No bad indentation or unquoted special characters

**Tool name check** — if a `tools` field is specified, verify each tool name is valid.

**Valid tool names:** `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Glob`, `WebSearch`, `WebFetch`, `NotebookEdit`

Invalid tool names (e.g., `RunLinter`, `FormatCode`) silently fail at runtime — the agent runs without those tools and no error is shown. Use `Bash` to run CLI tools like linters and formatters.

**MCP server → tool check** — if `mcpServers` is specified, verify that `tools` includes at least one `mcp__{server}__*` tool per listed server. Without corresponding tools, the `mcpServers` declaration has no effect — the agent cannot call any server endpoints. Flag as High severity: the agent declares a dependency it cannot use.

## Execution Model Compliance

Verify the agent's declared execution capabilities match its content. See [execution-models.md](execution-models.md) for the full capabilities model.

| Capability | Required Content | Must NOT Have |
|------------|-----------------|---------------|
| **Subagent** | I/O contract-compatible workflow | `## Team Behavior`, SendMessage/TaskList in tools |
| **Team member** | `## Team Behavior` section, coordination tools in tools list, shutdown handling | — |
| **Dual-purpose** | Both subagent and team content, mode detection logic | — |

**Checks:**
- If agent has `## Team Behavior`: verify tools include `SendMessage`, `TaskList`, `TaskUpdate`, `TaskGet`, `TaskCreate`
- If agent has coordination tools but no `## Team Behavior`: flag as error (tools without instructions)
- If agent is dual-purpose: verify mode detection documented, both paths testable

## Team Agent Gates

**Additional gates for agents with team member capability:**

| Gate | What to Verify |
|------|----------------|
| **Shutdown handling** | Agent describes how it handles `shutdown_request` messages |
| **Task polling** | Agent checks TaskList after completing work |
| **Peer discovery** | Agent reads team config to find teammate names |
| **Status reporting** | Agent sends meaningful updates to team lead |
| **Message handling** | Agent processes incoming messages (task assignments, status requests, peer context) |

**Skip if:** Agent has no team member capability.

## Subagent I/O Contract Compliance

If the agent's workflow instructs spawning subagents via the Task tool, verify it follows the [I/O contract]({plugin-docs}/agent-io-contract.md) — TaskCreate-with-metadata pattern:

| Check | What to verify |
|-------|---------------|
| `TaskCreate` before spawn | Task created with metadata containing all structured parameters |
| Metadata keys match agent's Assignment table | Required keys present, types correct |
| Minimal spawn prompt | Prompt is just `Your task is {task-id}.` — no embedded I/O contract sections |
| `TaskGet` for results | Orchestrator reads completion metadata via TaskGet, not parsing stdout |

Also verify subagent templates follow the invocation rules in [execution-models.md](execution-models.md) (`subagent_type` only, no `name` parameter). For `general-purpose` agents, verify prompts pass absolute paths resolved from `{skill-base-dir}`.

**Skip if:** Agent never instructs Task tool usage.

## Description Freshness

If the edit added, removed, or changed what the agent handles: update the YAML `description` field. Stale descriptions cause mis-routing — Claude may follow the description instead of the agent body.
