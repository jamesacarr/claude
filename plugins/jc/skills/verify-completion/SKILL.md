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

## Process

### Step 1: List Criteria

Extract every success criterion from the plan task. Include NFR criteria if present. If no explicit criteria exist, return UNVERIFIED with "no criteria defined" and escalate.

### Step 2: Gather Evidence

For each criterion, run the appropriate verification:

| Evidence Type | When to Use | What to Capture |
|--------------|-------------|-----------------|
| Test output | Criterion has corresponding tests | Command run + pass/fail output |
| Command output | Criterion is about system behavior | Command run + observed result |
| File verification | Criterion is about file existence/content | Path check + content match |
| Manual check | Criterion requires runtime observation | Steps taken + observed behavior |

Reading code is permitted to evaluate whether a test actually asserts the claimed behavior — it is not permitted as a substitute for running that test.

On re-verification (after a fix): re-run all evidence, not just previously failed criteria. Fixes can introduce regressions.

### Step 3: Classify Each Criterion

| Status | Meaning |
|--------|---------|
| VERIFIED | Evidence proves the criterion is met |
| PARTIALLY VERIFIED | Some aspects proven, others lack evidence. Document what's proven and what's not |
| UNVERIFIED | Cannot gather evidence with available tools. Document why |
| FAILED | Evidence shows the criterion is NOT met |

### Step 4: Write Report

Report each criterion in this format:

| Criterion | Status | Evidence | Notes |
|-----------|--------|----------|-------|
| Description from plan | VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / FAILED | What was run, what was observed | Gaps, caveats, recommendations |

**FAILED:** Return to Executor with which criteria failed, what evidence was gathered, what was expected vs. observed.

**UNVERIFIED:** Include in report with reason and recommendation. The caller decides whether to accept the risk or address the gap.

## Anti-Patterns

- **Trust-based verification:** "The Executor is reliable, so I'll take their word" — verify it yourself
- **Code-review-as-evidence:** Reading implementation and concluding it works is not running it
- **Silent skip:** Omitting a hard-to-verify criterion rather than flagging it as UNVERIFIED
- **Test-as-proof mismatch:** A passing test that doesn't assert the claimed behavior is not evidence for that criterion

## Success Criteria

- [ ] Every success criterion from the plan has an entry in the report
- [ ] Every VERIFIED criterion has concrete evidence (command output, test results)
- [ ] No criterion is claimed VERIFIED based solely on code review
- [ ] Unverifiable criteria are flagged as UNVERIFIED with reason
- [ ] Tests were run by the verifier, not trusted from Executor claims
