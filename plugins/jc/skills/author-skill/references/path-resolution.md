# Path Resolution

> Context detection algorithm for determining where skills live. Check CWD for context markers, default to global.

## Resolution Algorithm

Check CWD directly — no directory walking. Default to global.

| Check | Context | `{skills-dir}` | `{agents-dir}` |
|-------|---------|-----------------|-----------------|
| `.claude-plugin/plugin.json` exists in CWD | Plugin | `{CWD}/skills/` | `{CWD}/agents/` |
| `.claude-plugin/marketplace.json` exists in CWD | Marketplace | *(prompt user to select plugin)* | N/A |
| `.claude/skills/` exists in CWD | Project | `{CWD}/.claude/skills/` | `{CWD}/.claude/agents/` |
| *(none of the above)* | Global (default) | `~/.claude/skills/` | `~/.claude/agents/` |

First match wins. Always announce resolved context before proceeding.

**Name collision:** If context is not Global and the target skill also exists in `~/.claude/skills/` (global), list both locations and ask which to use before proceeding.

## Marketplace Selection

When marketplace context is detected:

1. Read `.claude-plugin/marketplace.json` — parse the plugins list
2. Filter to entries where `source` is a string path (skip entries where `source` is an object with `"url"`)
3. For each local plugin, check if `{source}/skills/` exists
4. Present numbered list of plugins that have skills directories
5. User selects plugin — set `{skills-dir}` to `{selected-plugin}/skills/`, `{agents-dir}` to `{selected-plugin}/agents/`

If no plugins have `skills/`, report: "No plugins in this marketplace have skills directories."

## Context Label

After resolution, announce:
```
Context: {Plugin|Marketplace|Project|Global} — skills dir: {skills-dir}
```
This confirms the resolved path before any workflow proceeds.
