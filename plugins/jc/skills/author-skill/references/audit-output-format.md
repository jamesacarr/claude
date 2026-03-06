# Audit Output Format

> Unified report format merging structural audit, wording review, and behavioral verification. Present as one report.

```
## Audit Report: {skill-name}

### Assessment
[1-2 sentence verdict covering structural, wording, and behavioral results.]

### Critical Issues
Findings rated Critical or High:

1. **[Title]** ({S|W|B}) — file:line — {Critical|High} — evidence: {verified|pattern-match|inference}
   - Current: [what exists]
   - Should be: [what's correct]
   - Why: [impact on skill effectiveness]
   - Fix: [specific action]

### Recommendations

| # | Title | Sev | Src | Evidence | Location | Current | Recommendation | Benefit |
|---|-------|-----|-----|----------|----------|---------|----------------|---------|
| 1 | [title] | Med/Low | S/W/B | verified/pattern-match/inference | file:line | [what exists] | [what to change] | [improvement] |

### Gaps

| # | Scenario | Category | Location | Impact | Suggestion | Confirmed |
|---|----------|----------|----------|--------|-----------|------------|
| 1 | [concrete example] | [type] | file:line or "missing" | [what goes wrong] | [how to address] | Yes/No/Untested |

Confirmed: Yes = behavioral test failed. No = mitigated. Untested = no scenario run.

### Behavioral Verification

| # | Scenario | Type | Result | Notes |
|---|----------|------|--------|-------|
| 1 | [description] | [discipline/retrieval/gap] | PASS/WEAK/FAIL | [brief] |
| 2 | "Create a new skill for X" | trigger | PASS | Correctly matched |
| 3 | "Create a new agent for X" | trigger-negative | PASS | Correctly excluded |

Result: PASS = complies citing skill. WEAK = complies without citing. FAIL = violates.

### Improvement Suggestions

| # | Priority | Category | Suggestion | Expected Impact |
|---|----------|----------|------------|-----------------|
| 1 | high | instructions | [specific change to make] | [what outcome this would change] |
| 2 | medium | error_handling | [specific change] | [expected improvement] |

Priority: **high** = would change audit outcomes. **medium** = improves quality but may not change pass/fail. **low** = marginal improvement.
Categories: `instructions`, `wording`, `structure`, `examples`, `error_handling`, `references`, `triggers`.

### Quick Fixes
1. [Issue] at file:line → [one-line fix]

### Strengths
- [Specific strength with file:line]

### Context
- Skill type: [simple / router]
- Lines: [SKILL.md] / [total all files]
- Scenarios run: [count]
- Effort to address issues: [low / medium / high]
```

Source tags: **(S)** = Structural (from audit-skill-auditor). **(W)** = Wording (from wording review). **(B)** = Behavioral (from TDD verification). Omit empty sections except Gaps and Behavioral Verification (always required).

Evidence tags: **verified** = checked against filesystem/frontmatter/tools. **pattern-match** = matches canonical anti-pattern. **inference** = reasoning without direct evidence. Findings tagged `inference` + `Low` severity are suppressed by default. Add `"N low-confidence findings suppressed. Re-run with --verbose to include."` at report bottom (omit if N=0).
