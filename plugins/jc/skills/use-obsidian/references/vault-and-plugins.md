# Vault & Plugins

> Vault info, bases, command palette, plugin management, themes, snippets, sync, publish, and workspaces.

## Vault

```bash
obsidian vault                           # current vault info
obsidian vault info=name                 # vault name only
obsidian vault info=path                 # vault path
obsidian vault info=files                # file count
obsidian vault info=size                 # vault size
obsidian vaults                          # list all known vaults
obsidian vaults --total
obsidian vaults --verbose                # include paths
```

### Target a Specific Vault

Prefix any command with `vault=<name>` or `vault=<id>`:

```bash
obsidian vault=Work files
obsidian vault=Personal daily:read
```

## Bases

Obsidian Bases are structured data views (`.base` files) within the vault.

```bash
obsidian bases                           # list all .base files
obsidian base:views                      # list views in current base
obsidian base:create file="My Base" name="Item" content="field content"
obsidian base:create file="My Base" view="View Name" name="Item"
obsidian base:query file="My Base" format=json
obsidian base:query file="My Base" format=csv
obsidian base:query file="My Base" format=md
obsidian base:query file="My Base" format=paths   # file paths only
```

| Parameter | Purpose |
|-----------|---------|
| `file` | Target base file |
| `view` | Target view within the base |
| `name` | Item name for creation |
| `content` | Item content |
| `format` | Query output: `json`, `csv`, `tsv`, `md`, `paths` |

| Flag | Purpose |
|------|---------|
| `--open` | Open after creation |
| `--newtab` | Open in new tab |

## Command Palette

Execute any Obsidian command by ID — useful for automation and triggering actions not exposed via dedicated CLI commands.

```bash
obsidian commands                        # list all command IDs
obsidian commands filter="export"        # filter by name
obsidian command id="editor:toggle-bold" # execute command by ID
```

## Plugins

```bash
obsidian plugins                         # list all installed
obsidian plugins filter=core             # core plugins only
obsidian plugins filter=community        # community only
obsidian plugins --versions              # include version info
obsidian plugins:enabled                 # list enabled plugins
obsidian plugin id="plugin-id"           # plugin details
```

Formats: `json`, `tsv`, `csv`.

### Enable & Disable

```bash
obsidian plugin:enable id="plugin-id"
obsidian plugin:disable id="plugin-id"
```

### Install & Uninstall

```bash
obsidian plugin:install id="plugin-id"
obsidian plugin:install id="plugin-id" --enable   # install and enable
obsidian plugin:uninstall id="plugin-id"
```

### Restricted Mode

```bash
obsidian plugins:restrict --on           # enable restricted mode
obsidian plugins:restrict --off          # disable restricted mode
```

### Development

```bash
obsidian plugin:reload id="plugin-id"    # reload for development
```

## Themes

```bash
obsidian themes                          # list installed themes
obsidian themes --versions
obsidian theme                           # active theme info
obsidian theme name="Theme Name"         # specific theme details
obsidian theme:set name="Theme Name"     # set active theme
obsidian theme:install name="Theme Name"
obsidian theme:install name="Theme Name" --enable
obsidian theme:uninstall name="Theme Name"
```

## CSS Snippets

```bash
obsidian snippets                        # list all snippets
obsidian snippets:enabled                # enabled only
obsidian snippet:enable name="snippet"
obsidian snippet:disable name="snippet"
```

## Sync

```bash
obsidian sync --on                       # resume sync
obsidian sync --off                      # pause sync
obsidian sync:status                     # sync status and usage
obsidian sync:history                    # file version history (active)
obsidian sync:history file="Note"
obsidian sync:read version=1             # read specific version
obsidian sync:restore version=1          # restore version
obsidian sync:deleted                    # list deleted files
obsidian sync:open                       # open sync history UI
```

## Publish

```bash
obsidian publish:site                    # site info
obsidian publish:list                    # published files
obsidian publish:status                  # pending changes
obsidian publish:status --new            # new files only
obsidian publish:status --changed        # changed only
obsidian publish:status --deleted        # deleted only
obsidian publish:add file="Note"         # publish file
obsidian publish:add --changed           # publish all changes
obsidian publish:remove file="Note"      # unpublish
obsidian publish:open file="Note"        # open on web
```

## Workspaces

```bash
obsidian workspaces                      # list saved workspaces
obsidian workspace                       # current workspace tree
obsidian workspace --ids                 # include pane IDs
obsidian workspace:save name="Layout"    # save current layout
obsidian workspace:load name="Layout"    # load workspace
obsidian workspace:delete name="Layout"  # delete workspace
```

## Tabs & Recent Files

```bash
obsidian tabs                            # list open tabs
obsidian tabs --ids                      # include tab IDs
obsidian tab:open                        # new empty tab
obsidian tab:open file="Note"            # open file in new tab
obsidian recents                         # recently opened files
obsidian recents --total
```

## General

```bash
obsidian help                            # list all commands
obsidian help command="search"           # help for specific command
obsidian version                         # Obsidian version
obsidian reload                          # reload app window
obsidian restart                         # restart application
```

## Bookmarks

```bash
obsidian bookmarks                       # list bookmarks
obsidian bookmarks --verbose             # detailed info
obsidian bookmarks format=json
obsidian bookmark file="Note"            # bookmark a file
obsidian bookmark file="Note" subpath="#heading"  # bookmark heading
obsidian bookmark search="query"         # bookmark a search
obsidian bookmark url="https://..."      # bookmark a URL
```
