---
name: author-agent
description: Creates, edits, audits, and deletes Claude Code agents. Use when working with agent .md files in agents/ directories, building or improving agents, testing agent behavior, or understanding agent structure and best practices. Do NOT use for SKILL.md files (use author-skill).
---

# author-agent

## Essential Principles

1. **Execution Capabilities Model.** Agents support one or more execution capabilities: subagent (one-shot via Task tool), forked skill (one-shot via `context: fork`), or team member (persistent via Task tool + `team_name` with SendMessage/TaskList coordination). An agent can be dual-purpose. Details: references/execution-models.md.
2. **Pure Markdown Structure.** No XML tags in agent body. Use Markdown headings only.
3. **Least-Privilege Tool Access.** Grant only the tools needed. Read-only: `Read, Grep, Glob`. Code modification: `Read, Edit, Bash, Grep`. Omit `tools` field only when full access is genuinely needed.
4. **Description Drives Routing.** Claude selects agents automatically based on the `description` field. Include: what it does + when to use it + differentiation from similar agents. Vague descriptions = never invoked.
5. **Agents Are Cached During Sessions.** Mid-session edits are NOT picked up by dedicated `subagent_type`. Test with `general-purpose` + inlined prompt (see audit-agent.md Step 3 for testing pattern).
6. **Delegate heavy work to subagents.** Main context handles intake, routing, and presenting results. Research, content generation, testing, and auditing run in subagents via Task tool with I/O contract prompts. Use `subagent_type` only — do NOT use the `name` parameter (it creates team members instead of foreground subagents). Resolve `{skill-base-dir}` from this skill's announced base directory and pass absolute paths to reference files in subagent prompts. Note: subagents cannot spawn other subagents — the main context must orchestrate all subagent calls directly.

## Intake

Read `references/path-resolution.md` and resolve `{agents-dir}` and `{plugin-docs}`. Announce context before proceeding.

What would you like to do?

1. Create an agent
2. Edit an agent
3. Audit an agent
4. Delete an agent

## Routing

| Response | Next Action | Workflow |
|----------|-------------|----------|
| 1, "create", "new", "build" | Ask: "What task should this agent handle?" | workflows/create-agent.md |
| 2, "edit", "improve", "modify", "update" | Ask: "Which agent?" | workflows/edit-agent.md |
| 3, "audit", "review", "check", "test" | Ask: "Which agent?" | workflows/audit-agent.md |
| 4, "delete", "remove", "deprecate", "retire" | Ask: "Which agent?" | workflows/delete-agent.md |

Read the matched workflow file and follow it exactly.

## Success Criteria

- Agent passes structural audit with no critical issues
- Execution capability compliance verified for all claimed capabilities
- Behavioral tests pass on representative scenarios
- Gap analysis identifies no critical missing capabilities
- Subagent I/O contract compliance verified on agents that spawn subagents
