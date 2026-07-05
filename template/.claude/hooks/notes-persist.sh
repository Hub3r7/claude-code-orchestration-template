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

# Extract the NOTES UPDATE body. Read-only agents wrap it in a ```markdown
# fence and lead with an "# H1" title + "## H2" subsections, so we must NOT stop
# at the first "## " (the old bug truncated everything after the title, leaving
# only a fence + title in every read-only agent's notes). Stop only at a
# recognized *sibling* protocol section, or at the closing code fence (which the
# harness may fuse with trailing metadata, e.g. ```agentId:...).
NOTES=$(printf '%s\n' "$RESP" | awk '
  /^##[[:space:]]+NOTES UPDATE[[:space:]]*$/ { f = 1; next }
  !f { next }
  !started && /^[[:space:]]*$/ { next }                 # skip leading blanks
  !started && /^```/ { started = 1; next }              # skip one opening fence
  { started = 1 }
  /^```/ { exit }                                       # closing fence / metadata boundary
  /^##[[:space:]]+(RESULT|HANDOFF|VERDICT|BLOCKED|AGENT UPDATE)/ { exit }
  { print }
')

# Nothing to persist (no section, or an empty one) → leave existing notes alone.
[ -n "$(printf '%s' "$NOTES" | tr -d '[:space:]')" ] || exit 0

# The protocol caps notes at 200 lines; enforce a hard ceiling at 250 so a
# runaway section cannot bloat the file.
if [ "$(printf '%s\n' "$NOTES" | wc -l)" -gt 250 ]; then
  NOTES="$(printf '%s\n' "$NOTES" | head -n 250)
[truncated by notes-persist hook — keep notes under 200 lines]"
fi

mkdir -p "$CWD/.agentNotes/$AGENT"
printf '%s\n' "$NOTES" > "$CWD/.agentNotes/$AGENT/notes.md"

exit 0
