# Issues

## Create

```bash
jira issue create -tStory -s"Summary" -PPARENT-KEY --custom field-name="value" --template -
```

| Flag | Purpose |
|------|---------|
| `-t, --type` | Issue type: `Story`, `Bug`, `Spike`, `Task` |
| `-s, --summary` | Title |
| `-P, --parent` | Parent issue key (epic or parent task) |
| `-b, --body` | Inline description (takes precedence over `--template`) |
| `-T, --template` | Read description from file; use `-` for stdin |
| `-a, --assignee` | Assignee (username, email, or display name) |
| `-y, --priority` | Priority level |
| `-l, --label` | Labels (repeatable) |
| `-C, --component` | Components (repeatable) |
| `--custom` | Custom fields: `--custom field-name="value"` |
| `--no-input` | Skip interactive prompts |
| `--web` | Open in browser after creation |
| `--raw` | Print JSON output |

**Description from stdin (heredoc):** delimiter is single-quoted (`'EOF'`) to prevent shell variable expansion in the description body.

```bash
cat << 'EOF' | jira issue create -tStory -s"Summary" -PPARENT-KEY --custom field-name="value" --template -
## Description
Content here
EOF
```

## View

```bash
jira issue view PROJ-123
jira issue view PROJ-123 --plain
```

## Edit

```bash
jira issue edit PROJ-123 -s"New summary"
jira issue edit PROJ-123 --custom field-name="value"
jira issue edit PROJ-123 --label "frontend" --label "urgent"
jira issue edit PROJ-123 --label -old-label           # remove label (minus prefix)
jira issue edit PROJ-123 -PNEW-PARENT --no-input      # change parent
```

**Edit description from stdin:** delimiter is single-quoted (`'EOF'`) to prevent shell variable expansion.

```bash
cat << 'EOF' | jira issue edit PROJ-123 --no-input
Updated description content
EOF
```

## Transition (Move)

To see available transitions: `jira issue view PROJ-123` (transitions listed at bottom).

```bash
jira issue move PROJ-123 "In Progress"
jira issue move PROJ-123 Done -RFixed                           # with resolution
jira issue move PROJ-123 "In Progress" -a$(jira me) --comment "Starting"
```

Aliases: `transition`, `mv`

## Comment

```bash
jira issue comment add PROJ-123 "Comment text"
jira issue comment add PROJ-123 "Internal note" --internal    # visible to project members only
```

**Mentioning users:** Mentioning/tagging users via the CLI is NOT supported — neither `@Name` nor `@@Name` creates a proper Jira mention. Both render as plain text. Users must manually edit the comment in the Jira web UI to add proper @mentions.

**Multi-line comment:**

```bash
jira issue comment add PROJ-123 "$(cat << 'EOF'
## Update
- Completed task A
- Blocked on B
EOF
)"
```

## Assign

```bash
jira issue assign PROJ-123 "user@example.com"
jira issue assign PROJ-123 $(jira me)
```

## Link / Unlink

```bash
jira issue link PROJ-123 PROJ-456 "Blocks"
jira issue unlink PROJ-123 PROJ-456
```

| Link Type | Meaning |
|-----------|---------|
| `Blocks` | This issue blocks another |
| `is blocked by` | This issue is blocked by another |
| `relates to` | General relationship |
| `duplicates` | Duplicate of another |

## Search (List)

```bash
jira issue list -a$(jira me) -tBug -s~Done -yHigh --created -7d --plain
```

| Flag | Purpose | Examples |
|------|---------|----------|
| `-a` | Assignee | `-a$(jira me)`, `-ax` (unassigned), `-a"Name"` |
| `-t` | Type | `-tBug`, `-tStory` |
| `-s` | Status | `-s"In Progress"`, `-s~Done` (negate with `~`) |
| `-y` | Priority | `-yHigh` |
| `-l` | Label | `-lurgent` (repeatable) |
| `-P` | Parent/epic | `-PEPIC-123` |
| `-q` | Raw JQL | `-q"project = PROJ AND assignee = currentUser() AND status != Done"` |
| `--created` | Created date | `today`, `week`, `month`, `-7d`, `-4w` |
| `--updated` | Updated date | Same formats as `--created` |
| `--paginate` | Pagination | `20` (limit), `10:50` (offset:limit) |

**Output formats:**

| Flag | Format |
|------|--------|
| `--plain` | Plain text table |
| `--plain --columns key,summary,status` | Specific columns |
| `--plain --no-headers` | No headers |
| `--raw` | JSON |
| `--csv` | CSV |

Aliases: `lists`, `ls`, `search`

## Other Issue Operations

| Operation | Command |
|-----------|---------|
| Clone issue | `jira issue clone PROJ-123` |
| Delete issue | `jira issue delete PROJ-123` |
| Watch issue | `jira issue watch PROJ-123` |
| Open in browser | `jira open PROJ-123` |
| Attachments | Jira UI or REST API (not supported by CLI) |
