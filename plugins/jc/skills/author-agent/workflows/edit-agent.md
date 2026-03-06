# Edit Existing Agent

> Modify an existing agent's prompt, configuration, or structure with before/after behavioral verification, delegating heavy work to subagents.

## Goal

Apply targeted changes to an existing agent while maintaining or improving its behavioral effectiveness. Main context handles identification and decisions. Subagents handle testing, editing, and auditing.

## Prerequisites

Read `references/writing-agent-prompts.md` for prompt structure conventions.

## Steps

### Step 1: Read Current Agent (Main)

Read the agent's `.md` file. Understand:
- Current structure (YAML config, Markdown headings used)
- Role and focus areas
- Tool access and model selection
- Execution capabilities (subagent, team, dual-purpose)
- Any existing constraints

`{agents-dir}` was resolved during path resolution — see SKILL.md.

### Step 2: Backup (if risky edit)

For high-risk prompt changes, preserve the ability to rollback:
1. Copy current file to `{name}-backup.md`
2. Skip this for trivial edits (typos, adding a constraint, YAML-only changes)

### Step 3: Identify Changes (Main)

Clarify what needs to change:
- **Bug fix**: Agent doesn't behave as intended?
- **Enhancement**: Add new capability or focus area?
- **Structural upgrade**: Convert XML tags to Markdown headings, add missing sections?
- **Bulletproofing**: Agent breaks rules or produces poor output?
- **Capability change**: Adding/removing team member or subagent capability?
- **YAML-only change**: Just updating tools list, model, or description? → Skip to Step 5, edit YAML frontmatter directly, then skip to Step 7.

### Step 4: Delegate Before-Test (Subagent)

Follow `references/testing-agents.md` for invocation pattern and scenario design.

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Run behavioral test on the agent's current prompt to establish baseline behavior.

    ## Context
    - Agent file: {agents-dir}/{name}.md
    - Change being made: {description of planned change}
    - Reference files: {skill-base-dir}/references/
      (read testing-agents.md)

    ## Input
    - Agent prompt: {full content of the .md file}
    - Scenario targeting the specific behavior being modified

    ## Expected Output
    - Current behavior documented
    - What it does well, what it gets wrong
    - PASS/WEAK/FAIL assessment
```

### Step 5: Delegate Edit + After-Test (Subagent)

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Apply the specified change to the agent file, then verify the change
    improves behavior by running the same test scenario.

    ## Context
    - Agent file: {agents-dir}/{name}.md
    - Change type: {bug fix|enhancement|structural|bulletproofing|capability change}
    - Before-test results: {results from step 4}
    - Reference files: {skill-base-dir}/references/
      (read writing-agent-prompts.md, execution-models.md)

    ## Input
    - Current agent content: {full content}
    - Specific change requested: {description}
    - For capability changes: new execution model details

    ## Expected Output
    - Updated agent file written to {agents-dir}/{name}.md
    - After-test results (same scenario as before-test)
    - Comparison: before vs after behavior
    - PASS/WEAK/FAIL assessment
```

If behavioral fix and edit type is not YAML-only:
- Add/strengthen constraints with strong modal verbs (MUST, NEVER, ALWAYS)
- Clarify workflow steps that are being skipped
- Add `## Output Format` if outputs are inconsistent

If capability change (adding team support):
- Add `## Team Behavior` section
- Add coordination tools to tools list
- Add shutdown handling

### Step 6: Present Results (Main)

Review the subagent's output. Present to user:
- What changed (diff summary)
- Before vs after behavior comparison
- Ask: "Satisfied with the change, or should I iterate?"

If still failing: iterate on the prompt and re-test.

### Step 7: Delegate Audit (Subagent)

Read `references/validation-gates.md`. Run applicable gates:

```
Task tool parameters:
  subagent_type: "jc:audit-agent-auditor"
  prompt: |
    ## Task
    Audit the agent for structural correctness after edit.

    ## Context
    - Prior work: Agent edit — {change type}
    - Key findings: {any issues from testing}
    - Constraints: Focus on areas affected by edit

    ## Input
    Agent file: {agents-dir}/{name}.md
    Reference files: {skill-base-dir}/references/

    ## Expected Output
    Per your standard output format.
```

Also run **Description Freshness** gate if capabilities changed.

Fix any critical issues introduced by the edit before considering it complete.

## Validation

All applicable gates from `references/validation-gates.md` must pass:
- Structural Audit — no new critical issues
- Execution Model Compliance — if capabilities changed
- Behavioral test from Step 4 now passes or improves
- No regressions in previously passing scenarios

## Rollback

Restore from backup if created in Step 2, or `git checkout -- {agents-dir}/{name}.md`.
