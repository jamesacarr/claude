# Board & Sprint

## Board

```bash
jira board list                                   # list boards in project
jira board list -pPROJ                            # list boards in specific project
```

Aliases: `boards`

## Sprint List

```bash
jira sprint list                                  # top 50 sprints (interactive)
jira sprint list --state active --plain           # active sprints only
jira sprint list --current --plain                # current active sprint issues
jira sprint list --prev --plain                   # previous sprint issues
jira sprint list --next --plain                   # next planned sprint issues
jira sprint list SPRINT_ID --plain --columns type,key,summary,status
```

| Flag | Purpose |
|------|---------|
| `--state` | Filter: `future`, `active`, `closed` (comma-separated) |
| `--current` | Current active sprint issues |
| `--prev` | Previous sprint issues |
| `--next` | Next planned sprint issues |
| `--table` | Table view |
| `--plain` | Plain text output |
| `--columns` | Sprint: `ID,NAME,START,END,COMPLETE,STATE`. Issues: `TYPE,KEY,SUMMARY,STATUS,...` |

## Sprint Add

```bash
jira sprint add SPRINT_ID ISSUE-1 ISSUE-2        # max 50 issues
```

## Sprint Close

```bash
jira sprint close SPRINT_ID
```
