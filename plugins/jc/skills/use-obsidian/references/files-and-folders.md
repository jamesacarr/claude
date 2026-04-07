# Files & Folders

> Create, read, edit, move, and list files and folders in the vault.

## File Targeting

| Parameter | Resolution | Use When |
|-----------|-----------|----------|
| `file=` | Wikilink resolution (partial name, no extension) | User-facing lookups — `file="Meeting Notes"` |
| `path=` | Exact vault-root-relative path | Scripting — `path="projects/2026/spec.md"` |

Both parameters work on all file commands. Omit both to target the active file.

## Create

```bash
obsidian create name="Note Title" content="# Heading\nBody text"
obsidian create path="folder/note.md" content="Content here"
obsidian create name="From Template" template="Template Name"
```

| Parameter | Purpose |
|-----------|---------|
| `name` | Note title (creates `name.md`) |
| `path` | Exact path from vault root |
| `content` | Note body (`\n` for newlines, `\t` for tabs) |
| `template` | Apply a template |

| Flag | Purpose |
|------|---------|
| `--overwrite` | Overwrite if file exists (default: error). **Destructive** — requires user confirmation |
| `--open` | Open the file after creation |
| `--newtab` | Open in a new tab |

## Read

```bash
obsidian read                           # active file
obsidian read file="Note Name"
obsidian read path="folder/note.md"
```

## Append & Prepend

```bash
obsidian append file="Note" content="\n## New Section\nContent"
obsidian prepend file="Note" content="Added before existing content"
```

| Flag | Purpose |
|------|---------|
| `--inline` | Append/prepend inline (no newline separator) |
| `--open` | Open the file after editing |

`prepend` inserts after frontmatter — it won't break YAML properties.

## Open

```bash
obsidian open file="Note Name"
obsidian open path="folder/note.md"
```

| Flag | Purpose |
|------|---------|
| `--newtab` | Open in new tab |

## Move & Rename

```bash
obsidian move file="Old Name" to="new/path/note.md"
obsidian rename file="Old Name" name="New Name"
```

Both commands automatically update internal links throughout the vault.

`rename` preserves the file extension — pass just the name, not `name.md`.

## Delete

```bash
obsidian delete file="Note Name"
```

| Flag | Purpose |
|------|---------|
| `--permanent` | Skip trash, delete permanently |

Default: moves to system trash (recoverable).

## List Files & Folders

```bash
obsidian files                          # all vault files
obsidian files folder="subfolder"       # files in folder
obsidian files ext="md"                 # filter by extension
obsidian files --total                  # count only

obsidian folders                        # all folders
obsidian folders folder="parent"        # subfolders of parent
obsidian folder path="folder" info=size # folder size
```

## File & Folder Info

```bash
obsidian file                           # active file info
obsidian file file="Note Name"          # specific file info
obsidian folder path="folder" info=files  # file count in folder
```

`info` options: `files`, `folders`, `size`.

## File History & Versions

Local file recovery — view and restore previous versions of files.

```bash
obsidian history file="Note"             # list local versions
obsidian history:list                    # list all files with local history
obsidian history:read file="Note"        # read most recent version
obsidian history:read file="Note" version=3  # read specific version
obsidian history:restore file="Note" version=2  # restore version
obsidian history:open                    # open file recovery UI
```

`history:restore` is a mutation — requires user confirmation.

### Comparing Versions

```bash
obsidian diff file="Note"                # list all versions (local + sync)
obsidian diff file="Note" filter=local   # local versions only
obsidian diff file="Note" filter=sync    # sync versions only
obsidian diff file="Note" from=1 to=3    # compare two versions
```
