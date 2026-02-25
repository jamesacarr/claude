---
name: research
description: "Researches a task across 4 dimensions (approach, codebase integration, quality standards, risks) by spawning parallel researcher agents. Use before /jc:plan. Do NOT use for codebase mapping (use /jc:map)."
---

## Essential Principles

1. **4 fixed focus areas.** Every research run spawns 4 researchers: approach, codebase-integration, quality-standards, risks-edge-cases. User confirms or overrides before spawning.
2. **Task-ID is user-facing.** Task-IDs appear in git history, `.planning/` paths, and are reused by all downstream skills (`/jc:plan`, `/jc:implement`). ALWAYS confirm with the user — never silently generate.
3. **Collision = error.** If `.planning/{task-id}/` already exists, stop and alert the user. Do NOT overwrite.
4. **Agents write directly.** Researcher agents write files themselves. Do NOT relay content through the skill.
5. **Always commit.** Research output is committed to git after creation.

## Quick Start

1. Accept task description + optional task-id
2. Resolve task-id — generate slug, detect ticket references, confirm with user
3. Check for collision in `.planning/`
4. Present 4 focus areas for confirmation/override
5. Spawn 4 `team-researcher` agents in parallel
6. Verify all 4 output files exist
7. Commit and suggest `/jc:plan`

## Process

### Step 0: Resolve Paths

Resolve from the skill's base directory (the directory containing this SKILL.md):
- `{plugin-docs}` = `{skill-base-dir}/../../docs/`

### Step 1: Resolve Task-ID

| Input | Task-ID | Action |
|-------|---------|--------|
| User provided task-id | Use as-is | Validate format, confirm with user |
| Ticket reference detected (`WC-123`, `JIRA-456`, `GH-789`) | Use ticket reference | Validate format, confirm with user |
| Task description only | Generate slug (e.g., "add OAuth2 auth" → `add-oauth2-auth`) | Validate format, confirm with user via AskUserQuestion |

**Format rule:** Task-IDs must contain only lowercase alphanumeric characters, hyphens, and underscores. Normalise before presenting: lowercase, replace spaces/slashes with hyphens, strip other special characters.

Use AskUserQuestion to present the generated task-id:
- Question: "Task ID for this research? This will be used in `.planning/{task-id}/` and all downstream skills."
- Options: the generated slug as default, plus "Other" for custom input

### Step 2: Check Collision

Check if `.planning/{task-id}/` already exists:

```bash
ls .planning/{task-id}/ 2>/dev/null
```

If it exists: **stop immediately**. Tell the user the directory already exists and suggest either choosing a different task-id or using the existing research.

### Step 3: Confirm Focus Areas

Present the 4 focus areas via AskUserQuestion (multiSelect with all pre-selected):

| Focus Area | Research Question |
|-----------|------------------|
| **approach** | What are the viable implementation approaches? |
| **codebase-integration** | What existing code is affected and how? |
| **quality-standards** | What are the security, performance, a11y, and testing implications? |
| **risks-edge-cases** | What could go wrong? |

User can override individual focus areas (e.g., replace "risks-edge-cases" with "database migration strategy"). Always spawn exactly 4 researchers.

### Step 4: Spawn Researchers

Get the absolute project root via `pwd`. Spawn all 4 `team-researcher` agents in a **single message** (parallel execution) via the Task tool.

Prompt template per agent, following the I/O contract in `{plugin-docs}/agent-io-contract.md`:

```
## Task
Research the {focus_area} dimension of the given task.

## Context
- Task ID: {task-id}
- Project root: {absolute_project_root}
- Planning directory: {absolute_project_root}/.planning

## Input
- Focus area: {focus_area}
- Task description: {task_description}
- Output file: {absolute_project_root}/.planning/{task-id}/research/{focus-area}.md

## Expected Output
- Write findings to .planning/{task-id}/research/{focus-area}.md
- Return short confirmation listing file written
```

Use `subagent_type: "team-researcher"` for each agent.

### Step 5: Verify Output

After all agents complete, verify all 4 research files exist. Use the confirmed focus area names from Step 3 (which may differ from defaults if the user overrode any):

```bash
ls .planning/{task-id}/research/{focus-area-1}.md .planning/{task-id}/research/{focus-area-2}.md .planning/{task-id}/research/{focus-area-3}.md .planning/{task-id}/research/{focus-area-4}.md
```

If any file is missing, re-spawn that single `team-researcher` agent using the same prompt template. Max 1 retry per missing file — if the retry also fails, report the missing file and advise the user to inspect the agent error response.

### Step 6: Commit

Stage and commit the research output:

```bash
git add .planning/{task-id}/research/ && git commit -m "$(cat <<'EOF'
docs(jc): research {task-id}
EOF
)"
```

NEVER use `--no-gpg-sign`. If GPG signing fails due to sandbox restrictions, disable sandbox for that command. If commit still fails, report files written and instruct user to commit manually.

### Step 7: Report

Report to user:
- Paths to all 4 research documents
- Suggest running `/jc:plan {task-id}` as the next step

## Success Criteria

- Task-ID confirmed with user before proceeding (never silently generated)
- Collision detected and reported if `.planning/{task-id}/` exists
- Focus areas presented for confirmation/override before spawning
- 4 researcher agents spawned in parallel in a single message
- All 4 output files exist in `.planning/{task-id}/research/`
- Research committed to git
- User informed of next step (`/jc:plan`)

## References

- Agent definition: `../../agents/team-researcher.md` (relative to skill directory)
- I/O contract: `{plugin-docs}/agent-io-contract.md`
