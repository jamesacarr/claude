# Audit Output Format

> Unified report format merging structural audit (audit-skill-auditor subagent) with behavioral verification. Present as one report.

```
## Audit Report: {skill-name}

### Assessment
[1-2 sentence verdict covering both structural and behavioral results.]

### Critical Issues
Findings rated Critical or High:

1. **[Title]** ({S|B}) — file:line — {Critical|High}
   - Current: [what exists]
   - Should be: [what's correct]
   - Why: [impact on skill effectiveness]
   - Fix: [specific action]

### Recommendations

| # | Title | Sev | Src | Location | Current | Recommendation | Benefit |
|---|-------|-----|----------|-----|---------|----------------|---------|
| 1 | [title] | Med/Low | S/B | file:line | [what exists] | [what to change] | [improvement] |

### Gaps

| # | Scenario | Category | Location | Impact | Suggestion | Confirmed |
|---|----------|----------|----------|--------|-----------|------------|
| 1 | [concrete example] | [type] | file:line or "missing" | [what goes wrong] | [how to address] | Yes/No/Untested |

Confirmed: Yes = behavioral test failed. No = mitigated. Untested = no scenario run.

### Behavioral Verification

| # | Scenario | Type | Result | Notes |
|---|----------|------|--------|-------|
| 1 | [description] | [discipline/retrieval/gap] | PASS/WEAK/FAIL | [brief] |

Result: PASS = complies citing skill. WEAK = complies without citing. FAIL = violates.

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

Source tags: **(S)** = Structural (from audit-skill-auditor). **(B)** = Behavioral (from TDD verification). Omit empty sections except Gaps and Behavioral Verification (always required).
