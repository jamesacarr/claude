---
name: plan
description: "Creates implementation plans through a plan-critique-revise loop using the planner agent. Use after /jc:research. Do NOT use for research (use /jc:research) or execution (use /jc:implement)."
---

## Essential Principles

1. **Codebase map = hard gate.** The planner agent does NOT explore the codebase itself — it reads the codebase map. Without the map, plans lack convention awareness, correct file paths, and architectural alignment. Stop and direct user to `/jc:map`. No exceptions.
2. **Research = hard gate.** Plans without research are guesswork. Stop and direct user to `/jc:research`. No exceptions.
3. **Critique loop is mandatory.** Every plan gets adversarial critique by a second planner invocation. The orchestrator reading the plan is NOT a substitute — it lacks the planner's codebase map cross-referencing and research gap detection. Never skip critique.
4. **Max 1 revision round.** Plan → Critique → (if objections) Revise → Re-critique → done. 4 planner invocations worst case.
5. **Agents write directly.** Planner agents write files themselves. Do NOT relay content through the skill.

## Quick Start

1. Resolve task-id (reuse from `/jc:research`, or detect from `.planning/`)
2. Check codebase map gate (missing = stop, stale = prompt)
3. Check research gate (missing = stop)
4. Check for existing plan (completed tasks → replace or replan?)
5. Run plan-critique loop
6. Present plan summary to user
7. Suggest `/jc:implement`

## Process

### Step 1: Resolve Task-ID

If user provided a task-id, use it. Otherwise, detect from existing `.planning/` directories:

```bash
ls -d .planning/*/ 2>/dev/null | grep -v codebase
```

If exactly one task directory exists, use that task-id. If multiple exist, present them via AskUserQuestion for the user to choose. If none exist, prompt the user to run `/jc:research` first.

**Format rule:** Task-IDs must contain only lowercase alphanumeric characters, hyphens, and underscores.

### Step 2: Codebase Map Gate

**3-tier check:**

| Check | Condition | Action |
|-------|-----------|--------|
| **Missing** | `.planning/codebase/` does not exist or has no files | **Hard gate.** Stop. Tell user to run `/jc:map` first |
| **Stale** | >50 source commits since last map (heuristic for significant drift) | **Soft prompt.** AskUserQuestion: "regenerate map?" or "proceed with current map" |
| **Recent** | ≤50 source commits since last map | Proceed |

Staleness check — run as two separate Bash tool calls (no variable interpolation):

1. Get the commit that last modified the codebase map:
```bash
git log -1 --format=%H -- .planning/codebase/
```

2. If step 1 returned a commit hash, count source commits since then (paste the hash literally):
```bash
git log --oneline <paste-hash-here>..HEAD -- . ':!.planning/' | wc -l
```

If step 1 returned empty (map exists but not committed), treat as stale.

### Step 3: Research Gate

Check if research exists for this task:

```bash
ls .planning/{task-id}/research/*.md 2>/dev/null
```

If no research files exist: **hard gate.** Stop. Tell user to run `/jc:research {task-id}` first.

### Step 4: Existing Plan Check

Check if `.planning/{task-id}/plans/PLAN.md` exists:

```bash
ls .planning/{task-id}/plans/PLAN.md 2>/dev/null
```

If it exists, read it and check for tasks with status `passed`. If any completed tasks exist, use AskUserQuestion:
- **Replace** — discard existing plan, create fresh
- **Replan** — preserve completed tasks, replan remaining work

If no completed tasks, proceed with fresh plan (overwrite).

### Step 5: Plan-Critique Loop

Get the absolute project root via `pwd`. All planner invocations use `subagent_type: "team-planner"`.

Prompt template following the I/O contract in `plugins/jc/docs/agent-io-contract.md`:

