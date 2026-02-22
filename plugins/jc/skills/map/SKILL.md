---
name: map
description: "Maps a codebase to produce structured analysis documents in .planning/codebase/. Use when starting work on a new codebase or onboarding to a project. Do NOT use for task-scoped research (use /jc:research)."
---

## Essential Principles

1. **Brownfield vs greenfield.** Detect automatically. Brownfield (source files exist) spawns 4 parallel mappers. Greenfield (empty/minimal codebase) prompts user for stack decisions and writes docs directly.
2. **4 focus areas, 6 files.** Technology → `STACK.md` + `INTEGRATIONS.md`. Architecture → `ARCHITECTURE.md`. Quality → `CONVENTIONS.md` + `TESTING.md`. Concerns → `CONCERNS.md`. All in `.planning/codebase/`.
3. **Agents write directly.** Mapper agents write files themselves. Do NOT relay content through the skill — minimises context load.
4. **Always commit.** The codebase map is committed to git after creation. Required for worktree transfer and staleness tracking.

## Quick Start

1. Detect brownfield (project indicators exist) or greenfield (empty project)
2. If `.planning/codebase/` exists — ask regenerate or cancel
3. Brownfield — spawn 4 parallel `team-mapper` agents
4. Greenfield — prompt for stack decisions, write docs directly
5. Verify all 6 files exist
6. Commit to git
7. Suggest `/jc:research` as next step

## Process

### Step 1: Detect Mode

Check for project indicators — any of: package manifests (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Gemfile`, `pom.xml`, `build.gradle`, etc.), `src/` or `lib/` directories, or a build/bundler config.

- **Any project indicator found** → brownfield mode
- **No indicators** → greenfield mode

### Step 2: Check Existing Map

If `.planning/codebase/` already exists with any files:

First, check which of the 6 expected files exist. Then use AskUserQuestion, including the file list in the question context:
- **Regenerate** — overwrite all existing map files with fresh analysis
- **Cancel** — keep current map, do nothing

If user cancels, stop and report current map paths.

### Step 3A: Brownfield — Spawn Mappers

Spawn 4 `team-mapper` agents in parallel via the Task tool. Each agent gets one focus area.

Use this prompt template for each, following the I/O contract in `plugins/jc/docs/agent-io-contract.md`:

```
## Task
Map the {focus_area} focus area for this codebase.

## Context
- Project root: {absolute_project_root}
- Planning directory: {absolute_project_root}/.planning

## Input
- Focus area: {focus_area}
- Output directory: .planning/codebase/

## Expected Output
- Write {output_files} to .planning/codebase/
- Return short confirmation listing files written
```

| Focus Area | `{focus_area}` | `{output_files}` |
|-----------|----------------|-------------------|
| Technology | `technology` | `STACK.md`, `INTEGRATIONS.md` |
| Architecture | `architecture` | `ARCHITECTURE.md` |
| Quality | `quality` | `CONVENTIONS.md`, `TESTING.md` |
| Concerns | `concerns` | `CONCERNS.md` |

All 4 agents MUST be spawned in a single message (parallel execution). Use `subagent_type: "team-mapper"` for each.

### Step 3B: Greenfield — Prompt and Write

Use AskUserQuestion to gather key decisions:

1. **Tech stack** — "What language(s) and framework(s) will this project use?"
2. **Architecture** — "What's the high-level structure? (monolith, microservices, monorepo, etc.)"
3. **Testing** — "What test framework and patterns will you use?"
4. **Conventions** — "Any specific naming, style, or tooling conventions to follow?"

Write all 6 files directly to `.planning/codebase/` as prescriptive guides based on user answers. Use the same output format as the team-mapper agent (see `plugins/jc/agents/team-mapper.md` for templates). Get the timestamp via `date -u +"%Y-%m-%dT%H:%M:%SZ"`.

### Step 4: Verify

After all agents complete (brownfield) or docs are written (greenfield), verify all 6 files exist:

```bash
ls .planning/codebase/STACK.md .planning/codebase/INTEGRATIONS.md .planning/codebase/ARCHITECTURE.md .planning/codebase/CONVENTIONS.md .planning/codebase/TESTING.md .planning/codebase/CONCERNS.md
```

If any file is missing, report which files are missing. To recover, re-spawn a single `team-mapper` agent for the failed focus area using the same prompt template from Step 3A with the appropriate `{focus_area}`. The other files are safe — mapper agents only write their own focus area's files.

### Step 5: Commit

Stage and commit the codebase map:

```bash
git add .planning/codebase/
git commit -m "docs(jc): map codebase"
```

NEVER use `--no-gpg-sign`. If GPG signing fails due to sandbox restrictions, disable sandbox for that command. If commit still fails, report the files written and instruct the user to commit manually.

### Step 6: Report

Report to user:
- Paths to all 6 codebase map documents
- Suggest running `/jc:research` as the next step for task-scoped work

## Success Criteria

- All 6 files exist in `.planning/codebase/` after completion
- Brownfield: 4 mapper agents spawned in parallel with correct focus areas
- Greenfield: user prompted for stack decisions before writing
- Existing map: user asked before overwriting
- Codebase map committed to git
- User informed of next step (`/jc:research`)

## References

- Agent definition: `plugins/jc/agents/team-mapper.md`
- I/O contract: `plugins/jc/docs/agent-io-contract.md`
