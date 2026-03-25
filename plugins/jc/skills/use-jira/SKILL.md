---
name: use-jira
description: Manages Jira issues, epics, sprints, and boards using the jira CLI (ankitpokhrel/jira-cli). Use when creating, viewing, editing, searching, or transitioning Jira issues, managing epics, or working with sprints and boards.
---

# use-jira

## Essential Principles

- **Epic commands are separate from issue commands** because the CLI treats epics as a distinct resource — mixing issue and epic subcommands silently fails or produces wrong results. Use `jira epic create`, `jira epic add`, `jira epic remove`, `jira epic list` — do NOT use `jira issue create -tEpic` or `jira issue link` for epic operations.
- **Stdin descriptions use `--template -`** (not `--body-template` or `--stdin`). For `issue edit`, pipe to stdin with `--no-input` instead.
- **Use shorthand filter flags** (`-t`, `-s`, `-a`, `-y`, `-l`, `-P`) for `issue list` instead of raw JQL when possible — they are safer to compose programmatically and less error-prone for simple filters. Reserve `-q`/`--jql` for queries that cannot be expressed with shorthand.
- **`$(jira me)` for current user.** Use in `-a$(jira me)` for assignee, not `currentUser()` (that's JQL-only syntax).
- **Negate filters with `~` prefix.** `-s~Done` means "not Done". Use `-ax` for unassigned.
- **No interactive flags** — the agent runs non-interactively and a prompt will hang indefinitely. Use `--no-input` to skip prompts.
- **`--plain` for scripting.** Use `--plain` output when parsing results or piping to other commands.
- **Custom fields use field name, not ID.** `--custom field-name="value"`, not `--custom customfield_10001="value"`. View available custom fields in `jira init` config output.
- **Confirm with user before any mutation** (create, edit, move, delete). Never execute a write operation without explicit user approval.

## Prerequisites

```bash
command -v jira >/dev/null 2>&1
```

If not found: `brew tap ankitpokhrel/jira-cli && brew install jira-cli`. Then configure: `jira init`.

Verify authentication:

```bash
jira me
```

If `jira me` fails: run `jira init` to configure. Set default project via `jira init` or use `-p PROJECT_KEY` per command.

## Quick Start

```bash
jira issue create -tStory -s"Summary" --template -
jira issue view PROJ-123
jira issue list -a$(jira me) -s~Done --plain
jira issue move PROJ-123 "In Progress"
jira epic create -n"Epic Name" -s"Summary" -yHigh
jira epic list EPIC-KEY --plain
jira sprint list --current --plain
```

## References

Read the relevant reference for detailed flags, examples, and heredoc patterns:

- **Issues** (create, view, edit, move, comment, assign, link, search): `references/issues.md`
- **Epics** (create, list, add/remove issues, view): `references/epics.md`
- **Board & Sprint** (board list, sprint list/add/close): `references/board-sprint.md`

## Useful Flags (Global)

| Flag | Purpose |
|------|---------|
| `-p, --project` | Project key (overrides configured default) |
| `-c, --config` | Config file path |
| `--debug` | Debug output |

## Success Criteria

- Correct command group used (epic commands for epic ops, issue commands for issue ops)
- `--template -` used for stdin descriptions on create, `--no-input` for edit
- Shorthand filter flags preferred over raw JQL where possible
- No interactive flags (`-i`) used
- User confirmed before any mutation (create, edit, move, delete)
