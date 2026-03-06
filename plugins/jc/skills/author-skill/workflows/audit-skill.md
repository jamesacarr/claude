# Audit Skill

> Audit a skill's structure, instruction wording, and behavioral effectiveness, producing a unified report with severity ratings. Structural audit, wording review, behavioral testing, report compilation, and fixes all delegate to subagents.

## Goal

Produce a unified audit report covering structural compliance, instruction wording quality, and behavioral effectiveness.

## Prerequisites

None.

## Steps

### Step 1: Select Skill (Main)

```bash
ls {skills-dir}/
```

Present as numbered list, ask: "Which skill would you like to audit? (enter number or name)"

### Step 2: Analysis (Parallel Subagents)

Launch structural audit and wording review in parallel — both are independent read-only analyses.

**2a: Structural Audit**

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

**If `audit-skill-auditor` is unavailable:** Stop and alert user. Do not proceed with the audit — no manual structural checks, no partial behavioral testing. The validation-gates.md manual fallback does NOT apply to standalone audits.

**2b: Wording Review**

```
Task tool parameters:
  subagent_type: "jc:wording-reviewer"
  prompt: |
    ## Task
    Review instruction quality in the skill files.
    Read-only analysis — do not modify any files.

    ## Input
    Target directory: {skills-dir}/{skill-name}/
    Writing guide: {skill-base-dir}/references/writing-effective-skills.md

    ## Expected Output
    Per your standard output format.
```

### Step 3: Behavioral Test (Main orchestrates DEC)

Structural correctness and good wording do not guarantee behavioral effectiveness. After reviewing the structural report (including the Gaps section) and wording review, identify the skill type (discipline, technique, pattern, or reference).

Follow references/tdd-for-skills.md DEC pattern. Main context orchestrates all phases.

**3a: Design scenarios (Phase A)**

Launch 1 subagent to design scenarios. Pass: skill content, structural audit gaps from Step 2a, wording issues from Step 2b, skill type. Returns numbered scenario specs.

**3b: Execute GREEN scenarios (Phase B)**

Launch N scenario subagents in parallel using the GREEN variant template from tdd-for-skills.md. Inline skill content.

**Audit-specific note:** Skip RED phase — auditing an existing skill that's already in use. GREEN-only testing verifies current behavioral effectiveness.

**3c: Trigger scenarios (Phase B)**

In addition to behavioral scenarios, include trigger verification:
- 2-3 should-trigger queries (realistic prompts matching the skill)
- 2-3 should-NOT-trigger queries (near-misses, especially for skills with negative triggers)

Report trigger results in the Behavioral Verification table with Type = "trigger".

**3d: Compile, Merge & Report (Subagent)**

Launch a compilation subagent that evaluates all results and produces the unified report. This keeps scenario evaluation and report merging out of main context.

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Evaluate behavioral test results, merge with structural audit and wording
    review findings, and produce a unified audit report.

    ## Context
    - Skill: {skill-name}
    - Skill directory: {skills-dir}/{skill-name}/
    - Report format: read {skill-base-dir}/references/audit-output-format.md
    - Per-scenario grading: PASS (correct + cites skill), WEAK (correct, no cite),
      FAIL (wrong choice), EVASION (invents fourth option)
    - Eval self-critique: flag non-discriminating scenarios — would pass without
      the skill, can't distinguish correct from incorrect, or a wrong output could
      still satisfy. These create false confidence.
    - Evidence filtering: each finding from auditors includes an evidence tag
      (verified/pattern-match/inference). Suppress findings tagged `inference` + `Low`
      severity — they are low-confidence noise. At the report bottom, add:
      "N low-confidence findings suppressed. Re-run with --verbose to include."
      (omit if N=0). When the user passes --verbose, include all findings.

    ## Input
    **Structural audit results:**
    {paste structural audit output from Step 2a}

    **Wording review results:**
    {paste wording review output from Step 2b}

    **Behavioral scenario results:**
    {for each scenario: name, type, correct answer, agent's response}

    **Trigger test results:**
    {for each trigger query: query, expected, actual}

    ## Expected Output
    Return as structured stdout:

    ```
    ## Result
    <PASS | FINDINGS | FAIL>

    ## Summary
    1-2 sentence verdict covering structural, wording, and behavioral results.

    ## Details
    Unified report per audit-output-format.md including:
    - Structural findings (tagged S), wording findings (tagged W), behavioral results (tagged B)
    - Improvement Suggestions table with priority/category/expected-impact
    - Eval quality flags for non-discriminating scenarios
    ```
```

Review the report. For any FAIL outcomes: launch meta-test subagent per tdd-for-skills.md Meta-Testing section, then update the report.

### Step 4: Auto-Fix (Main orchestrates)

**Structural + wording fixes** (formatting, missing headings, authority-without-why, ambiguous instructions): launch a subagent to apply all at once.

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Apply structural and wording fixes to a skill based on audit findings.

    ## Context
    - Wording guide: {skill-base-dir}/references/writing-effective-skills.md (read first)
    - Structural fixes: apply as specified (formatting, headings, line count)
    - Wording fixes: rewrite instructions to lead with reasoning.
      Pair any remaining MUST/NEVER with an explanation of why.
      Don't remove authority language — add the missing "because".

    ## Input
    - Skill directory: {skills-dir}/{skill-name}/
    - Structural fixes: {list structural issues from report}
    - Wording fixes: {list wording issues from report}

    ## Expected Output
    Return as structured stdout:

    ```
    ## Result
    <PASS | ERROR>

    ## Summary
    Applied X structural and Y wording fixes.

    ## Details
    List of changes made with file:line references.
    ```
```

**Behavioral fixes** (description, workflow logic): each gets its own RED → GREEN → REFACTOR cycle. Use the Single-Scenario Shortcut from tdd-for-skills.md — one targeted scenario per fix, run GREEN only (the audit already established the baseline).

Present unified report with all fixes applied and their verification results.
Ask user only if a fix attempt fails after 3 iterations: "This issue couldn't be auto-resolved. Want me to try a different approach, or leave it for manual review?"

## Validation

Verify the report includes all required sections from `references/audit-output-format.md`. Confirm behavioral scenarios were run (not skipped).

## Rollback

Audits are read-only — no rollback needed. If fixes were applied and introduced regressions, revert via git.
