# Edit Existing Skill

> Edit or improve an existing skill, delegating TDD and auditing to subagents.

## Goal

Make a targeted, tested improvement to an existing skill without introducing regressions. Main context identifies changes and presents results. Subagents handle TDD and auditing.

## Prerequisites

Read references/tdd-for-skills.md and references/skill-structure.md before starting.

## Steps

### Step 1: Read Current Skill (Main)

Read the existing SKILL.md and all supporting files. Understand:
- Current structure (simple vs router pattern)
- What the skill does
- Current test coverage (if any)

### Step 2: Identify Changes (Main)

Clarify what needs to change:
- Bug fix (skill doesn't work as intended)?
- Enhancement (add new capability)?
- Structural upgrade (apply template structure)?
- Bulletproofing (skill is being rationalized around)?

### Step 3: TDD Edit Cycle (Main orchestrates DEC)

Follow references/tdd-for-skills.md DEC pattern. Main context orchestrates all phases — subagents cannot spawn other subagents.

**3a: Design scenarios (Phase A)**

Launch 1 subagent to design scenarios targeting the specific change:
- Pass: change description, current skill content, specific gap or issue
- Subagent returns numbered scenario specs (Name, Type, Target, Prompt, Correct, Rationale)

For single-aspect edits (e.g., fixing one rule): use the Single-Scenario Shortcut — skip Phase A and write the scenario directly.

**3b: RED baseline (Phase B without skill)**

Launch N scenario subagents in parallel, each using the RED variant template from tdd-for-skills.md. No skill content inlined — establishes baseline behavior.

**3c: Review RED results & apply edit (Main)**

Review RED results — document rationalizations observed. Then apply the targeted edit to the skill files.

**3d: GREEN verification (Phase B with skill)**

Launch the same N scenarios in parallel using the GREEN variant template. Inline the **updated** skill content.

**3e: REFACTOR if needed**

If new rationalizations found in GREEN results: update skill to close loopholes, re-run Phase B (GREEN only) to verify.

### Step 4: Present Results (Main)

Review subagent output. Present:
- What was tested (RED phase baseline)
- What was changed (files and specific edits)
- Test results (GREEN phase verification)
- Any REFACTOR iterations needed

If new rationalizations found: discuss with user, then delegate another REFACTOR cycle if needed.

## Validation

Read references/validation-gates.md. Run all applicable gates:
1. **Description Freshness** — mandatory if capabilities changed (e.g., workflow added/removed, operations changed, trigger conditions narrowed)
2. **Structural Audit** — launch `audit-skill-auditor` subagent (prompt template in validation-gates.md)
3. **Token Efficiency Gate** — edits must not introduce filler, duplication, or verbose prose
4. **Subagent Input Compliance** — if skill spawns subagents, verify prompts follow the I/O contract

## Rollback

Revert modified files via git if the edit introduces regressions that cannot be resolved in the REFACTOR phase.
