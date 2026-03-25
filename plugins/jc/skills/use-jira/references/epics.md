# Epics

## Create Epic

```bash
jira epic create -n"Epic Name" -s"Summary" -yHigh -b"Description"
```

| Flag | Purpose |
|------|---------|
| `-n, --name` | Epic name (required) |
| `-s, --summary` | Epic summary/title |
| `-b, --body` | Description |
| `-y, --priority` | Priority |
| `-a, --assignee` | Assignee |
| `-l, --label` | Labels (repeatable) |
| `--custom` | Custom fields |
| `--no-input` | Skip prompts |

## List Epics / Epic Issues

```bash
jira epic list                                    # list all epics
jira epic list --table --plain                    # epics in plain table
jira epic list PROJ-50 --plain --columns type,key,summary,status   # issues in epic
```

## Add Issues to Epic

```bash
jira epic add EPIC-KEY ISSUE-1 ISSUE-2           # max 50 issues
```

## Remove Issues from Epic

```bash
jira epic remove ISSUE-1 ISSUE-2
```

## View Epic

```bash
jira epic view EPIC-KEY
```
