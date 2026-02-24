---
name: status
description: Reports on .planning/ state without modifying anything. Use when checking task progress, codebase map freshness, or planning directory status. Do NOT use for modifying plan state (use jc:implement).
---

# status

## Essential Principles

1. **Read-only. No exceptions.** NEVER modify any file in `.planning/`. Not PLAN.md, not frontmatter, not status fields — nothing. Even if the user asks you to "fix" or "update" stale status, refuse. PLAN.md status fields are managed by the implement skill's state machine — direct edits corrupt resume/recovery state.
2. **Report what exists.** Derive phase from directory contents and PLAN.md frontmatter. Don't infer or guess what *should* be there.
3. **Always check the codebase map.** Report existence, staleness (commits since last map), and missing files.

## Quick Start

Run without arguments. Scans `.planning/` and prints a structured status report. No files are modified.

## Process

### Step 1: Delegate Scanning

Spawn a `general-purpose` agent via the Task tool. The agent does ALL scanning — directory listing, frontmatter parsing, git commands — and returns the formatted report. Main context never sees raw output.

**CRITICAL: Include "NEVER modify any file in .planning/" in the agent prompt.**

Agent prompt must include the full scanning methodology:

**Directory scanning:**
- List `.planning/` contents. If missing: report "No `.planning/` directory found" and stop.
- If no subdirectories: report "No tasks found" (codebase map section still applies if `codebase/` exists).
- Separate `codebase/` (shared map) from task directories.

**Codebase map check:**
- Check `.planning/codebase/` for 6 expected files: `STACK.md`, `INTEGRATIONS.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`.
- If missing entirely: report "Codebase map: Not found. Run `/jc:map` to create."
- If exists: count source commits since last map — two separate commands (no variable interpolation):
  1. `git log -1 --format=%H -- .planning/codebase/`
  2. If hash returned: `git log --oneline <paste-hash>..HEAD -- . ':!.planning/' | wc -l`
  3. If no hash (never committed): report "unknown"

**Phase detection per task directory** (excluding `codebase/`):

| Phase | How to detect |
|-------|---------------|
| **Unknown** | No `research/` or `plans/PLAN.md` found |
| **Research (incomplete)** | `research/` exists with fewer than 4 expected files (`approach.md`, `codebase-integration.md`, `quality-standards.md`, `risks-edge-cases.md`) |
| **Research (complete)** | `research/` has all 4 files, no `plans/` directory |
| **Planned** | `plans/PLAN.md` exists, frontmatter `status: planning` |
| **Executing** | `plans/PLAN.md` frontmatter `status: executing` |
| **Paused** | `plans/PLAN.md` frontmatter `status: paused` |
| **Verifying** | `plans/PLAN.md` frontmatter `status: verifying` |
| **Completed** | `plans/PLAN.md` frontmatter `status: completed` |

For tasks with PLAN.md, also report: current wave/total waves, current task (if executing), task counts by status, `pause_reason` (if paused), verification report existence, review report existence.

**Report format** — group tasks by phase (active first, completed last):

```
## Codebase Map
Status: {exists | missing}
Commits since last map: {n}
Missing files: {list | none}

## Tasks

### {task-id} — {phase}
Wave: {current}/{total}
Tasks: {n} passed, {n} pending, {n} in_progress, {n} failed, {n} skipped
{Verification: task-level reports exist for tasks 1-4}
{Review: PLAN-REVIEW.md exists}
{Paused: reason}

### {task-id} — Research (incomplete)
Research docs: {n}/4
Missing: {list}
```

### Step 2: Present Report

Present the agent's report to the user as-is. Do not add intermediate tool output or scanning details. If the agent returns an error or non-report output, surface the error and suggest re-running `/jc:status`.

## Anti-Patterns

| Excuse | Reality |
|--------|---------|
| "PLAN.md is just a text file, editing is safe" | The implement skill uses PLAN.md status fields as a state machine. Direct edits break resume, recovery, and retry tracking |
| "The user asked me to update status" | Status updates happen through `/jc:implement`. Report what you see and direct the user there |
| "I'll just fix this one stale field" | One "fix" breaks the contract. The implement skill may overwrite your change or misinterpret state on resume |

## Success Criteria

- Every task directory in `.planning/` is reported with correct phase
- Codebase map staleness is calculated using git commit count
- No files in `.planning/` are modified
- Verification and review report existence is noted
- User directed to appropriate skill for any action (map, research, implement)
