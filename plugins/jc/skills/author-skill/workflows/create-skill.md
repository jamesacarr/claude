# Create New Skill

> Create a new skill from scratch using TDD methodology (RED → GREEN → REFACTOR), with heavy work delegated to subagents.

## Goal

Produce a tested, validated skill that demonstrably changes agent behavior. Main context handles intake, routing, and presenting results. Subagents handle research, content generation, TDD, and auditing.

## Prerequisites

Read references/tdd-for-skills.md and references/skill-structure.md before starting.

## Steps

### Step 1: Adaptive Requirements Gathering (Main)

**If user provided context** (e.g., "build a skill for X"):
→ Analyze what's stated, what can be inferred, what's unclear
→ Skip to asking about genuine gaps only

**If the conversation already contains a workflow** (e.g., user says "turn this into a skill"):
→ Extract from conversation history: tools used, sequence of steps, corrections the user made, input/output formats observed
→ Infer structure, scope, and skill type from extracted context
→ Only ask about genuine gaps that can't be inferred
→ Proceed directly to structure decision

**If user just invoked skill without context:**
→ Ask what they want to build

**Using AskUserQuestion**

Ask 2-4 domain-specific questions based on actual gaps:
- "What specific operations should this skill handle?"
- "Should this also handle [related thing] or stay focused on [core thing]?"
- "Task-execution skill, tool-usage skill (CLI/MCP), or domain expertise skill?"

**Decision Gate**

After initial questions, ask:
"Ready to proceed with building, or would you like me to ask more questions?"

### Step 2: Decide Structure (Main)

**Tool skill (teaches Claude to use a CLI or MCP server):**
→ Single SKILL.md using `templates/tool-skill-template.md`. Name: `use-{tool-name}`.

**Simple skill (single workflow, <200 lines):**
→ Single SKILL.md file with all content

**Complex skill (multiple workflows OR domain knowledge):**
→ Router pattern (see references/skill-structure.md for full layout): SKILL.md routes to workflows/ and references/.

**Internal helper skill (system-invocable only):**
→ Add `user-invocable: false` to YAML frontmatter to hide from user skill list.

### Step 3: Delegate Research + Content Generation (Subagent)

Launch a subagent to research (if needed) and write skill files:

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Research the domain (if tool skill) and create skill files following the
    specified structure and template.

    ## Context
    - Skill type: {tool|simple|complex}
    - Template: {template name from step 2} — read it before authoring
    - Templates directory: {skill-base-dir}/templates/
    - Requirements: {summary from step 1}
    - Skills directory: {skills-dir}
    - Reference files: (read all .md files in {skill-base-dir}/references/)

    ## Input
    - Skill name: {skill-name}
    - Operations: {list of operations from intake}
    - Structure decision: {simple|router} with rationale
    - Research needed: {yes/no — if tool skill, fetch CLI help/MCP schema/API docs}

    ## Expected Output
    Write all skill files to {skills-dir}/{skill-name}/. Return:
    - List of files created with line counts
    - Summary of skill capabilities
    - Any decisions made during content generation

    Before returning, self-review: Does every instruction explain WHY? Could any
    section be misinterpreted? Is anything repeated across files? Revise if needed.
```

Create directory first if needed:
```bash
mkdir -p {skills-dir}/{skill-name}
# If complex:
mkdir -p {skills-dir}/{skill-name}/workflows
mkdir -p {skills-dir}/{skill-name}/references
```

### Step 4: Review & Proceed (Main)

Review the subagent's output for obvious issues (missing files, wrong structure, empty sections).
If issues found: fix inline or re-run subagent. Do not stop for user confirmation — proceed directly to TDD.

### Step 5: TDD Testing (Main orchestrates DEC)

Follow references/tdd-for-skills.md DEC pattern. Main context orchestrates all phases — subagents cannot spawn other subagents.

**5a: Design scenarios (Phase A — runs once)**

Launch 1 subagent to design scenarios based on skill type and requirements. Returns numbered scenario specs (Name, Type, Target, Prompt, Correct, Rationale). Same specs reused across RED/GREEN/REFACTOR.

**5b: RED baseline (Phase B without skill)**

Launch N scenario subagents in parallel using the RED variant template. No skill content — establishes baseline failures.

**5c: Compile RED results (Phase C)**

Collect results, document baseline rationalizations and violations per scenario.

**5d: GREEN verification (Phase B with skill)**

Launch same N scenarios in parallel using the GREEN variant template. Inline skill content created in Step 3.

**5e: Compile GREEN results (Phase C)**

Compare GREEN against RED baseline. Each scenario should show improvement (PASS or WEAK vs prior FAIL).

**5f: REFACTOR if needed**

If new rationalizations found: update skill, re-run Phase B (GREEN only). Continue until no new rationalizations emerge.

### Step 6: Trigger Optimization

After TDD passes, validate that the skill's description triggers correctly:

1. Generate 5-8 trigger/no-trigger queries targeting the new skill
   - Should-trigger: realistic prompts a user would type that need this skill
   - Should-NOT-trigger: near-miss prompts that share keywords but need a different skill (or no skill)
   - Focus on edge cases and overlaps with existing skills
   - If skill has a negative trigger ("Do NOT use for..."): include at least 2 should-NOT-trigger queries for the excluded case
2. Test description against queries (see Trigger Testing in references/tdd-for-skills.md)
3. If trigger accuracy is poor: iterate description and retest (max 3 rounds)
4. Record results for the completion report

### Step 7: Completion Report (Main)

Present a single summary covering all phases:
- Files created and their purposes
- TDD results: scenarios run, outcomes (PASS/WEAK/FAIL), rationalizations found
- Trigger validation results: queries tested, pass/fail
- Structural audit results: issues found and auto-fixed
- Any remaining issues requiring user attention

## Validation

Read references/validation-gates.md. Run all applicable gates:
1. **Structural Audit** — launch `audit-skill-auditor` subagent (prompt template in validation-gates.md)
2. **Token Efficiency Gate** — run checklist against new skill. Watch for first-draft waste: filler phrases, restating the obvious, duplicate instructions across SKILL.md and workflows.
3. **Subagent Input Compliance** — if skill spawns subagents, verify prompts follow the I/O contract

Present audit results. Offer to fix any issues found.

## Rollback

If skill proves fundamentally flawed post-validation: use workflows/delete-skill.md for clean teardown (checks dependents, removes cross-references).
