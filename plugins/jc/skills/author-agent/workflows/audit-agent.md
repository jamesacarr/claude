# Audit Agent

> Comprehensive structural and behavioral audit of a Claude Code agent with actionable findings, delegating audit phases to subagents.

## Goal

Produce a unified audit report combining structural validation (via audit-agent-auditor) with behavioral testing, identifying gaps and providing fix recommendations. Main context handles selection, presentation, and fix decisions. Subagents handle the actual auditing and testing.

## Prerequisites

Agent file must exist at `{agents-dir}/{name}.md`.

## Steps

### Step 1: Select Agent (Main)

If not already specified, list available agents:
```bash
ls {agents-dir} 2>/dev/null
```

`{agents-dir}` was resolved during path resolution — see SKILL.md.

Ask: "Which agent would you like to audit?"

### Step 2: Delegate Structural Audit (Subagent)

See also `references/validation-gates.md` for the standard structural audit gate.

```
Task tool parameters:
  subagent_type: "jc:audit-agent-auditor"
  prompt: |
    ## Task
    Audit the agent for structural correctness, content quality, execution capability
    compliance, and coverage gaps.

    ## Context
    - Prior work: {any prior audit results or known issues, or "Initial audit"}
    - Key findings: {anything discovered during selection, or "None yet"}
    - Constraints: {scope boundaries — e.g., "structural only" or "full audit"}

    ## Input
    Agent file: {agents-dir}/{name}.md
    Reference files: {skill-base-dir}/references/

    ## Expected Output
    Structured audit report with findings categorized by severity
    (Critical/High/Medium/Low), covering structural correctness, content quality,
    execution capability compliance, and coverage gaps.
```

Review the structural report before proceeding to Step 3.

**Batch mode:** To audit all agents, iterate over the resolved agents directory:
```bash
for f in {agents-dir}/*.md; do echo "--- $f ---"; done
```
Then run Steps 2-5 for each file. Summarize results in a single report.

### Step 3: Behavioral Test (Main orchestrates DEC)

Structural correctness does not guarantee behavioral effectiveness.

Follow `references/testing-agents.md` DEC pattern. Main context orchestrates all phases.

**3a: Design scenarios (Phase A)**

Launch 1 subagent to design scenarios targeting structural gaps from Step 2. Pass: agent prompt content, structural audit findings, agent role. Returns numbered scenario specs.

**3b: Execute GREEN scenarios (Phase B)**

Launch N scenario subagents in parallel using the GREEN variant template from testing-agents.md. Inline agent prompt content.

**Audit-specific note:** Skip RED phase — auditing an existing agent that's already in use. GREEN-only testing verifies current behavioral effectiveness.

**3c: Compile results (Phase C)**

Evaluate per testing-agents.md criteria. On FAIL, run meta-test to diagnose prompt weakness.

### Step 4: Coordination Test (Main orchestrates DEC, if applicable)

For agents with team member capability, test coordination behavior. Skip if subagent-only.

Follow `references/testing-agents.md` DEC pattern.

**4a: Design coordination scenarios (Phase A)**

Launch 1 subagent to design coordination-specific scenarios: task claiming, message handling, shutdown handling, peer discovery. For dual-purpose agents: include mode detection scenarios.

**4b: Execute coordination scenarios (Phase B)**

Launch N scenario subagents in parallel using the coordination variant template from testing-agents.md. Inline agent prompt + simulated team context.

**4c: Compile results (Phase C)**

Evaluate per-test PASS/FAIL for each coordination capability.

### Step 5: Offer Fixes (Main)

If issues found, ask: "Would you like me to fix these issues?"
1. **Fix all**
2. **Fix one by one**
3. **Just the report**

If fixing, use the `workflows/edit-agent.md` workflow.

If user chooses **report-only**: present the report, then add:
- For critical issues: "These will cause failures in production. Recommend addressing soon."
- Offer: "Would you like me to add TODO comments to the agent file marking the critical issues?"

## Output Format

Final report merges structural audit (audit-agent-auditor) with behavioral verification. Present as one unified report:

```
## Audit Report: {agent-name}

### Assessment
[1-2 sentence verdict covering both structural and behavioral results.]

### Critical Issues
Findings rated Critical or High:

1. **[Title]** ({S|B|C}) — file:line — {Critical|High}
   - Current: [what exists]
   - Should be: [what's correct]
   - Why: [impact on agent effectiveness]
   - Fix: [specific action]

### Recommendations

| # | Title | Sev | Src | Location | Current | Recommendation | Benefit |
|---|-------|-----|-----|----------|---------|----------------|---------|
| 1 | [title] | Med/Low | S/B/C | file:line | [what exists] | [what to change] | [improvement] |

### Gaps

| # | Scenario | Category | Location | Impact | Suggestion | Confirmed |
|---|----------|----------|----------|--------|-----------|-----------|
| 1 | [concrete example] | [type] | file:line or "missing" | [what goes wrong] | [how to address] | Yes/No/Untested |

Confirmed: Yes = behavioral test failed. No = mitigated. Untested = no scenario run.

### Behavioral Verification

| # | Scenario | Type | Result | Notes |
|---|----------|------|--------|-------|
| 1 | [description] | [role/gap] | PASS/WEAK/FAIL | [brief] |

Result: PASS = complies citing prompt. WEAK = complies without citing. FAIL = violates.

### Coordination Verification (if applicable)

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1 | Task claiming | PASS/FAIL | [brief] |
| 2 | Message handling | PASS/FAIL | [brief] |
| 3 | Shutdown handling | PASS/FAIL | [brief] |

### Quick Fixes
1. [Issue] at file:line → [one-line fix]

### Strengths
- [Specific strength with file:line]

### Context
- Agent type: [analysis-only / code-modifying / orchestrator / team-member]
- Execution capabilities: [subagent / team / dual-purpose]
- Tool access: [tools listed or "full access"]
- Model: [model specified or "default"]
- Lines: [total]
- Scenarios run: [count]
- Effort to address issues: [low / medium / high]
```

Source tags: **(S)** = Structural (from audit-agent-auditor). **(B)** = Behavioral (from test scenarios). **(C)** = Coordination (from team tests). Omit empty sections except Gaps and Behavioral Verification (always required).

## Validation

- Structural audit completed (audit-agent-auditor ran)
- At least 2 behavioral scenarios executed
- Coordination tests executed (if agent has team capability)
- Unified report produced with all required sections
- Each finding has source tag (S, B, or C)

## Rollback

Audit is read-only — no rollback needed. If fixes were applied via Step 5, rollback per `edit-agent.md`.
