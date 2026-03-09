#!/usr/bin/env bash
# Injects the plugin root path into subagent context.
# CLAUDE_PLUGIN_ROOT is available in hooks.json for path resolution but may
# not be exported to child processes. The root is passed as $1 from hooks.json
# to guarantee availability.
PLUGIN_ROOT="${1:?plugin root not passed as argument}"
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": "plugin_root: ${PLUGIN_ROOT}"
  }
}
EOF
exit 0
