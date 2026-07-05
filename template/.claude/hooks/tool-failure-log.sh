#!/bin/bash
# PostToolUseFailure hook on Agent/Task: record failed agent invocations.
#
# The chain log is the evidence loop, and tool failures are evidence too. A
# failed Agent call (invalid parameters, subagent died) never reaches
# SubagentStop, so without this the failure exists only in the orchestrator's
# context — invisible to /consolidate. One JSONL line per failure, first line
# of the error only, capped so a giant stack trace cannot bloat the log.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in
  Agent|Task) ;;
  *) exit 0 ;;
esac

CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
AGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"')
# Field name is defensive: take whichever error-ish field the event carries.
ERR=$(echo "$INPUT" | jq -r '
  (.error // .tool_error // .failure_reason // .tool_response // "")
  | if type == "string" then . else tojson end
' 2>/dev/null | head -1 | cut -c1-200)

mkdir -p "$CWD/.agentNotes"
jq -cn --arg a "$AGENT" --arg e "$ERR" \
  '{ts: (now | todate), event: "tool_failure", agent: $a, error: $e}' \
  >> "$CWD/.agentNotes/chain-log.jsonl"
exit 0
