---
name: use-obsidian
description: Manages Obsidian vaults using the native obsidian CLI — file operations, search, daily notes, properties, tags, tasks, plugins, sync, and publish. Use when creating, reading, searching, or organising notes, managing properties/tags, working with daily notes or templates, managing vault sync/publish, working across multiple vaults, or any obsidian CLI operation. Do NOT use for Obsidian Markdown syntax guidance (wikilinks, callouts, embeds) — that is content formatting, not CLI operations.
---

# use-obsidian

## Essential Principles

- **Obsidian must be running** — the CLI communicates with the running app via IPC. If Obsidian isn't running, the first command launches it automatically, but expect a startup delay
- **`file=` vs `path=`** — `file=` uses wikilink resolution (partial names, no extension needed); `path=` requires the exact vault-root-relative path. Prefer `file=` for user-facing lookups, `path=` for scripting precision
- **Default vault is CWD** — if the terminal's working directory is inside a vault, that vault is used. Otherwise, targets the active vault. Use `vault=<name>` as the first parameter to target a specific vault
- **Quote values with spaces** — `file="My Note"`. Multiline content uses `\n` for newlines and `\t` for tabs
- **Confirm with user before mutations** (create, move, rename, delete, `--overwrite`, sync:restore, publish:add/remove, plugin:install/enable/disable) — these operations modify the vault and may trigger sync side-effects

## Prerequisites

```bash
command -v obsidian >/dev/null 2>&1
```

If not found: enable in Obsidian → Settings → General → "Command line interface", then restart your terminal.

Verify the CLI can reach the running app:

```bash
obsidian vault
```

If it fails: ensure Obsidian is running (the CLI requires a live app connection via IPC).

## Quick Start

```bash
obsidian vault                          # show current vault info
obsidian vault=Work files               # list files in a specific vault
obsidian files                          # list vault files
obsidian read file="Note Name"          # read a note
obsidian create name="New Note" content="# Title\nBody text"
obsidian search query="search term"     # search vault
obsidian daily:read                     # read today's daily note
obsidian properties file="Note"         # list note properties
obsidian tags                           # list all tags
obsidian tasks --todo                   # list incomplete tasks
```

## References

- **Files & Folders** (create, read, append, prepend, move, rename, delete, open, list, history, diff): `references/files-and-folders.md`
- **Search & Links** (search, backlinks, outgoing links, orphans, unresolved, outline): `references/search-and-links.md`
- **Daily Notes & Templates** (daily notes, templates, unique notes, random notes): `references/daily-notes-and-templates.md`
- **Properties & Tasks** (frontmatter properties, tags, tasks, aliases, wordcount): `references/properties-and-tasks.md`
- **Vault & Plugins** (vault info, bases, command palette, plugins, themes, snippets, sync, publish, workspaces): `references/vault-and-plugins.md`

## Success Criteria

- `file=` used for user-facing lookups, `path=` for exact paths
- `vault=` specified when operating outside the target vault's directory
- User confirmed before any mutation (create, move, rename, delete, overwrite, sync/publish ops, plugin changes)
- Output format flags (`--plain`, json, tsv, csv) used when parsing results programmatically
