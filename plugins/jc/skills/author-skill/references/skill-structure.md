# Skill Structure

> Three structural components: YAML frontmatter (metadata), Markdown body with standardized headings (content), and progressive disclosure (file organization). No XML tags.

## YAML Frontmatter

**Required fields:**
```yaml
---
name: skill-name-here
description: What it does and when to use it (third person, specific triggers)
---
```

**Name:** Max 64 chars, lowercase-with-hyphens, must match directory, no "anthropic"/"claude". Convention: `create-*`, `manage-*`, `setup-*`, `generate-*`, `build-*`, `use-*` (tool skills).

**Description:** Non-empty, max 1024 chars, third person. **CRITICAL:** Description = triggering conditions, NOT workflow summary — Claude may follow description instead of reading full skill content.

**Description format:** `"<Capability statement>. Use when <trigger conditions>."` — always include both halves.
- GOOD: `"Guides systematic root-cause investigation for bugs and failures. Use when encountering any bug, test failure, or unexpected behavior."`
- BAD: `"Use when encountering any bug"` (missing capability)
- BAD: `"Guides debugging"` (missing trigger)

**Naming conflicts:** If two skills could match the same user intent, differentiate by making trigger conditions more specific. One skill should clearly own the narrower case. If overlap persists, merge the skills or add a `## When to Use` section with explicit disambiguation.

**Optional frontmatter fields:**

| Field | Purpose | Example |
|-------|---------|---------|
| `context: fork` | Runs skill in a forked context (isolated from main) | Auditing, analysis tasks |
| `context: agent` | Runs as a subagent (one-shot, returns result) | Automated pipelines |
| `context: disable-model-invocation` | Prevents automatic model selection | Static analysis skills |
| `user-invocable: false` | Hides from user skill list (only system-invocable) | Internal helper skills |
| `$ARGUMENTS` | Access to arguments passed after skill name | `/skill-name arg1 arg2` |

## Body Structure

Use **Markdown headings only** — no XML tags anywhere. Keep Markdown formatting within content (bold, tables, code blocks, lists).

**No XML rule:** Skills, workflows, and references must use pure Markdown. XML tags create a non-standard convention, produce inconsistency when mixed with Markdown content, and don't provide benefits over well-structured Markdown + file decomposition.

**Standardized heading names** — use these for consistency across skills:

| Concept | Heading | NOT |
|---------|---------|-----|
| What not to do | `## Anti-Patterns` | `## Red Flags`, `## Common Mistakes` |
| Excuse-busting | `## Rationalizations` | `## Rationalization Prevention` |
| Usage guidance | `## When to Use` | `## Usage`, `## Applicability` |
| Related skills | `## Related Skills` | ad hoc prose |
| Sequential actions | `## Step N: Title` inside workflow | `## Phase 1`, `## Phase: Name` |
| Core rules | `## Essential Principles` | `## Rules`, `## Guidelines` |
| User menu | `## Intake` | `## Options`, `## Menu` |
| Route mapping | `## Routing` | `## Dispatch`, `## Navigation` |
| File listing | `## References` / `## Workflows` | `## Index`, `## Files` |

## Negative Triggers

Use the `"Do NOT use for..."` pattern in descriptions to prevent mis-routing between related skills.

**Format:** Add after the trigger conditions in the description field.

```yaml
description: Expert guidance for authoring Skills. Use when working with SKILL.md files. Do NOT use for agent authoring (use author-agent).
```

**When to add:** Two skills share overlapping trigger words. One skill is a superset that could absorb the other's cases. Users frequently invoke the wrong skill.

**Testing:** Verify with trigger tests — "Should NOT trigger on [excluded case]" scenarios. See references/tdd-for-skills.md.

## Router Pattern

For complex skills with multiple workflows:

```
skill-name/
├── SKILL.md              # Router + essential principles
├── workflows/            # Step-by-step procedures (FOLLOW)
│   ├── workflow-a.md
│   └── workflow-b.md
├── references/           # Domain knowledge (READ)
├── templates/            # Output structures (COPY + FILL)
└── scripts/              # Reusable code (EXECUTE)
```

**SKILL.md router headings:** Per `templates/router-skill-template.md`.

**Use when:** Multiple distinct workflows, different refs per workflow, essential principles that can't be skipped, skill beyond 200 lines.

**Optional directories:**

| Directory | Purpose | Use When |
|-----------|---------|----------|
| `templates/` | Output structures to COPY + FILL | Skill produces structured output (reports, configs, boilerplate) |
| `scripts/` | Reusable code to EXECUTE | Skill automates repeatable shell/code operations |

Templates contain skeleton files with `{placeholder}` markers. Scripts contain executable code the skill instructs Claude to run.

## Templates

Templates are the source of truth for required headings. Located in `templates/`. Read the template before authoring — headings present in the template are required.

| Template | Use For |
|----------|---------|
| `simple-skill-template.md` | Single-file SKILL.md |
| `tool-skill-template.md` | CLI/MCP tool-teaching SKILL.md |
| `router-skill-template.md` | Multi-workflow SKILL.md |
| `workflow-template.md` | Step-by-step procedures |
| `reference-template.md` | Domain knowledge / lookup |

**Entry pattern:** Workflows and references share a common entry: `# Heading` + `> blockquote summary`. SKILL.md files do NOT use a blockquote summary — the YAML description field serves as the summary.

## Skill Placement

**Global skills** (`~/.claude/skills/`): Reusable across all projects.

**Project skills** (`.claude/skills/` in repo root): Project-specific, committed to version control.

**Plugin skills** (`{plugin-root}/skills/`): Bundled with a plugin.

**Marketplace skills**: Within plugins managed by a marketplace (`marketplace.json`).

| Criterion | Global | Project | Plugin | Marketplace |
|-----------|--------|---------|--------|-------------|
| Applies to multiple repos | Yes | — | — | — |
| References project-specific paths/APIs | — | Yes | — | — |
| Shared with team via git | — | Yes | Yes | Yes |
| Personal workflow preference | Yes | — | — | — |
| Bundled with a plugin | — | — | Yes | Yes |
| Requires plugin selection | — | — | — | Yes |

**Precedence:** Plugin > Project > Global. Avoid name collisions — prefix project skills with the project name if ambiguous.

## Progressive Disclosure

SKILL.md = overview; reference files = details. Claude loads refs only when needed.

Rules: SKILL.md under ~100 lines (lean router). References one level deep (no nesting). Add TOC to refs over 100 lines. Forward slashes for paths.
