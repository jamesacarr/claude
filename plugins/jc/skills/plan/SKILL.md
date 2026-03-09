---
name: plan
description: "Creates implementation plans through a plan-critique-revise loop using the planner agent. Use after /jc:research. Do NOT use for research (use /jc:research) or execution (use /jc:implement)."
---

# Plan

## Essential Principles

1. **Codebase map = hard gate.** The planner reads the codebase map, not raw source files — without it, plans lack convention awareness, correct file paths, and architectural alignment. Stop and direct user to `/jc:map`. No exceptions.
2. **Research = hard gate.** Plans without research are guesswork. Stop and direct user to `/jc:research`. No exceptions.
3. **Acceptance criteria = hard gate.** Generate ACCEPTANCE-CRITERIA.md before planning — planning without criteria undermines the verification chain. Acceptance criteria define what the plan must achieve; without them, success criteria are invented by the planner without traceability to requirements.
4. **Critique loop is mandatory.** The orchestrator lacks the planner's codebase map cross-referencing and research gap detection — every plan gets adversarial critique by a second planner invocation. Never skip critique.
5. **Max 2 revision rounds.** Plan → Critique → (if objections) Revise → Re-critique → (if still objections) Revise → Re-critique → done. Changes during revision can introduce new issues, so a second round catches cascading problems. 6 planner invocations worst case.
6. **Agents write directly.** Planner agents write files themselves — relaying content through the skill risks truncation, loses formatting, and bloats context.

## Quick Start

1. Resolve task-id (reuse from `/jc:research`, or detect from `.planning/`)
2. Check codebase map gate (missing = stop, stale = prompt)
3. Check research gate (missing = stop)
4. Generate acceptance criteria (or skip if already exists)
5. Check for existing plan (completed tasks → replace or replan?)
6. Run plan-critique loop
7. Present plan summary to user
8. Suggest `/jc:implement`

## Process

### Step 0: Resolve Paths

Resolve from the skill's base directory (the directory containing this SKILL.md):
- `{plugin-docs}` = `{skill-base-dir}/../../docs/`

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

**Research gate note:** The gate checks file presence only. Thin or partial research will surface as critique objections — the gate does not assess research quality.

### Step 4: Generate Acceptance Criteria

Check if `.planning/{task-id}/ACCEPTANCE-CRITERIA.md` already exists:

```bash
ls .planning/{task-id}/ACCEPTANCE-CRITERIA.md 2>/dev/null
```

If it exists, skip to Step 5 (resume case — criteria already generated).

If not, spawn a `team-criteria-generator` agent via the Task tool. `{task_description}` is the user's original planning request from the current conversation.

1. `TaskCreate` with:
   - subject: `criteria-{task-id}`
   - description: `Generate acceptance criteria for: {task_description}`
   - metadata: `{"task_id": "{task-id}", "task_description": "{task_description}", "research_dir": "{absolute_project_root}/.planning/{task-id}/research/", "codebase_map_dir": "{absolute_project_root}/.planning/codebase/", "acceptance_criteria_path": "{absolute_project_root}/.planning/{task-id}/ACCEPTANCE-CRITERIA.md", "external_doc_paths": "{external_doc_paths or null}"}`

2. Spawn agent with `subagent_type: "team-criteria-generator"`, prompt: `Your task is {task-id-from-TaskCreate}.`

After the agent completes, read results via `TaskGet` on the created task to confirm completion.

After the agent completes, verify the output file exists:

```bash
ls .planning/{task-id}/ACCEPTANCE-CRITERIA.md 2>/dev/null
```

If missing, retry the agent once. On second failure, report to user and stop. Suggest re-running `/jc:research {task-id}` to ensure research files are complete, then retrying `/jc:plan`.

### Step 5: Existing Plan Check

Check if `.planning/{task-id}/plans/PLAN.md` exists:

```bash
ls .planning/{task-id}/plans/PLAN.md 2>/dev/null
```

If it exists, read it and check for tasks with status `passed`. If any completed tasks exist, use AskUserQuestion:
- **Replace** — discard existing plan, create fresh
- **Replan** — preserve completed tasks, replan remaining work

If no completed tasks, proceed with fresh plan (overwrite).

### Step 6: Plan-Critique Loop

