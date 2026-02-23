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

### Step 1: Scan .planning/ directory

```bash
ls -1 .planning/ 2>/dev/null
```

If `.planning/` doesn't exist: report "No `.planning/` directory found" and stop.

If `.planning/` exists but contains no subdirectories: report "No tasks found" (codebase map section still applies if `codebase/` exists).

Separate results into:
- `codebase/` — shared codebase map
- Everything else — task-scoped directories

### Step 2: Report codebase map status

Check `.planning/codebase/` for the 6 expected files: `STACK.md`, `INTEGRATIONS.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`.

**If missing entirely:** Report "Codebase map: Not found. Run `/jc:map` to create."

**If exists:** Count source commits since last map update:

```bash
git log --oneline "$(git log -1 --format=%H -- .planning/codebase/)..HEAD" -- . ':!.planning/' | wc -l
```

If the inner `git log -1` returns empty (codebase map never committed), report commit count as "unknown".

Report: exists, number of commits since last map, list any of the 6 files that are missing.

### Step 3: Report each task

For each task directory in `.planning/` (excluding `codebase/`), determine phase from contents:

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

**For tasks with a PLAN.md**, also report:
- Current wave / total waves (from frontmatter `current_wave` and wave count)
- Current task (from frontmatter `current_task`, if executing)
- Task counts by status (passed, failed, skipped, in_progress, pending)
- `pause_reason` if paused
- Whether verification reports exist in `verification/`
- Whether a review report exists in `reviews/`

### Step 4: Present report

Format as a structured summary. Group tasks by phase (active first, completed last).

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
