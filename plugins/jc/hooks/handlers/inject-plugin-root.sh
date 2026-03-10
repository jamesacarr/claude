#!/usr/bin/env bash
# Injects the plugin root path into agent context via additionalContext.
# Called by the SessionStart hook to provide plugin_root to jc:* agents.
#
# Args:
#   $1 — plugin root path (required, passed from hooks.json)
#
# Stdin: hook input JSON (used to check agent_type)
#
# Skips injection if the session is not a jc:* agent (e.g. a plain `claude` session).

PLUGIN_ROOT="${1:?plugin root not passed as argument}"

# Filter to jc:* agents only
AGENT_TYPE="$(grep -o '"agent_type":"[^"]*"' | head -1 | cut -d'"' -f4)"
if [[ ! "$AGENT_TYPE" =~ ^jc: ]]; then
  echo '{}'
  exit 0
fi

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "plugin_root: ${PLUGIN_ROOT}"
  }
}
EOF
exit 0
