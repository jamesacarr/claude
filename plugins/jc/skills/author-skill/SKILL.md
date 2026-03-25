---
name: author-skill
description: Creates, edits, audits, upgrades, and deletes Claude Code Skills. Use when working with SKILL.md files or skill directories. Do NOT use for agent authoring (use author-agent).
---

# author-skill

## Essential Principles

**Skills are prompts tested with TDD.** RED (baseline without skill) → GREEN (skill works) → REFACTOR (close loopholes).

1. **The Iron Law:** `NO SKILL WITHOUT A FAILING TEST FIRST` — baseline failures prove the gap exists before you write the fix. Applies to new skills AND edits. Details: references/tdd-for-skills.md.
2. **Skills are prompts.** Be clear, be direct, use Markdown headings. Only add context Claude doesn't have.
3. **SKILL.md is always loaded.** Keep it lean — details go in workflows/ and references/. Layout: references/skill-structure.md.
4. **Pure Markdown structure.** No XML tags. Standardized headings per template. Details: references/skill-structure.md. Anti-patterns: references/anti-patterns.md.
5. **Token efficiency.** Every token loads on every invocation. Say it once, tables over prose, eliminate filler. Checklist: references/token-efficiency.md.
6. **Delegate heavy work to subagents.** Main context handles intake, routing, and presenting results. Resolve `{skill-base-dir}` from this skill's announced base directory and pass absolute paths to reference files in subagent prompts. Details: references/tdd-for-skills.md and references/validation-gates.md.
7. **Write for understanding.** Models generalize better from reasoning than mandates — explain why, not just what. Escalate to authority language only when reasoning fails in TDD. Details: references/writing-effective-skills.md.
8. **Validation gates enforced** on all new/changed skills (references/validation-gates.md).

## Intake

Read `references/path-resolution.md` and resolve `{skills-dir}` and `{agents-dir}`. Announce context before proceeding.

What would you like to do?

1. Create a skill
2. Edit a skill
3. Audit a skill
4. Upgrade a simple skill to router pattern
5. Delete a skill

**Scope note:** Skills that spawn subagents are in scope (use option 1).

## Routing

| Response | Next Action | Workflow |
|----------|-------------|----------|
| 1, "create", "new", "build" | Ask: "Task-execution skill or domain expertise skill?" | workflows/create-skill.md |
| 2, "edit", "improve", "modify", "update" | Ask: "Which skill?" | workflows/edit-skill.md |
| 3, "audit", "review", "check", "test" | Ask: "Which skill?" (includes auto-fix) | workflows/audit-skill.md |
| 4, "upgrade", "router", "convert", "split" | Ask: "Which skill?" | workflows/upgrade-to-router.md |
| 5, "delete", "deprecate", "remove", "retire" | Ask: "Which skill?" | workflows/delete-skill.md |

