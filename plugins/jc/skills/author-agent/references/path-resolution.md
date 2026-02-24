# Path Resolution

> Context detection algorithm for determining where agents live. Check CWD for context markers, default to global.

## Resolution Algorithm

Check CWD directly — no directory walking. Default to global.

| Check | Context | `{agents-dir}` |
|-------|---------|-----------------|
| `.claude-plugin/plugin.json` exists in CWD | Plugin | `{CWD}/agents/` |
| `.claude-plugin/marketplace.json` exists in CWD | Marketplace | *(prompt user to select plugin)* |
| `.claude/agents/` exists in CWD | Project | `{CWD}/.claude/agents/` |
| *(none of the above)* | Global (default) | `~/.claude/agents/` |

First match wins. Always announce resolved context before proceeding.

**Name collision:** If context is not Global and the target agent also exists in `~/.claude/agents/` (global), list both locations and ask which to use before proceeding.

## Marketplace Selection

When marketplace context is detected:

1. Read `.claude-plugin/marketplace.json` — parse the plugins list
2. Filter to entries where `source` is a string path (skip entries where `source` is an object with `"url"`)
3. For each local plugin, check if `{source}/agents/` exists
4. Present numbered list of plugins that have agents directories
5. User selects plugin — set `{agents-dir}` to `{selected-plugin}/agents/`

If no plugins have `agents/`, report: "No plugins in this marketplace have agents directories."

## Plugin Docs Resolution

Also resolve `{plugin-docs}` from the skill's own location: `{skill-base-dir}/../../docs/`

This enables references like `{plugin-docs}/agent-io-contract.md` to resolve correctly regardless of whether the skill runs from source or cache.

## Context Label

After resolution, announce:
```
Context: {Plugin|Marketplace|Project|Global} — agents dir: {agents-dir}
```
This confirms the resolved path before any workflow proceeds.
