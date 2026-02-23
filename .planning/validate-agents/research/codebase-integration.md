# Codebase Integration Research

> Task: Add a validate-agents script that checks all agent .md files have required sections (Role, Constraints, Workflow, Output Format, Success Criteria)
> Last researched: 2026-02-23T16:52:25Z

## Affected Code

| File/Module | Role | Change Type |
|------------|------|-------------|
| `plugins/jc/agents/team-leader.md` | Team Leader agent — uses `## Lifecycle` instead of `## Workflow` | **read target** (not modified; validation must account for this) |
| `plugins/jc/agents/team-mapper.md` | Codebase mapping agent | read target |
| `plugins/jc/agents/team-researcher.md` | Task-scoped research agent | read target |
| `plugins/jc/agents/team-planner.md` | Plan creation/critique agent | read target |
| `plugins/jc/agents/team-executor.md` | TDD implementation agent | read target |
| `plugins/jc/agents/team-verifier.md` | Functional verification agent — has `## Success Criteria` appearing twice (once in Output Format template at line 155, once as real section at line 250) | read target |
| `plugins/jc/agents/team-reviewer.md` | Code quality review agent | read target |
| `plugins/jc/agents/team-debugger.md` | Root-cause investigation agent | read target |
| New script file (location TBD) | Validation script for agent .md files | **create** |

## Entry Points

The script is a standalone validation tool. It does not hook into any existing agent/skill workflow. It reads agent `.md` files from `plugins/jc/agents/` and reports pass/fail.

There is **no existing build system, Makefile, package.json, or CI pipeline** in this repo. The script will be the first executable artifact. Entry point options:

1. **Project root** as a standalone script (e.g., `scripts/validate-agents.sh` or `scripts/validate-agents.ts`)
2. **Plugin root** at `plugins/jc/scripts/validate-agents.sh` (closer to the files it validates)
3. **Makefile target** at project root (user preference per CLAUDE.md: "Prefer makefile targets")

## Existing Patterns to Follow

### Agent file structure (canonical heading order)

Documented in `plugins/jc/.planning/codebase/CONVENTIONS.md` and `plugins/jc/.planning/codebase/ARCHITECTURE.md`:

```
---
name: <agent-name>
description: "<one-line description>"
tools: <comma-separated tool list>
skills: <comma-separated skill list, if preloaded>
---

## Role
## Focus Areas
## Constraints
## Workflow
## Output Format
## Agent Team Behavior (optional, dual-mode agents only)
## Success Criteria
```

Reference: `.planning/codebase/CONVENTIONS.md` lines 49-69, `.planning/codebase/ARCHITECTURE.md` lines 206-207.

### Naming conventions

- Files: kebab-case throughout — reference: `.planning/codebase/CONVENTIONS.md` lines 7-14
- Agent files: `team-<role>.md` in flat `agents/` directory
- Scripts: no precedent in this repo (first script)

### Important deviations from canonical structure

| Agent | Deviation | Detail |
|-------|-----------|--------|
| `team-leader.md` | Uses `## Lifecycle` instead of `## Workflow` | Lines 51+. This is intentional — the leader coordinates phases rather than executing a workflow |
| `team-debugger.md` | Has extra `## Debug Methodology` section between Constraints and Workflow | Line 41. Additional domain-specific content |
| `team-verifier.md` | `## Success Criteria` appears twice | Line 155 (inside Output Format markdown template) and line 250 (actual section). Parser must distinguish real H2 headings from those inside code blocks |
| `team-mapper.md` | No `## Agent Team Behavior` section | Mapper is not dual-mode |
| `team-researcher.md` | No `## Agent Team Behavior` section | Researcher is not dual-mode |
| `team-leader.md` | No `## Agent Team Behavior` section | Leader IS the team coordinator, not a teammate |

### YAML frontmatter

All 8 agent files have YAML frontmatter delimited by `---`. The frontmatter must be skipped when parsing section headings. Required frontmatter fields are `name` and `description`; `tools`, `skills`, and `mcpServers` are optional.

## Shared Code to Reuse

There is no shared code, utilities, or libraries in this repo. The entire codebase is Markdown specifications. The script will be built from scratch.

## Dependencies

### If shell script (bash)
- `grep` / `awk` / `sed` — standard Unix tools, no new dependencies
- No package manager needed

### If Node.js script
- Would require adding `package.json` (does not exist)
- Adds a runtime dependency to a currently dependency-free repo
- Likely overkill for heading validation

### If Python script
- Python 3 is available on macOS, no pip packages needed for basic file parsing
- No `requirements.txt` needed for stdlib-only script

## Data Flow

### Current state

```
plugins/jc/agents/team-*.md  →  (read manually by humans/agents)
```

### After change

```
plugins/jc/agents/team-*.md  →  validate-agents script  →  stdout (pass/fail per file)
                                                          →  exit code 0/1
```

The script:
1. Discovers all `*.md` files in `plugins/jc/agents/` (excluding `.gitkeep`)
2. For each file, parses YAML frontmatter and top-level `## ` headings
3. Checks presence of required sections: `Role`, `Constraints`, `Workflow`, `Output Format`, `Success Criteria`
4. Reports missing sections per file
5. Exits 0 if all pass, 1 if any fail

### Critical parsing considerations

1. **Code blocks**: `## Success Criteria` inside a ` ```markdown ` block (as in `team-verifier.md`) must not be counted as a real section heading. The parser must track fenced code block state (` ``` ` toggles)
2. **Workflow vs Lifecycle**: The task description lists "Workflow" as required. `team-leader.md` uses `## Lifecycle`. The script must either:
   - Accept `## Lifecycle` as equivalent to `## Workflow` (recommended — documented convention)
   - Or flag it and let the user decide
3. **Frontmatter**: Must skip lines between the opening and closing `---` delimiters
4. **File discovery**: Only `plugins/jc/agents/team-*.md` — not `.gitkeep`, not files in other directories

### File inventory (8 agents)

| File | Role | Constraints | Workflow/Lifecycle | Output Format | Success Criteria |
|------|------|-------------|-------------------|---------------|-----------------|
| `team-leader.md` | line 6 | line 34 | `Lifecycle` line 51 | line 281 | line 308 |
| `team-mapper.md` | line 7 | line 22 | line 35 | line 73 | line 276 |
| `team-researcher.md` | line 8 | line 23 | line 41 | line 85 | line 227 |
| `team-planner.md` | line 8 | line 41 | line 56 | line 142 | line 241 |
| `team-executor.md` | line 8 | line 34 | line 53 | line 95 | line 180 |
| `team-verifier.md` | line 8 | line 42 | line 60 | line 106 | line 250 |
| `team-reviewer.md` | line 7 | line 73 | line 88 | line 125 | line 270 |
| `team-debugger.md` | line 7 | line 22 | line 88 | line 111 | line 235 |

All 8 agents currently have all 5 required sections (with the Workflow/Lifecycle caveat for team-leader). The script's value is **preventing regressions** as new agents are added or existing ones are refactored.
