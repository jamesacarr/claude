---
name: skill-name
description: What it does with the tool. Use when trigger conditions. Do NOT use for negative triggers (use other-skill).
---

# Skill Name

## Essential Principles

- **Convention:** Tool-specific conventions and gotchas
- ...

## Prerequisites

**CLI tool:**

```bash
command -v {tool} >/dev/null 2>&1
```

If not found: `{install-command}`.

If the tool requires authentication, also verify:

```bash
{tool} auth status
```

If not authenticated: `{auth-command}`.

**MCP server:**

Verify the MCP server is available by calling a lightweight tool (e.g., `mcp__{server}__list` or equivalent). If unavailable, instruct the user to add the server to their MCP configuration.

## Quick Start

**CLI tool:**

```bash
{tool} common-command-1
{tool} common-command-2
```

**MCP server:**

```
mcp__{server}__operation-1  arg1="value"
mcp__{server}__operation-2  arg1="value"
```

Pick ONE variant (CLI or MCP) per skill. Both are shown here for template reference.

## {Operation Group 1}

### Step 1: ...

Multi-step operations use numbered steps.

```bash
{tool} subcommand --flag value
```

| Flag | Purpose |
|------|---------|
| `--flag` | What it does |

### Step 2: ...

...

## {Operation Group 2}

### {Named Sub-Operation A}

Independent sub-operations use named headings instead of steps.

### {Named Sub-Operation B}

...

## Other Operations

| Operation | Command |
|-----------|---------|
| List items | `{tool} list` |

## Success Criteria

- ...
