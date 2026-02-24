# Anti-Patterns

> Common mistakes in skill authoring. Covers structural, content, and process anti-patterns.

## Structural Anti-Patterns

- **XML tags in skill files:** Use Markdown headings (`## Objective`) not XML (`<objective>`). Markdown is the standard format — XML creates non-standard conventions and inconsistency.
- **Missing required headings:** See references/skill-structure.md for required headings by template type.
- **Deeply nested references:** Keep one level deep from SKILL.md. Claude may partially read nested files.
- **Windows paths:** Always forward slashes: `scripts/helper.py` not `scripts\helper.py`.
- **Name mismatch:** Directory name must match skill name exactly.

## Content Anti-Patterns

- **Vague description:** "Helps with documents" → "Extract text and tables from PDF files. Use when working with PDF files."
- **Workflow in description:** Summarizing process in description → Claude follows description, skips skill body. Use triggering conditions only.
- **Inconsistent POV:** Never "I can help you..." → Always third person: "Processes Excel files."
- **Narrative storytelling:** "In session 2025-10-03, we found..." → Extract the technique, discard the narrative.
- **Multi-language dilution:** One excellent example in the most relevant language. Claude can port.
- **Code in flowcharts:** Use code blocks for code, flowcharts only for non-obvious decisions.
- **Generic labels:** `helper1`, `step3` → Use semantic names.
- **Phase headings instead of step:** `## Phase 1`, `## Phase: Name` → Use `## Step N: Title` inside workflows. One heading pattern for all sequential actions.
- **Inconsistent heading names:** `## Red Flags` for anti-patterns, `## Common Rationalizations` for rationalizations → Use standardized names from skill-structure.md.
- **Description missing half:** Only trigger ("Use when...") or only capability ("Guides...") → Always include both: `"<Capability>. Use when <trigger>."`.
- **Too many options:** One default approach + escape hatch for special cases.

## Token Waste Anti-Patterns

See references/token-efficiency.md for principles, checklist, and common waste patterns table.

## Process Anti-Patterns

- **Batch creation:** Creating multiple skills without testing each. STOP after writing ANY skill — test before moving on.
- **Dynamic context execution:** When showing `!backtick` or `@ file` syntax in skills, add a space to prevent execution during skill load.

## Flowchart Rules

Use flowcharts ONLY for non-obvious decision points, process loops, or "A vs B" decisions. Never for reference material (→ tables), code examples (→ code blocks), or linear instructions (→ numbered lists).

## Code Examples

Choose most relevant language. Good examples: complete, runnable, commented (WHY not WHAT), from real scenarios. See references/token-efficiency.md principle #5 for compression rules.
