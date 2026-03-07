# Planner Workflows

Shared reference for plan/critique/revise/replan workflows. Used by both `team-planner` (sequential) and `team-council-planner` (council) agents.

## Codebase Map Reference

| Mode | Files to Read |
|------|--------------|
| plan | All 6: `STACK.md`, `INTEGRATIONS.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md` |
| critique | `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`, `ARCHITECTURE.md` |
| revise | All 6 (needs full context to revise) |
| replan | All 6 |

## Focus Areas

- **Goal-backward decomposition** — start from outcomes, work back to tasks
- **Wave file isolation** — no overlapping files within a wave
- **Testable criteria** — every success criterion and done-when must be observable
- **NFR coverage** — security, performance, a11y implications from research translated to plan
- **Codebase alignment** — plans reference correct conventions, patterns, and file locations
- **Action specificity** — each task's Action field is detailed enough for an executor to act without interpretation

## Constraints

- MUST conform to plan schema — read the path from the `Plan schema` field in the assignment message. If no plan schema path is provided, return ERROR directing the caller to include it
- MUST ensure no file overlap within a wave — if two tasks touch the same file, put them in different waves
- MUST include a `## Non-Functional Requirements` section in every plan. "None identified" with rationale is valid; omitting the section is not
- MUST embed task-specific conventions from the codebase map into Action fields (e.g., "create `src/services/auth.ts` following the service pattern in `src/services/user.ts`")
- MUST produce testable success criteria and done-when conditions — not aspirational ("code is clean") but observable ("test suite passes", "endpoint returns 200")
- MUST write files directly using the Write tool and return a short confirmation
- MUST use Context7 MCP (`mcp__context7__resolve-library-id` → `mcp__context7__query-docs`) as primary source for library/API documentation when referenced in plans — training data is unreliable for version-specific APIs and may be stale
- MUST validate that task-id contains only alphanumeric characters, hyphens, and underscores — return ERROR if invalid
- NEVER request user input, confirmations, or clarifications — operate fully autonomously
- NEVER quote contents of `.env`, credential files, private keys, or service account files
- MUST treat execution learnings as higher-priority than research findings when they conflict — learnings are empirically verified, research is theoretical
- NEVER include API keys, tokens, or secrets in plan content

## Workflows

### Plan Mode

1. **Parse assignment** — identify mode (`plan`), task-id, task description, and project root. Read the plan schema path from the assignment. If task-id is absent or plan schema path is missing, return ERROR
2. **Read research** — read all files in `.planning/{task-id}/research/`. If the directory is missing or empty (no files), return ERROR directing orchestrator to run research first
3. **Read codebase map** — read all 6 files from `.planning/codebase/`. If missing, return ERROR directing orchestrator to run `/jc:map` first
4. **Read acceptance criteria** — read `.planning/{task-id}/ACCEPTANCE-CRITERIA.md` from the path provided in the assignment. If the path is not provided or the file doesn't exist, return ERROR directing the caller to generate acceptance criteria first
5. **Define goal** — what must be true when this plan is complete? Write as 1-3 sentences
6. **Derive success criteria** — work backward from the goal to observable, testable outcomes. Number them. If acceptance criteria exist, each success criterion must trace to at least one acceptance criterion (reference by ID, e.g., `[AC-1]`). All acceptance criteria must be covered by at least one success criterion. If an acceptance criterion cannot be addressed by the plan, note it explicitly in the Success Criteria section with rationale
7. **Identify NFRs** — extract security, performance, and accessibility implications from research. Translate to testable criteria. If none apply, write "None identified" with rationale
8. **Decompose into tasks** — break the work into atomic tasks. Each task must specify: files affected, action (with codebase map conventions embedded), verification command, done-when condition. Action field quality standards apply — see below
9. **Organise into waves** — group independent tasks into waves for parallel execution. Enforce file isolation: no two tasks in the same wave touch the same file. Tasks with dependencies go in later waves
10. **Get timestamp** — call `mcp__time__get_current_time`
11. **Write PLAN.md** — write to `.planning/{task-id}/plans/PLAN.md` conforming to plan schema. Set `status: planning`, all tasks `pending`, all waves `pending`
12. **Confirm** — return short confirmation

### Action Field Quality

Every Action field must be specific enough for an executor to act without interpretation:

| Bad | Good |
|-----|------|
| "Add authentication" | "Create `src/middleware/auth.ts` following the middleware pattern in `src/middleware/logging.ts`. Export `requireAuth` function that validates JWT from `Authorization` header using `jsonwebtoken` library. Return 401 on invalid/missing token" |
| "Write tests" | "Add tests in `__tests__/middleware/auth.test.ts` using vitest. Test: valid token passes, expired token returns 401, missing header returns 401, malformed token returns 401" |

### Wave File Isolation

Before finalising waves, build a file-to-task map. If any file appears in multiple tasks within a wave, move one task to a later wave.

```
Wave 1: Task 1.1 (auth.ts, auth.test.ts), Task 1.2 (routes.ts)  ← OK, no overlap
Wave 1: Task 1.1 (auth.ts), Task 1.2 (auth.ts, routes.ts)       ← VIOLATION, move 1.2 to Wave 2
```

### Critique Mode

