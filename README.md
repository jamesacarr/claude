# Claude Code Marketplace & Plugins

A personal marketplace containing curated plugins for Claude Code.

## Structure

```
.claude-plugin/
  marketplace.json    # Marketplace manifest
plugins/
  jc/                 # James' Claude Toolkit
    .claude-plugin/
      plugin.json     # Plugin manifest
```

## Plugins

| Plugin | Description | Version |
|--------|-------------|---------|
| `jc`  | James' Claude Toolkit | 0.0.1 |

## Usage

### Add the marketplace

```
/plugin marketplace add jamesacarr/claude
```

### Install a plugin

```
/plugin install jc@jamesacarr-claude
```

### Manage

```
/plugin marketplace list          # List marketplaces
/plugin marketplace update        # Refresh listings
/plugin marketplace remove        # Remove marketplace
/plugin disable jc@jamesacarr-claude   # Disable plugin
/plugin uninstall jc@jamesacarr-claude # Uninstall plugin
```

## License

UNLICENSED
