# Create New Agent

> Create a new agent from requirements to validated file, with heavy work delegated to subagents.

## Goal

Produce a working agent `.md` file at `{agents-dir}/{name}.md` that passes structural audit and behavioral testing. Main context handles intake, decisions, and presenting results. Subagents handle content generation, testing, and auditing.

## Prerequisites

Read `references/agents.md`, `references/writing-agent-prompts.md`, and `references/execution-models.md` before starting.

## Steps

### Step 1: Gather Requirements (Main)

**If user provided context** (e.g., "create an agent for code review"):
- Analyze what's stated, what can be inferred, what's unclear
- Skip to asking about genuine gaps only

**If no context provided**, ask using AskUserQuestion:
- "What specific task should this agent handle?"
- "Should it modify code or only analyze/report?"

`{agents-dir}` was resolved during path resolution — see SKILL.md.

### Step 2: Decide Execution Capabilities (Main)

Ask using AskUserQuestion:
- "How will this agent be used?"
  - **Subagent** — spawned one-shot by a skill or orchestrator, returns result
  - **Team member** — persistent agent coordinating with teammates via messaging
  - **Both** — dual-purpose, works standalone or in teams

See `references/execution-models.md` for decision framework.

### Step 3: Decide Complexity (Main)

| Complexity | Sections Needed | Examples |
|------------|----------------|----------|
| **Simple** (single task) | Role + Constraints + Workflow | code-reviewer, test-runner, syntax-checker |
| **Medium** (multi-step) | + Output Format + Success Criteria | api-researcher, documentation-generator |
| **Complex** (research + gen + validation) | + Validation + Examples | comprehensive-auditor, mcp-researcher |

For team members, always at least **Medium** — they need `## Team Behavior` and coordination instructions.

### Step 4: Delegate Content Generation (Subagent)

Launch a subagent to write the agent file:

**WARNING:** Use `subagent_type` only — do NOT add a `name:` parameter to the Task tool call (that creates a persistent team member instead of a one-shot subagent).

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Create an agent .md file following the specified structure, execution capabilities,
    and complexity level.

    ## Context
    - Execution capabilities: {subagent|team|both}
    - Complexity: {simple|medium|complex}
    - Template: {simple-agent-template|full-agent-template|team-agent-template}
    - Requirements: {summary from step 1}
    - Agents directory: {agents-dir}
    - Reference files: {skill-base-dir}/references/
      (read agents.md, writing-agent-prompts.md, execution-models.md)

    ## Input
    - Agent name: {name}
    - Task description: {what the agent does}
    - Tools needed: {list of tools}
    - Model: {sonnet|haiku|opus}
    - For team agents: coordination responsibilities, message types handled

    ## Expected Output
    Write agent file to {agents-dir}/{name}.md. Return:
    - File path and line count
    - Summary of agent capabilities
    - Execution capabilities configured
    - Any decisions made during content generation
```

**Pre-flight check:** Before writing, verify no agent with this name already exists:
```bash
ls {agents-dir}/{name}.md
```
If the file exists, warn the user and ask: "Overwrite, cancel, or choose a different name?"

Create directory first if needed:
```bash
mkdir -p {agents-dir}
```

### Step 5: Present & Confirm (Main)

Review the subagent's output. Present to user:
- Agent file created and its capabilities
- Execution capabilities configured
- Key decisions the subagent made
- Ask: "Does this look right, or should I adjust anything before testing?"

### Step 6: Behavioral Testing (Main orchestrates DEC)

Follow `references/testing-agents.md` DEC pattern. Main context orchestrates all phases (see `references/execution-models.md` for spawning constraints).

**6a: Design scenarios (Phase A)**

Launch 1 subagent to design scenarios based on agent role and execution capabilities. For team agents: include task claiming and shutdown scenarios. For dual-purpose: include both modes. Returns numbered scenario specs.

**6b: RED baseline (Phase B without agent prompt)**

Launch N scenario subagents in parallel using the RED variant template from testing-agents.md. No agent prompt — establishes baseline.

**6c: GREEN verification (Phase B with agent prompt)**

Launch same N scenarios in parallel using the GREEN variant template. Inline the full agent prompt content.

**6d: Compile results (Phase C)**

Evaluate per testing-agents.md criteria. If FAIL results: iterate on prompt, re-run Phase B (GREEN only).

### Step 7: Present Test Results (Main)

Review test results. Present to user:
- Scenarios run and their outcomes (PASS/WEAK/FAIL)
- Any prompt improvements suggested
- Ask: "Ready to proceed to audit, or should I iterate on the prompt?"

If FAIL results: discuss with user, iterate on prompt, re-test.

### Step 8: Delegate Audit (Subagent)

Read `references/validation-gates.md`. Launch the auditor:

```
Task tool parameters:
  subagent_type: "jc:audit-agent-auditor"
  prompt: |
    ## Task
    Audit the agent for structural correctness, content quality, execution capability
    compliance, and coverage gaps.

    ## Context
    - Prior work: New agent creation — passed behavioral testing
    - Key findings: {any issues from testing phase}
    - Constraints: Full audit

    ## Input
    Agent file: {agents-dir}/{name}.md
    Reference files: {skill-base-dir}/references/

    ## Expected Output
    Per your standard output format.
```

### Step 9: Present Audit & Finalize (Main)

Review audit results. Present to user:
- Audit findings (critical, warning, info)
- Offer to fix any issues found
- Confirm agent is ready for use

## Validation

All gates from `references/validation-gates.md` must pass:
- YAML & Tool Validation — frontmatter parses, tool names valid
- Execution Model Compliance — capabilities match content
- Structural Audit — no critical issues
- At least one behavioral test passes (Step 6)
- For team agents: Team Agent Gates pass

## Rollback

If the file is tracked by git: `git checkout -- {agents-dir}/{name}.md`
If newly created (untracked): `rm {agents-dir}/{name}.md`
