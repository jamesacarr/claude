# Audit Skill

> Audit a skill's structure and behavioral effectiveness, producing a unified report with severity ratings. Both audit phases delegate to subagents.

## Goal

Produce a unified audit report covering both structural compliance and behavioral effectiveness.

## Prerequisites

None.

## Steps

### Step 1: Select Skill (Main)

```bash
ls {skills-dir}/
```

Present as numbered list, ask: "Which skill would you like to audit? (enter number or name)"

### Step 2: Structural Audit (Subagent)

Launch the `audit-skill-auditor` agent via Task tool using the I/O contract format:

```
Task tool parameters:
  subagent_type: "jc:audit-skill-auditor"
  prompt: |
    ## Task
    Audit the skill for structural correctness, content quality, completeness gaps, and token efficiency.

    ## Context
    - **Prior work:** {any prior audit results or known issues, or "Initial audit"}
    - **Key findings:** {anything observed during skill selection, or "None yet"}
    - **Constraints:** {scope — full audit unless user specified otherwise}

    ## Input
    Skill directory: {skills-dir}/{skill-name}/
    Reference files: {skill-base-dir}/references/

    ## Expected Output
    Per your standard output format.
```

The subagent handles: reading all files, running the structural checklist, identifying coverage gaps, and generating the severity-based report.

**If `audit-skill-auditor` is unavailable:** Stop and alert user. Do not proceed with the audit — no manual structural checks, no partial behavioral testing. The validation-gates.md manual fallback does NOT apply to standalone audits.

### Step 3: Behavioral Test (Main orchestrates DEC)

Structural correctness does not guarantee behavioral effectiveness. After reviewing the structural report (including the Gaps section), identify the skill type (discipline, technique, pattern, or reference).

Follow references/tdd-for-skills.md DEC pattern. Main context orchestrates all phases.

**3a: Design scenarios (Phase A)**

Launch 1 subagent to design scenarios. Pass: skill content, structural audit gaps from Step 2, skill type. Returns numbered scenario specs.

**3b: Execute GREEN scenarios (Phase B)**

Launch N scenario subagents in parallel using the GREEN variant template from tdd-for-skills.md. Inline skill content.

**Audit-specific note:** Skip RED phase — auditing an existing skill that's already in use. GREEN-only testing verifies current behavioral effectiveness.

**3c: Compile results (Phase C)**

Evaluate each result per tdd-for-skills.md evaluation criteria: PASS, WEAK, FAIL, EVASION. On FAIL, run meta-test per tdd-for-skills.md Meta-Testing section.

### Step 4: Present Unified Report (Main)

Merge structural findings (from audit-skill-auditor) with behavioral results (from behavioral tester). Present using the Output Format below. Mark each finding's source.

### Step 5: Offer Fixes (Main)

If issues found, ask: "Would you like me to fix these issues?"
1. **Fix all** 2. **Fix one by one** 3. **Just the report**

If user chooses Fix all or Fix one by one, **each fix MUST go through the full edit-skill.md TDD cycle:**

1. **RED** — Design a subagent pressure scenario that exposes the specific issue. Run it. Document the failure.
2. **GREEN** — Make the minimal edit to fix the issue. Re-run the same scenario. Confirm it passes.
3. **REFACTOR** — If new gaps appear, address them and re-test.

**Per-fix, not batched.** Each issue gets its own RED → GREEN → REFACTOR cycle. Do not batch fixes then run one test at the end — you lose failure isolation.

**Structural-only fixes** (cosmetic formatting, missing headings with obvious content, line count reduction) are exempt from subagent scenarios — verify structurally. All other fixes (behavioral, description, workflow logic) require subagent testing.

> **Anti-pattern:** Labeling direct edits as "RED/GREEN" without running actual subagent pressure scenarios is not TDD. RED means a subagent test that fails. GREEN means the same test passes after your edit.

## Validation

Verify the report includes all required sections from the Output Format below. Confirm behavioral scenarios were run (not skipped).

## Rollback

Audits are read-only — no rollback needed. If fixes were applied and introduced regressions, revert via git.

## Output Format

Use the format in references/audit-output-format.md.
