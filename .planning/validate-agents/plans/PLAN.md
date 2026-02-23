---
task_id: validate-agents
title: Add validate-agents script with Makefile target
status: planning
created: 2026-02-23T16:56:16Z
updated: 2026-02-23T16:59:50Z
current_wave: null
current_task: null
pause_reason: null
---

# Add validate-agents script with Makefile target

## Goal

A bash script and Makefile target exist such that running `make validate-agents` from the project root validates all `team-*.md` agent files in `plugins/jc/agents/` have the 5 required sections (Role, Constraints, Workflow, Output Format, Success Criteria), correctly handles code-block-aware parsing and the `## Lifecycle` alias, and all 8 existing agents pass validation.

## Success Criteria

1. `scripts/validate-agents.sh` exists, is executable, and runs without errors when invoked directly from the project root
2. `Makefile` exists at project root with a `validate-agents` target and a `help` target that lists available targets
3. `make validate-agents` exits 0 when all 8 current agent files pass validation
4. The script detects missing required sections — removing any one of the 5 required headings from a test fixture file causes exit code 1 and a clear error message naming the file and missing section
5. The script accepts `## Lifecycle` as a valid alias for `## Workflow` (so `team-leader.md` passes)
6. The script ignores `## ` headings inside fenced code blocks (triple-backtick regions) — does not count them as real sections
7. The script reports all failures across all files before exiting (does not stop at first failure)
8. The script exits 1 if no agent files are found in the target directory

## Non-Functional Requirements

1. **Zero dependencies** — the script uses only bash builtins and standard Unix tools (grep, awk, sed) available on macOS and Linux. No package manager, node_modules, or Python required. Rationale: the repo has no package.json, Makefile, or build system (per STACK.md); this must stay dependency-free
2. **Read-only** — the script never modifies any agent files. It reads from `plugins/jc/agents/` and writes only to stdout/stderr. Rationale: security consideration from quality-standards research
3. **Glob-based discovery** — agent files are discovered via `plugins/jc/agents/team-*.md` glob, not a hardcoded list. New agents are automatically included. Rationale: risks research identifies hardcoded lists as a regression vector

## Wave 1: Create script and Makefile

Status: pending

### Task 1.1: Create the validate-agents.sh script

