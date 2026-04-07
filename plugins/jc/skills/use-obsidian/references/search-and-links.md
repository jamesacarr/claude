# Search & Links

> Search vault content, explore link graphs, and inspect document outlines.

## Search

```bash
obsidian search query="search term"
obsidian search query="search term" path="folder" limit=10
obsidian search query="search term" format=json
obsidian search:context query="search term"     # grep-style with line context
obsidian search:open query="search term"         # open search UI in Obsidian
```

| Parameter | Purpose |
|-----------|---------|
| `query` | Search text (required) |
| `path` | Restrict to folder |
| `limit` | Max results |
| `format` | Output format: `text` (default), `json` |

| Flag | Purpose |
|------|---------|
| `--total` | Show count only |
| `--case` | Case-sensitive search |

`search:context` returns matches with surrounding lines — useful for understanding context without reading the full file.

## Backlinks

```bash
obsidian backlinks                       # backlinks to active file
obsidian backlinks file="Note Name"
obsidian backlinks file="Note" format=json
```

| Flag | Purpose |
|------|---------|
| `--total` | Count only |
| `--counts` | Show link count per file |

Formats: `json`, `tsv`, `csv`.

## Outgoing Links

```bash
obsidian links                           # links from active file
obsidian links file="Note Name"
obsidian links --total
```

## Unresolved Links

```bash
obsidian unresolved                      # vault-wide broken links
obsidian unresolved --total
obsidian unresolved --counts             # count per file
obsidian unresolved --verbose            # show source files
```

## Orphans & Dead Ends

```bash
obsidian orphans                         # files with no incoming links
obsidian orphans --total
obsidian deadends                        # files with no outgoing links
obsidian deadends --total
```

Useful for vault maintenance — orphans are disconnected notes, dead ends are notes that don't link elsewhere.

## Outline

```bash
obsidian outline                         # headings of active file
obsidian outline file="Note Name"
obsidian outline format=tree             # tree view (default)
obsidian outline format=md               # markdown list
obsidian outline format=json
obsidian outline --total                 # heading count
```
