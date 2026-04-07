# Daily Notes & Templates

> Work with daily notes, templates, unique notes, and random notes.

## Daily Notes

```bash
obsidian daily                           # open today's daily note
obsidian daily paneType=tab              # open in new tab
obsidian daily:path                      # get daily note file path
obsidian daily:read                      # read daily note contents
obsidian daily:append content="## Log\n- Item"
obsidian daily:prepend content="Top of note"
```

| Parameter | Purpose |
|-----------|---------|
| `content` | Text to append/prepend (required for append/prepend) |
| `paneType` | `tab`, `split`, or `window` |

| Flag | Purpose |
|------|---------|
| `--inline` | No newline separator |
| `--open` | Open after editing |

`daily:prepend` inserts after frontmatter.

## Templates

```bash
obsidian templates                       # list available templates
obsidian templates --total               # count only
obsidian template:read name="Template"   # read template content
obsidian template:read name="Template" title="Note Title" --resolve  # resolve variables
obsidian template:insert name="Template" # insert into active file
```

| Parameter | Purpose |
|-----------|---------|
| `name` | Template name (required) |
| `title` | Title for variable resolution |

| Flag | Purpose |
|------|---------|
| `--resolve` | Resolve template variables (date, title, etc.) |

## Unique Notes

```bash
obsidian unique                          # create with Zettelkasten-style ID
obsidian unique name="Optional Title" content="Body"
obsidian unique --open                   # open after creation
```

## Random Notes

```bash
obsidian random                          # open random note
obsidian random folder="subfolder"       # random from folder
obsidian random --newtab                 # open in new tab
obsidian random:read                     # read random note (includes path)
obsidian random:read folder="subfolder"
```
