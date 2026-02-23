---
name: cleanup
description: Removes task directories from .planning/ with interactive selection and confirmation. Use when .planning/ is cluttered with finished tasks. Do NOT use for modifying plan state (use jc:implement).
---

# cleanup

## Essential Principles

1. **Always present a multiSelect list.** Even if the user says "just remove them all" or "I trust you" — present the list and let them confirm. This is not optional. The confirmation step is the entire point of the skill: it prevents accidental deletion and provides an audit trail.
2. **Never touch `.planning/codebase/`.** The codebase map is shared across all tasks. It is not a cleanup target — ever. Do not list it, do not offer to remove it, do not suggest it might be stale.
3. **Commit the removal.** After deleting selected directories, stage the specific deletions and commit. The commit message must list which directories were removed.

## Quick Start

No arguments. Scan → present multiSelect → delete selected → commit.

## Process

### Step 1: Scan .planning/ directory

List only directories (ignore loose files):

```bash
ls -d .planning/*/ 2>/dev/null
```

If `.planning/` doesn't exist or has no subdirectories: report "No `.planning/` directory found" and stop.

Filter results: exclude `codebase/`. Everything else is a task-scoped directory.

If no task directories remain after filtering: report "No task directories to clean up" and stop.

### Step 2: Determine status for each task directory

For each task directory, read `plans/PLAN.md` frontmatter to extract `status`:

| Status found | Label |
|-------------|-------|
| `completed` | Completed |
| `paused` | Paused |
| `executing` | Executing |
| `verifying` | Verifying |
| `planning` | Planned |
| No `plans/PLAN.md` found | No plan |

### Step 3: Present multiSelect list

Use `AskUserQuestion` with `multiSelect: true`. Each option is a task directory with its status label.

Format each option label as: `{task-id} ({status label})`

Description for each: brief context (e.g., wave progress if available, "research only" if no plan).

### Step 4: Remove selected directories

For each user-selected directory:

```bash
rm -rf .planning/{task-id}
```

Verify each deletion succeeded. If any `rm -rf` fails, report which directories could not be removed and stop before committing.

### Step 5: Commit the removal

Stage only the deleted paths:

```bash
git add .planning/{task-id-1} .planning/{task-id-2} ...
```

Commit with a message listing removed directories:

```
chore: clean up planning directories

Removed:
- .planning/{task-id-1}
- .planning/{task-id-2}
```

## Anti-Patterns

| Excuse | Reality |
|--------|---------|
| "User said 'just do it' so I'll skip confirmation" | The confirmation IS the skill. Skipping it removes the safety net and audit trail. Present the list regardless of user urgency |
| "All tasks are completed, no need to ask" | Users may want to keep completed tasks for reference. Always let them choose |
| "I'll also clean up codebase/ since it looks stale" | `codebase/` is never a cleanup target. It's shared infrastructure managed by `/jc:map` |
| "I'll use git add -A to stage everything" | `-A` can catch unrelated changes. Stage only the specific deleted paths |

## Related Skills

- `jc:implement` — modifies plan state (status fields, execution)
- `jc:map` — manages `.planning/codebase/`
- `jc:status` — read-only reporting on `.planning/` state

## Success Criteria

- All task directories in `.planning/` are listed with correct status labels
- `codebase/` is never listed or offered for removal
- User explicitly selects which directories to remove via multiSelect
- Removal is committed with a message listing deleted directories
- Deletions are staged specifically (not `git add -A`)
