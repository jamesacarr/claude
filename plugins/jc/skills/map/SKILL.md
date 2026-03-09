---
name: map
description: "Maps a codebase to produce structured analysis documents in .planning/codebase/. Use when starting work on a new codebase, onboarding to a project, or refreshing a stale codebase map. Do NOT use for task-scoped research (use /jc:research)."
---

## Essential Principles

1. **Brownfield vs greenfield.** Detect automatically. Brownfield (source files exist) spawns 4 parallel mappers. Greenfield (empty/minimal codebase) prompts user for stack decisions and writes docs directly.
2. **4 focus areas, 6 files.** Technology → `STACK.md` + `INTEGRATIONS.md`. Architecture → `ARCHITECTURE.md`. Quality → `CONVENTIONS.md` + `TESTING.md`. Concerns → `CONCERNS.md`. All in `.planning/codebase/`.
3. **Agents write directly.** Mapper agents write files themselves — relaying content through the orchestrator risks exhausting the context window on large codebases. Do NOT relay content through the skill.
4. **Commit immediately.** Commit the codebase map right after creation so worktree transfers pick it up and staleness tracking has a baseline.

## Process

### Step 0: Resolve Paths

Resolve from the skill's base directory (the directory containing this SKILL.md):

| Variable | Resolved Path |
|----------|---------------|
| `{plugin-docs}` | `{skill-base-dir}/../../docs/` |
| `{agents-dir}` | `{skill-base-dir}/../../agents/` |

### Step 1: Detect Mode

Check for project indicators — any of: package manifests (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Gemfile`, `pom.xml`, `build.gradle`, etc.), `src/` or `lib/` directories, or a build/bundler config.

- **Any project indicator found** → brownfield mode
- **No indicators** → greenfield mode

If multiple project roots are plausible (e.g., monorepo sub-package with its own `package.json`), use the current working directory as the project root — the skill does not walk up the directory tree.

### Step 2: Check Existing Map

If `.planning/codebase/` already exists with any files:

First, check which of the 6 expected files exist. Then use AskUserQuestion, including the file list in the question context:
- **Regenerate** — overwrite all existing map files with fresh analysis
- **Cancel** — keep current map, do nothing

If user cancels, stop and report current map paths.

### Step 3A: Brownfield — Spawn Mappers

Spawn 4 `team-mapper` agents in parallel via the Task tool. Each agent gets one focus area.

For each agent, create a task via `TaskCreate` with metadata, then spawn the agent with only the task ID:

| Focus Area | `{focus_area}` | `{output_files}` |
|-----------|----------------|-------------------|
| Technology | `technology` | `STACK.md`, `INTEGRATIONS.md` |
| Architecture | `architecture` | `ARCHITECTURE.md` |
| Quality | `quality` | `CONVENTIONS.md`, `TESTING.md` |
| Concerns | `concerns` | `CONCERNS.md` |

**Per agent:**

1. `TaskCreate` with:
   - subject: `map-{focus_area}`
   - description: `Map the {focus_area} focus area for this codebase`
   - metadata: `{"focus_area": "{focus_area}", "codebase_map_dir": "{absolute_project_root}/.planning/codebase/"}`

2. Spawn agent with `subagent_type: "team-mapper"`, prompt: `Your task is {task-id-from-TaskCreate}.`

Spawn all 4 agents in a single message so they run concurrently — sequential spawning would serialize the analysis and roughly quadruple wall-clock time.

After each agent completes, read results via `TaskGet` on the created task to confirm completion.

### Step 3B: Greenfield — Prompt and Write

Use AskUserQuestion to gather key decisions:

1. **Tech stack** — "What language(s) and framework(s) will this project use?"
2. **Architecture** — "What's the high-level structure? (monolith, microservices, monorepo, etc.)"
3. **Testing** — "What test framework and patterns will you use?"
4. **Conventions** — "Any specific naming, style, or tooling conventions to follow?"

Read `{agents-dir}/team-mapper.md` to obtain the output format templates. Write all 6 files directly to `.planning/codebase/` as prescriptive guides based on user answers, conforming to those templates. Get the timestamp via `mcp__time__get_current_time`.

### Step 4: Verify

After all agents complete (brownfield) or docs are written (greenfield), verify all 6 files exist:

```bash
ls .planning/codebase/STACK.md .planning/codebase/INTEGRATIONS.md .planning/codebase/ARCHITECTURE.md .planning/codebase/CONVENTIONS.md .planning/codebase/TESTING.md .planning/codebase/CONCERNS.md
```

If any file is missing, report which files are missing. To recover, re-spawn a single `team-mapper` agent for the failed focus area using the same TaskCreate + Agent pattern from Step 3A with the appropriate `{focus_area}`. The other files are safe — mapper agents only write their own focus area's files.

### Step 5: Commit

Stage and commit the codebase map:

```bash
git add .planning/codebase/
git commit -m "docs(jc): map codebase"
```

NEVER use `--no-gpg-sign`. If GPG signing fails due to sandbox restrictions, exclude the git command from sandboxing. If commit fails for any other reason (lock file, dirty index, pre-commit hook, path errors), report the error, list the files written, and instruct the user to commit manually.

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

- Agent definition: `../../agents/team-mapper.md`
- I/O contract: `../../docs/agent-io-contract.md`