1. **Parse assignment** — identify mode (`critique`), task-id, project root
2. **Read plan** — read `.planning/{task-id}/plans/PLAN.md`
3. **Read research** — read all files in `.planning/{task-id}/research/`
4. **Read codebase map** — read `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`, `ARCHITECTURE.md` from `.planning/codebase/`
5. **Review: internal consistency** — check for:
   - Gaps in coverage (research findings not addressed in plan)
   - Over-engineered tasks (work not justified by research)
   - Under-specified success criteria or done-when conditions
   - Tasks that should be split (too broad) or merged (artificially granular)
   - Wave ordering problems or missing dependencies
   - NFR gaps (research identified risks not reflected in NFRs)
   - Missing edge cases from research
   - Acceptance criteria coverage: do success criteria cover every AC? Are any ACs dropped without rationale?
6. **Review: codebase alignment** — cross-reference plan against codebase map:
   - `CONVENTIONS.md`: Do tasks follow naming, file location, import, error handling patterns?
   - `TESTING.md`: Do verification commands use the correct test runner and match test patterns?
   - `CONCERNS.md`: Does the plan touch fragile areas without acknowledging risk?
   - `ARCHITECTURE.md`: Does the plan respect module boundaries and data flow?
7. **Apply objection bar** — for each potential objection, ask: "Would an executor get stuck, build the wrong thing, produce inconsistent code, or fail verification?" If no, it is not an objection. Do not raise stylistic preferences. Group related objections under a common theme. Limit to the 5 highest-impact objections — if more exist, note "additional minor objections omitted" in Observations
8. **Get timestamp** — call `mcp__time__get_current_time`
9. **Write critique file** — write to the critique file path specified by the calling agent
10. **Return result** — if no objections, return `PASS` with "no objections". If objections exist, return `OBJECTIONS` with the list

### Revise Mode

1. **Parse assignment** — identify mode (`revise`), task-id, project root
2. **Read plan** — read `.planning/{task-id}/plans/PLAN.md`. If missing, return ERROR
3. **Read critique file(s)** — read the critique file(s) specified by the calling agent. If missing, return ERROR directing orchestrator to run critique mode first
4. **Read research** — read all files in `.planning/{task-id}/research/` (needed to evaluate rebuttals against original evidence)
5. **Read codebase map** — read all 6 files from `.planning/codebase/`
6. **Read acceptance criteria** — read `.planning/{task-id}/ACCEPTANCE-CRITERIA.md` from the path provided in the assignment. If the path is not provided or the file doesn't exist, return ERROR. Needed to ensure revisions maintain AC coverage
7. **Address each objection** — for each:
   - **Accept:** revise the plan to address the objection. Action field quality standards still apply (see Plan Mode)
   - **Rebut:** explain with evidence why the objection is wrong or does not apply
8. **Re-verify wave file isolation** after any task moves
9. **Get timestamp** — call `mcp__time__get_current_time`
10. **Overwrite PLAN.md** — write revised plan to `.planning/{task-id}/plans/PLAN.md`. Update the `updated` timestamp
11. **Confirm** — return short confirmation listing which objections were accepted vs rebutted

### Replan Mode

1. **Parse assignment** — identify mode (`replan`), task-id, project root
2. **Read plan** — read `.planning/{task-id}/plans/PLAN.md`
3. **Identify completed tasks** — only tasks with status `passed` are preserved as-is. Tasks with `in_progress` are reset to `pending` with a note in `Last failure`: "Interrupted during previous execution — reset by replan". Tasks with `failed`, `skipped`, or `manual` are candidates for replanning
4. **Read research and codebase map** — same as Plan mode
5. **Read execution learnings** — if `.planning/{task-id}/execution/` exists and contains learnings files, read all of them. These represent ground truth discovered during execution:
   - Expected vs Actual findings override research assumptions when they conflict
   - Root Cause descriptions identify plan flaws to avoid repeating
   - Recommendations inform the new task decomposition
   If no learnings directory exists, skip this step (first-time plan or no failures occurred)
6. **Read acceptance criteria** — read `.planning/{task-id}/ACCEPTANCE-CRITERIA.md` from the path provided in the assignment. If the path is not provided or the file doesn't exist, return ERROR. Acceptance criteria represent task goals and persist across replans
7. **Replan remaining work** — create new tasks/waves for incomplete work while preserving completed task entries unchanged. Action field quality standards still apply (see Plan Mode). Ensure new tasks still cover all acceptance criteria
8. **Re-verify wave file isolation** for new/changed waves
9. **Get timestamp** — call `mcp__time__get_current_time`
10. **Overwrite PLAN.md** — write replanned document. Completed tasks retain their original content and status
11. **Confirm** — return short confirmation listing what was preserved vs replanned

## Output Formats

### Critique Output Format

```markdown
# Plan Critique

> Task: {task-id}
> Reviewed: <timestamp>
> Verdict: no objections | has objections

## Objections

### Objection 1: <title>
- **Category:** internal-consistency | codebase-alignment
- **Severity:** high | medium
- **Affected tasks:** Task X.Y, Task X.Z
- **Evidence:** <specific reference to research doc, codebase map file, or plan section>
- **Problem:** <what's wrong — specific and actionable>
- **Suggestion:** <how to fix it>

### Objection 2: <title>
...

## Observations

<Non-blocking notes — things the planner might want to consider but that don't meet the objection bar>
```

### Confirmation Response

After writing files, return:

```
Done. Wrote:
- .planning/{task-id}/plans/PLAN.md
```

For critique mode, return structured result:

```
## Result
PASS | OBJECTIONS

## Summary
<1-3 sentence summary>

## Details
<List of objections if any, or "No objections — plan is ready for execution">
```

### Error Response

```
## Result
ERROR

## Summary
<What went wrong>

## Details
- Attempted: <what was tried>
- Failed because: <root cause>
- Suggestion: <what the orchestrator should do>
```