- **Status:** pending
- **Files affected:** `scripts/validate-agents.sh`
- **Action:** Create `scripts/validate-agents.sh` as a bash script. The script must:

  1. Set `#!/usr/bin/env bash` shebang and `set -euo pipefail`
  2. Resolve `REPO_ROOT` relative to the script location using `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` and `REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"` so it works when invoked from any directory
  3. Define the agents directory with an environment variable override for testability: `AGENTS_DIR="${VALIDATE_AGENTS_DIR:-$REPO_ROOT/plugins/jc/agents}"`. This allows tests to point the script at a temporary fixture directory by setting `VALIDATE_AGENTS_DIR`
  4. Define the glob pattern: `team-*.md`
  5. Define the 5 required sections as an array: `("Role" "Constraints" "Workflow" "Output Format" "Success Criteria")`
  6. Discover agent files with the glob. If no files found, print an error message to stderr and exit 1
  7. For each agent file:
     a. **Strip fenced code blocks** before scanning for headings. Implement a state-machine approach: read the file line by line, track whether the parser is inside a fenced code block. The fence toggle pattern must be a **prefix match only**: match lines where the first non-whitespace characters are triple backticks, regardless of what follows (e.g., ` ```markdown `, ` ```bash `, bare ` ``` `). Use `^[[:space:]]*\x60\x60\x60` without a `$` end anchor. This is critical because agent files use language-annotated fences like ` ```markdown ` (e.g., `team-verifier.md` line 148). Collect only lines outside code blocks into a variable for heading search
     b. **Skip YAML frontmatter**: also skip lines between the opening `---` (first line) and the next `---` line
     c. **Check each required section**: for each section name, grep the filtered content for `^## <section-name>[[:space:]]*$` (exact H2 match with optional trailing whitespace). For the "Workflow" check specifically, also accept `^## Lifecycle[[:space:]]*$` as a valid match (documented alias used by `team-leader.md`)
     d. Track missing sections per file
  8. After processing all files, print a summary:
     - For passing files: `PASS: <filename>`
     - For failing files: `FAIL: <filename> — missing: <comma-separated section names>`
  9. Exit 0 if all files pass, exit 1 if any file fails
  10. Make the script executable (`chmod +x`)

  Reference for agent heading structure: `plugins/jc/agents/team-executor.md` (canonical example per CONVENTIONS.md line 51). Reference for the Lifecycle alias: `plugins/jc/agents/team-leader.md` line 51.

- **Verification:** Run `bash scripts/validate-agents.sh` from the project root and confirm exit code 0 with 8 PASS lines
- **Done when:** `scripts/validate-agents.sh` exists, is executable, and `make validate-agents` (or direct invocation) exits 0 with all 8 agents showing PASS
- **Retries:** 0
- **Last failure:** null

### Task 1.2: Create the Makefile

- **Status:** pending
- **Files affected:** `Makefile`
- **Action:** Create `Makefile` at the project root. This is the first Makefile in the repo (none currently exists). Include:

  1. A `.PHONY` declaration for all targets
  2. A `help` target (set as `.DEFAULT_GOAL`) that prints available targets with descriptions, using the self-documenting pattern: each target has a `## description` comment, and `help` greps the Makefile for these comments. Example pattern:
     ```
     .DEFAULT_GOAL := help

     .PHONY: help validate-agents

     help: ## Show available targets
     	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

     validate-agents: ## Validate agent .md files have required sections
     	@bash scripts/validate-agents.sh
     ```
  3. The `validate-agents` target runs `bash scripts/validate-agents.sh`
  4. Use tabs (not spaces) for recipe indentation — this is a Makefile requirement

  This follows the user preference for Makefile targets (per CLAUDE.md: "Prefer makefile targets over direct tool invocation") and establishes the pattern for future targets.

- **Verification:** Run `make help` and confirm it lists `validate-agents` with its description. Run `make validate-agents` and confirm it delegates to the script
- **Done when:** `make help` prints the target list including `validate-agents`, and `make validate-agents` exits 0
- **Retries:** 0
- **Last failure:** null

## Wave 2: Validate edge cases and negative testing

Status: pending

### Task 2.1: Test negative cases with fixture files

- **Status:** pending
- **Files affected:** none (uses temporary files in `$TMPDIR` only; no repo files modified)
- **Action:** Create temporary test fixture files to validate the script catches missing sections correctly. This is manual verification, not a permanent test suite (the repo has no test framework per TESTING.md). Use the `VALIDATE_AGENTS_DIR` environment variable override (implemented in Task 1.1) to point the script at temporary fixture directories. All fixtures use the `team-` prefix to match the glob pattern.

  For each scenario below, create a temp directory at `$TMPDIR/test-agents-<n>/`, place the fixture file in it, and run: `VALIDATE_AGENTS_DIR=$TMPDIR/test-agents-<n> bash scripts/validate-agents.sh`

  1. **Missing section detection**: Create `$TMPDIR/test-agents-1/team-test-missing.md` with valid frontmatter (`---\nname: test\n---`) and only `## Role` and `## Constraints` headings (missing Workflow, Output Format, Success Criteria). Run with `VALIDATE_AGENTS_DIR=$TMPDIR/test-agents-1`. Expected: exit code 1, output contains `FAIL: team-test-missing.md` and lists the 3 missing sections (Workflow, Output Format, Success Criteria)

  2. **Code block immunity**: Create `$TMPDIR/test-agents-2/team-test-codeblock.md` with all 5 required sections as real H2 headings, plus a `## Success Criteria` heading inside a fenced code block (between triple backticks). Run with `VALIDATE_AGENTS_DIR=$TMPDIR/test-agents-2`. Expected: exit code 0, output shows `PASS` (the code-block heading is ignored, and the real heading is found)

  3. **Lifecycle alias**: Create `$TMPDIR/test-agents-3/team-test-lifecycle.md` with `## Lifecycle` instead of `## Workflow` and all other 4 required headings (Role, Constraints, Output Format, Success Criteria). Run with `VALIDATE_AGENTS_DIR=$TMPDIR/test-agents-3`. Expected: exit code 0, output shows `PASS`

  4. **Empty file**: Create `$TMPDIR/test-agents-4/team-test-empty.md` as an empty file. Run with `VALIDATE_AGENTS_DIR=$TMPDIR/test-agents-4`. Expected: exit code 1, output contains `FAIL: team-test-empty.md` and lists all 5 sections as missing

  5. **No files found**: Create an empty directory `$TMPDIR/test-agents-5/` with no `.md` files. Run with `VALIDATE_AGENTS_DIR=$TMPDIR/test-agents-5`. Expected: exit code 1, stderr message indicates no agent files found

  6. **Heading with extra text**: Create `$TMPDIR/test-agents-6/team-test-extra.md` with `## Role and Responsibilities` instead of `## Role`, plus the other 4 required headings correctly. Run with `VALIDATE_AGENTS_DIR=$TMPDIR/test-agents-6`. Expected: exit code 1, output contains `FAIL` and lists `Role` as missing (exact match only, `## Role and Responsibilities` does not satisfy the Role requirement)

  After all 6 scenarios pass, re-run `make validate-agents` against the real agent files to confirm no regressions were introduced.

- **Verification:** Each of the 6 test scenarios produces the expected exit code and output. Final `make validate-agents` re-check exits 0 with 8 PASS lines
- **Done when:** All 6 negative/edge-case scenarios produce correct behavior (proper exit codes and error messages), and `make validate-agents` still passes all 8 real agents
- **Retries:** 0
- **Last failure:** null
