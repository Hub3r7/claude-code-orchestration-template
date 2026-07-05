#!/bin/bash
# SessionStart / UserPromptSubmit / PostCompact hook: re-orient the orchestrator
# whenever context (re)enters with a review chain still in flight.
#
# Compaction, session restarts, and /resume are where chain position gets lost —
# the summary or the fresh context may not carry the tier, the chain, and who
# ran already. If a chain is in flight (done shorter than chain in
# .agentNotes/chain-state.json), inject the manifest straight back into context
# so resuming is mechanical, not reconstructive. On UserPromptSubmit the
# reminder is a single line — enough to keep a mid-chain topic change from
# silently abandoning the chain. Silent in every case when no chain is open.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "SessionStart"')
STATE="$CWD/.agentNotes/chain-state.json"

[ -s "$STATE" ] || exit 0
jq -e . "$STATE" >/dev/null 2>&1 || exit 0

UNFINISHED=$(jq -r '
  if (.chain | type == "array") and (.done | type == "array")
  then ((.done | length) < (.chain | length))
  else true end
' "$STATE")
[ "$UNFINISHED" = "true" ] || exit 0

if [ "$EVENT" = "UserPromptSubmit" ]; then
  LINE=$(jq -r '
    "Chain in flight: T" + ((.tier // "?") | tostring)
    + " " + ((.done // []) | length | tostring)
    + "/" + ((.chain // []) | length | tostring)
    + ", next: " + ((.chain // [])[((.done // []) | length)] // "?")
    + " (.agentNotes/chain-state.json). Finish it or abandon it explicitly before unrelated work."
  ' "$STATE")
  jq -cn --arg e "$EVENT" --arg l "$LINE" \
    '{hookSpecificOutput: {hookEventName: $e, additionalContext: $l}}'
  exit 0
fi

MANIFEST=$(cat "$STATE")
LOGTAIL=""
[ -s "$CWD/.agentNotes/chain-log.jsonl" ] && LOGTAIL=$(tail -3 "$CWD/.agentNotes/chain-log.jsonl")

jq -cn --arg e "$EVENT" --arg m "$MANIFEST" --arg l "$LOGTAIL" '{
  hookSpecificOutput: {
    hookEventName: $e,
    additionalContext: (
      "A review chain is in flight. Chain manifest (.agentNotes/chain-state.json):\n"
      + $m
      + (if $l != "" then "\nLast gate verdicts (chain-log.jsonl):\n" + $l else "" end)
      + "\nResume with the first agent in `chain` that is not yet in `done`. Protocol: CLAUDE.md -> Chain state manifest."
    )
  }
}'
exit 0
