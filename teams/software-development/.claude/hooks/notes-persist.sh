#!/bin/bash
# PostToolUse hook on Agent/Task: persist read-only agents' working notes.
#
# Read-only agents cannot write their own .agentNotes/<agent>/notes.md, so the
# protocol has them emit a `## NOTES UPDATE` section and made the orchestrator
# copy it over — a mechanical obligation that prose can't guarantee. This hook
# does it mechanically: when a subagent's output contains the section, its
# content is written to the agent's notes file. Agents with Write access don't
# emit the section, so they are unaffected.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL" in
  Agent|Task) ;;
  *) exit 0 ;;
esac

AGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')
# The agent name becomes a path segment — accept plain kebab-case only.
case "$AGENT" in
  *[!a-z0-9-]*|""|-*) exit 0 ;;
esac

CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# The subagent's output may arrive as a plain string or nested in a content
# array; flatten defensively.
RESP=$(echo "$INPUT" | jq -r '
  (.tool_response // .tool_result // "")
  | if type == "string" then .
    elif type == "object" and (.content | type == "array") then
      ([.content[]? | select(.type? == "text") | .text] | join("\n"))
    else ([.. | strings] | join("\n"))
    end
' 2>/dev/null)

NOTES=$(printf '%s\n' "$RESP" | awk '
  /^##[[:space:]]+NOTES UPDATE[[:space:]]*$/ { f = 1; next }
  f && /^## / { exit }
  f { print }
')

# Nothing to persist (no section, or an empty one) → leave existing notes alone.
[ -n "$(printf '%s' "$NOTES" | tr -d '[:space:]')" ] || exit 0

mkdir -p "$CWD/.agentNotes/$AGENT"
printf '%s\n' "$NOTES" > "$CWD/.agentNotes/$AGENT/notes.md"

exit 0
