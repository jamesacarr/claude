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

**If the skill has no prior test coverage:** The Iron Law minimum for edits is: write a test for your specific change only (references/tdd-for-skills.md). Retroactive coverage of untouched behavior is optional — don't block the edit to ask about it, because most edits are time-sensitive and full retroactive coverage can be done separately via the audit workflow. Proceed directly to Step 2.

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

### Step 4: Iterative Improvement (Main)

When the skill passes TDD but output quality is unsatisfactory.

**The loop:** test → review outputs → identify patterns → revise → retest

1. **Read transcripts, not just outputs.** The subagent's execution path reveals
   whether the skill's instructions are being followed, ignored, or misinterpreted.
   Look for:
   - Instructions the model skips (too verbose? buried in prose?)
   - Steps every run reinvents independently (bundle as a script)
   - Wasted effort: model doing unproductive work the skill told it to do (remove those instructions)
   - Outputs that are technically correct but miss the user's actual intent

2. **Generalize, don't overfit.** You're iterating on a few test cases but the skill
   will be used on many. Resist fiddly changes that fix one test but narrow the skill.
   If a stubborn issue persists, try a different framing or metaphor rather than
   adding more constraints.

3. **Explain the why.** If the model keeps ignoring an instruction, the instruction
   probably states WHAT without explaining WHY it matters. Reframe with reasoning
   rather than adding MUST/NEVER emphasis.

4. **Keep the prompt lean.** Each iteration should remove as much as it adds.
   If a section isn't pulling its weight in the outputs, cut it.

5. **Retest and compare.** Run the same prompts against the revised skill.
   Compare outputs side by side — did the revision actually improve things?

Stop when: all assertions pass, outputs are consistently good across test cases,
or further changes aren't producing meaningful improvement (max 3 rounds).
Report iteration history in the completion report.

### Step 5: Completion Report (Main)

Present a single summary covering all phases:
- What was changed (files and specific edits)
- TDD results: RED baseline vs GREEN verification, any REFACTOR iterations
- Trigger validation results (if description changed)
- Structural audit results: issues found and auto-fixed
- Any remaining issues requiring user attention

## Validation

Read references/validation-gates.md. Run all applicable gates:
1. **Description Freshness** — mandatory if capabilities changed (e.g., workflow added/removed, operations changed, trigger conditions narrowed)
2. **Trigger Validation** — if description was updated (or should have been per Description Freshness):
   generate 3-5 trigger/no-trigger queries and verify the updated description triggers correctly.
   Reuse any existing trigger queries from prior optimization if available.
3. **Structural Audit** — launch `audit-skill-auditor` subagent (prompt template in validation-gates.md)
4. **Token Efficiency Gate** — edits must not introduce filler, duplication, or verbose prose
5. **Subagent Input Compliance** — if skill spawns subagents, verify prompts follow the I/O contract

## Rollback

Revert modified files via git if the edit introduces regressions that cannot be resolved in the REFACTOR phase.
