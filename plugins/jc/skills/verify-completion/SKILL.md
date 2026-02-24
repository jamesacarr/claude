---
name: verify-completion
description: Enforces evidence-based completion verification before success claims. Use when verifying that completed work meets its success criteria. Do NOT use for code quality review (use Reviewer agent).
---

## Essential Principles

Every completion claim requires evidence. No exceptions.

1. **Evidence over confidence.** "Tests pass" means you ran them and have the output. "Feature works" means you demonstrated it. Code review is not verification — it's a different confidence level.
2. **Verify every criterion.** Each success criterion gets its own evidence entry. No silent skips.
3. **Flag what you can't verify.** If a criterion cannot be verified with available tools, report it as UNVERIFIED with the reason. Do not claim verified based on code review alone.
4. **Partial verification is honest.** Report exactly what was proven and by what means. PARTIALLY VERIFIED with an explanation is better than a false VERIFIED.
5. **Run it yourself.** Never accept another agent's claim that "tests pass" without running them yourself.

## Quick Start

Invoke with `/jc:verify-completion`. Provide or reference a plan/task with explicit success criteria. The skill extracts criteria, delegates evidence collection to a subagent, and presents a summary table.

## Process

### Step 1: List Criteria

Extract every success criterion from the plan task or user request. Include NFR criteria if present. If no explicit criteria exist, return UNVERIFIED with "no criteria defined" and escalate.

### Step 2: Delegate Evidence Collection

Spawn a `general-purpose` agent via the Task tool. The agent does ALL evidence gathering — tests, commands, file checks — and returns a structured summary. Main context never sees raw output.

Agent prompt must include:

1. **The criteria list** from Step 1
2. **Full methodology inline** (do NOT reference this skill — the agent carries its own instructions):
   - Evidence over confidence: "tests pass" means run them, "feature works" means demonstrate it. Code review is not verification.
   - Verify every criterion. Each gets its own evidence entry. No silent skips.
   - Flag what you can't verify as UNVERIFIED with reason. Never claim VERIFIED from code review alone.
   - Run it yourself. Never trust another agent's claim without running the check.
   - Evidence types: test output (run tests, capture pass/fail), command output (run commands, capture result), file verification (check path + content), manual check (steps + observed behavior).
   - Reading code is permitted to evaluate whether a test asserts the claimed behavior — not as a substitute for running it.
   - On re-verification: re-run ALL evidence, not just previously failed criteria.
3. **Return format:**

```
## Result
PASS | PARTIAL | FAIL

## Summary
{n}/{total} criteria verified

## Criteria
| Criterion | Status | Evidence |
|-----------|--------|----------|
| {text} | VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / FAILED | {1-line evidence} |
```

Classification rules for the agent: VERIFIED = evidence proves criterion met. PARTIALLY VERIFIED = some aspects proven, others lack evidence. UNVERIFIED = cannot gather evidence with available tools. FAILED = evidence shows criterion NOT met.

### Step 3: Present Results

Present the agent's summary table to the user as-is. Do not add raw test output or command output — the table's Evidence column is sufficient.

**FAILED:** Report which criteria failed using the table. The Evidence column shows what was expected vs observed.

**UNVERIFIED:** Include in report with reason. The caller decides whether to accept the risk.

## Anti-Patterns

- **Silent skip:** Omitting a hard-to-verify criterion rather than flagging it as UNVERIFIED
- **Test-as-proof mismatch:** A passing test that doesn't assert the claimed behavior is not evidence for that criterion

## Success Criteria

- [ ] Every success criterion from the plan has an entry in the report
- [ ] Every VERIFIED criterion has concrete evidence (command output, test results)
- [ ] No criterion is claimed VERIFIED based solely on code review
- [ ] Unverifiable criteria are flagged as UNVERIFIED with reason
- [ ] Tests were run by the delegated agent, not trusted from Executor claims
