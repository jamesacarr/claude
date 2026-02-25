# Validation Gates

> Mandatory validation gates run at the end of every workflow that creates or modifies skill content.

## Structural Audit

Launch the `audit-skill-auditor` agent via Task tool using the I/O contract format:

```
Task tool parameters:
  subagent_type: "jc:audit-skill-auditor"
  prompt: |
    ## Task
    Audit the skill for structural correctness, content quality, token efficiency, and coverage gaps.

    ## Context
    - **Prior work:** {summary of what triggered the audit — new skill, edit, or standalone audit}
    - **Key findings:** {any known issues or areas of concern, or "None yet"}
    - **Constraints:** {scope — e.g., "structural only" or "full audit"}

    ## Input
    Skill directory: {skills-dir}/{skill-name}/

    ## Expected Output
    Per your standard output format.
```

Review the report. Fix any critical issues before proceeding.

**Fallback (if audit-skill-auditor unavailable):** Run the structural checklist manually — verify YAML frontmatter, headings match template, no XML tags. The structural requirements are in references/skill-structure.md. This fallback applies only to end-of-workflow validation gates (create/edit), NOT to standalone audits (see workflows/audit-skill.md).

## Token Efficiency Gate

Read references/token-efficiency.md. Run the checklist against all new or changed files. Every sentence must change agent behavior — if removing it wouldn't change output, delete it.

## Subagent I/O Contract Compliance

If the skill instructs spawning subagents via the Task tool, verify each prompt follows the I/O contract format (read `../../docs/agent-io-contract.md` relative to this skill's directory):

| Section | Check |
|---------|-------|
| `## Task` | Specific task description, not vague |
| `## Context` | Prior work, key findings, constraints filled in |
| `## Input` | Files, data, or artifacts the subagent needs |
| `## Expected Output` | Format, scope, detail level specified |

Also verify subagent templates do NOT use the `name` parameter (it creates team members, not foreground subagents). For `general-purpose` agents, verify prompts pass absolute paths resolved from `{skill-base-dir}` (the directory containing the skill's SKILL.md, resolved from the `Skill directory:` input).

**Skip if:** Skill never instructs Task tool usage.

## Description Freshness

If the edit added, removed, or changed what the skill handles: update the YAML `description` field. Stale descriptions cause mis-routing — Claude may follow the description instead of the skill body.