Get the absolute project root via `pwd`. All planner invocations use `subagent_type: "team-planner"`.

For each planner invocation, create a task via `TaskCreate` with metadata, then spawn the agent with only the task ID:

1. `TaskCreate` with:
   - subject: `planner-{mode}-{task-id}` (use a unique suffix if multiple invocations of the same mode, e.g., `planner-critique-{task-id}-2`)
   - description: `{action} for: {task_description}`
   - metadata: `{"mode": "{mode}", "task_id": "{task-id}", "planner_workflows_path": "{plugin-docs}/planner-workflows.md", "plan_schema_path": "{plugin-docs}/plan-schema.md", "acceptance_criteria_path": "{absolute_project_root}/.planning/{task-id}/ACCEPTANCE-CRITERIA.md", "research_dir": "{absolute_project_root}/.planning/{task-id}/research/", "codebase_map_dir": "{absolute_project_root}/.planning/codebase/"}`

2. Spawn agent with `subagent_type: "team-planner"`, prompt: `Your task is {task-id-from-TaskCreate}.`

After each agent completes, read results via `TaskGet` on the created task to confirm completion.

**Mode-to-action mapping:**

| Mode | `{action}` |
|------|-----------|
| `plan` | Create an implementation plan |
| `critique` | Adversarially critique the plan |
| `revise` | Revise the plan to address critique objections |
| `replan` | Replan remaining work preserving completed tasks |

For `replan` mode, `{task_description}` is taken from the existing PLAN.md's `## Goal` section.
For `plan` mode, `{task_description}` is the user's original planning request from the current conversation.
For `replan` mode, include `"execution_learnings_dir": "{absolute_project_root}/.planning/{task-id}/execution/"` in metadata if the directory exists.

**Loop execution:**

| Step | Mode | Action | Output |
|------|------|--------|--------|
| 6a | `plan` (or `replan`) | Create plan from research + codebase map + acceptance criteria | `PLAN.md` |
| 6b | `critique` | Adversarially review the plan | `CRITIQUE.md` + PASS/OBJECTIONS |
| 6c (if objections) | `revise` | Address critique objections | Revised `PLAN.md` |
| 6d (if revised) | `critique` | Re-review revised plan | Updated `CRITIQUE.md` + PASS/OBJECTIONS |
| 6e (if objections) | `revise` | Address remaining critique objections | Revised `PLAN.md` |
| 6f (if revised) | `critique` | Re-review revised plan | Updated `CRITIQUE.md` + PASS/OBJECTIONS |

Steps 6a and 6b are **always** executed. Steps 6c-6d execute only if 6b returns OBJECTIONS. Steps 6e-6f execute only if 6d returns OBJECTIONS. After 6f (or earlier if PASS), proceed to Step 7.

Each planner invocation is a **separate** Task tool call (sequential, not parallel — each depends on the previous output).

**Result parsing:** After each critique invocation completes, read the task's completion metadata via `TaskGet`. Check the `result` field: if `PASS`, no objections — proceed to Step 7. If `OBJECTIONS`, proceed to revision. If `ERROR`, surface the error to the user, stop the loop, and suggest remediation.

**Replan note:** For `replan` mode, acceptance criteria from the existing `.planning/{task-id}/ACCEPTANCE-CRITERIA.md` are passed as-is — they represent the task goals, not the implementation approach.

### Step 7: Report

Read `.planning/{task-id}/plans/PLAN.md` and present a summary to the user:
- **Goal** from the plan
- **Acceptance criteria:** {count} criteria generated
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
- Acceptance criteria generated (or pre-existing) before planning starts
- Existing plan with completed tasks triggers replace/replan choice
- Critique loop always runs (steps 6a + 6b minimum)
- Max 2 revision rounds (steps 6c-6d and 6e-6f if needed)
- Plan summary presented to user with critique status
- User informed of next step (`/jc:implement`)

## References

- Agent: `team-planner` (sequential plan-critique-revise)
- Agent: `team-criteria-generator` (acceptance criteria generation)
- Planner workflows (shared): `{plugin-docs}/planner-workflows.md`
- Plan schema: `{plugin-docs}/plan-schema.md`
- I/O contract: `{plugin-docs}/agent-io-contract.md`