```
## Task
{action} for the given task.

## Context
- Task ID: {task-id}
- Project root: {absolute_project_root}
- Planning directory: {absolute_project_root}/.planning
- Mode: {mode}

## Input
- Task description: {task_description}
- Research directory: {absolute_project_root}/.planning/{task-id}/research/
- Codebase map directory: {absolute_project_root}/.planning/codebase/
- Plan file: {absolute_project_root}/.planning/{task-id}/plans/PLAN.md
- Critique file: {absolute_project_root}/.planning/{task-id}/plans/CRITIQUE.md

## Expected Output
- Write {output_file} to {absolute_project_root}/.planning/{task-id}/plans/
- Return short confirmation or structured result
```

**Mode-to-action mapping:**

| Mode | `{action}` | `{output_file}` |
|------|-----------|-----------------|
| `plan` | Create an implementation plan | `PLAN.md` |
| `critique` | Adversarially critique the plan | `CRITIQUE.md` |
| `revise` | Revise the plan to address critique objections | `PLAN.md` |
| `replan` | Replan remaining work preserving completed tasks | `PLAN.md` |

For `replan` mode, `{task_description}` is taken from the existing PLAN.md's `## Goal` section.

**Loop execution:**

| Step | Mode | Action | Output |
|------|------|--------|--------|
| 5a | `plan` (or `replan`) | Create plan from research + codebase map | `PLAN.md` |
| 5b | `critique` | Adversarially review the plan | `CRITIQUE.md` + PASS/OBJECTIONS |
| 5c (if objections) | `revise` | Address critique objections | Revised `PLAN.md` |
| 5d (if revised) | `critique` | Re-review revised plan | Updated `CRITIQUE.md` + PASS/OBJECTIONS |

Steps 5a and 5b are **always** executed. Steps 5c and 5d execute only if 5b returns OBJECTIONS. After 5d, regardless of result, proceed to Step 6.

Each planner invocation is a **separate** Task tool call (sequential, not parallel — each depends on the previous output).

**Result parsing:** Read the `## Result` line of the critique agent's stdout response. If it contains `PASS`, no objections. If `OBJECTIONS`, proceed to revision. If `ERROR` or unparseable, surface the agent's `## Summary` and `## Details` to the user, stop the loop, and suggest remediation.

**Research gate note:** The gate checks file presence only. Thin or partial research will surface as critique objections — the gate does not assess research quality.

### Step 6: Report

Read `.planning/{task-id}/plans/PLAN.md` and present a summary to the user:
- **Goal** from the plan
- **Success criteria** count
- **Wave count** and **task count**
- **Critique status:** "Plan approved (no objections)", "Plan revised (objections addressed)", or "Plan has unresolved objections" with the objection list
- Path to `PLAN.md`
- Suggest running `/jc:implement {task-id}` as the next step

Do NOT commit the plan — `/jc:implement` handles committing `.planning/` docs before creating the worktree.

## Anti-Patterns

| Excuse | Reality |
|--------|---------|
| "The planner can read the codebase directly" | The planner reads the codebase map, not raw source files. Without the map, it produces plans with wrong file paths, missed conventions, and broken verification commands |
| "Critique is overkill for a small plan" | Small plans still have wrong test runners, missed conventions, and file overlap. Critique catches these systematically. Cost: one extra planner invocation. Cost of skipping: executor failures at runtime |
| "I can review the plan myself instead of critique" | You lack the planner's codebase map cross-referencing. You will miss convention violations and research gaps that the critique mode specifically checks |

## Success Criteria

- Codebase map gate enforced: missing = hard stop, stale = user prompted
- Research gate enforced: missing = hard stop
- Existing plan with completed tasks triggers replace/replan choice
- Critique loop always runs (steps 5a + 5b minimum)
- Max 1 revision round (steps 5c + 5d if needed)
- Plan summary presented to user with critique status
- User informed of next step (`/jc:implement`)

## References

- Agent definition: `plugins/jc/agents/team-planner.md`
- Plan schema: `plugins/jc/docs/plan-schema.md`
- I/O contract: `plugins/jc/docs/agent-io-contract.md`
