# Properties & Tasks

> Manage frontmatter properties, tags, tasks, aliases, and word counts.

## Properties

```bash
obsidian properties                      # list all vault properties
obsidian properties file="Note"          # properties of specific note
obsidian properties name="status"        # find notes with property
obsidian properties --active             # properties of active file
obsidian properties format=yaml          # output as YAML
obsidian properties --counts             # show usage counts
obsidian properties sort=count           # sort by frequency
```

Formats: `yaml`, `json`, `tsv`. Flags: `--total`, `--counts`, `--active`.

### Set Property

```bash
obsidian property:set name="status" value="draft" file="Note"
obsidian property:set name="tags" value="project,active" type=list file="Note"
obsidian property:set name="priority" value="1" type=number file="Note"
obsidian property:set name="done" value="true" type=checkbox file="Note"
```

| Type | Example Values |
|------|---------------|
| `text` | `"draft"` (default) |
| `list` | `"item1,item2"` |
| `number` | `"42"` |
| `checkbox` | `"true"`, `"false"` |
| `date` | `"2026-04-07"` |
| `datetime` | `"2026-04-07T10:00:00"` |

### Read & Remove

```bash
obsidian property:read name="status" file="Note"
obsidian property:remove name="status" file="Note"
```

## Tags

```bash
obsidian tags                            # list all vault tags
obsidian tags file="Note"                # tags in specific note
obsidian tags --active                   # tags in active file
obsidian tags --counts                   # show usage counts
obsidian tags sort=count                 # sort by frequency
obsidian tag name="project"              # tag info and usage
obsidian tag name="project" --total      # count of notes with tag
obsidian tag name="project" --verbose    # list files with tag
```

Formats: `json`, `tsv`, `csv`.

## Aliases

```bash
obsidian aliases                         # list all aliases
obsidian aliases --active                # aliases of active file
obsidian aliases --total                 # count
obsidian aliases --verbose               # show source files
```

## Tasks

```bash
obsidian tasks                           # list all tasks
obsidian tasks --todo                    # incomplete only
obsidian tasks --done                    # completed only
obsidian tasks file="Note"              # tasks in specific note
obsidian tasks --active                  # tasks in active file
obsidian tasks --daily                   # tasks in daily note
obsidian tasks status="x"               # filter by status character
obsidian tasks format=json
```

Formats: `json`, `tsv`, `csv`, `text`. Flag: `--total`, `--verbose`.

### Update Task

```bash
obsidian task ref="task-ref"             # show task details
obsidian task file="Note" line=15 --toggle   # toggle completion
obsidian task file="Note" line=15 --done     # mark complete
obsidian task file="Note" line=15 --todo     # mark incomplete
obsidian task file="Note" line=15 status="/" # set custom status
```

`ref` comes from task list output. `line` is the 1-based line number in the file.

## Word Count

```bash
obsidian wordcount                       # active file
obsidian wordcount file="Note"
obsidian wordcount --words               # words only
obsidian wordcount --characters          # characters only
```
