# Upgrade to Router

> Convert a simple single-file skill to the router pattern with workflows and references, delegating extraction and TDD to subagents.

## Goal

Convert a monolithic skill into the router pattern without losing content or degrading behavior.

## Prerequisites

Read references/skill-structure.md before starting.

## Steps

### Step 1: Select the Skill (Main)

```bash
ls {skills-dir}/
```

Present numbered list, ask: "Which skill should be upgraded to the router pattern?"

### Step 2: Verify It Needs Upgrading (Main)

Read the skill. Check:
- **Already a router?** (has workflows/ AND `## Intake` AND `## Routing`) → Offer to add workflows instead
- **Partial router?** (has workflows/ but missing `## Intake` or `## Routing`) → Stop and ask user: incomplete router state detected. Offer to audit first or complete the upgrade.
- **Should stay simple?** (under 200 lines, single workflow) → Explain router may be overkill, ask if they want to proceed
- **Good candidate:** Over 200 lines, multiple use cases, essential principles to enforce

### Step 3: Identify Components (Main)

Analyze and identify:
1. **Essential principles** — Rules that apply to ALL use cases
2. **Distinct workflows** — Different things a user might want to do
3. **Reusable knowledge** — Patterns, examples, technical details

Present findings and ask: "Does this breakdown look right?"

### Step 4: Delegate Extraction (Subagent)

Launch a subagent to create the directory structure and extract content:

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Extract a monolithic skill into the router pattern — create directory
    structure, split content into workflows and references, rewrite SKILL.md
    as a router.

    ## Context
    - Reference files: {skill-base-dir}/references/
      (read skill-structure.md; templates at {skill-base-dir}/templates/)
    - Component breakdown: {findings from step 3}

    ## Input
    - Skill path: {skills-dir}/{skill-name}/SKILL.md
    - Essential principles: {list from step 3}
    - Workflows to extract: {list with content mapping}
    - References to extract: {list with content mapping}

    ## Expected Output
    Write all files to {skills-dir}/{skill-name}/. Return:
    - List of files created/modified with line counts
    - Content mapping (which original sections went where)
    - Any decisions made during extraction
```

### Step 5: Present & Confirm (Main)

Review subagent output. Present:
- New file structure
- Content mapping (original → new location)
- Any decisions the subagent made

Ask: "Does this look right before I run TDD verification?"

### Step 6: TDD Verification (Main orchestrates DEC)

Follow references/tdd-for-skills.md DEC pattern. A structural rewrite is a significant edit — TDD is mandatory.

**6a: Design scenarios (Phase A)**

Launch 1 subagent to design regression scenarios covering key workflows and routing. Pass: both original and upgraded skill content so the subagent understands what changed.

**6b: RED — baseline with original skill (Phase B)**

Launch N scenario subagents in parallel using the GREEN variant template but with the **original** skill content (from git, pre-upgrade). This establishes what behavior the original skill produced.

**6c: GREEN — verify with upgraded skill (Phase B)**

Launch same N scenarios in parallel with the **upgraded** skill content (new router structure). Verify behavior matches or improves on baseline.

**6d: REFACTOR if any scenario degrades**

Fix extracted content, re-run Phase B with upgraded skill.

**Regression handling:** Minor regression (broken path, missing import) → fix in extracted workflow, re-test all. Structural omission (entire section lost) → reconstruct from original, re-test. Multiple omissions → roll back and restart extraction with a more careful mapping in Step 3.

Do not ship a partial upgrade — a router with broken workflows is worse than a working monolith.

### Step 7: Present Test Results (Main)

Review TDD results. Present outcomes and any regressions found.

## Validation

### Content Completeness

Compare original against new structure:
- All principles preserved (now inline), all procedures (now in workflows), all knowledge (now in references)
- No orphaned content, SKILL.md under ~100 lines

### Structural Audit

Launch `audit-skill-auditor` subagent (prompt template in references/validation-gates.md).

### Subagent I/O Contract Compliance

If the upgraded skill spawns subagents, verify all Task tool prompts follow the I/O contract format and do not use the `name` parameter. Details: references/validation-gates.md.

## Rollback

Restore original SKILL.md from git, delete the created `workflows/` and `references/` directories, and restart extraction with a more careful component mapping.
