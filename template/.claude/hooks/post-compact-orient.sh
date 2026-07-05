#!/bin/bash
# PostCompact hook: re-orient the orchestrator after context compaction.
#
# Compaction is where chain position gets lost — the summary may or may not
# carry the tier, the chain, and who ran already. If a chain is in flight
# (done shorter than chain in .agentNotes/chain-state.json), inject the
# manifest and the last verdicts straight back into context so resuming is
# mechanical, not reconstructive.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
STATE="$CWD/.agentNotes/chain-state.json"

[ -s "$STATE" ] || exit 0
jq -e . "$STATE" >/dev/null 2>&1 || exit 0

UNFINISHED=$(jq -r '
  if (.chain | type == "array") and (.done | type == "array")
  then ((.done | length) < (.chain | length))
  else true end
' "$STATE")
[ "$UNFINISHED" = "true" ] || exit 0

MANIFEST=$(cat "$STATE")
LOGTAIL=""
[ -s "$CWD/.agentNotes/chain-log.jsonl" ] && LOGTAIL=$(tail -3 "$CWD/.agentNotes/chain-log.jsonl")

jq -cn --arg m "$MANIFEST" --arg l "$LOGTAIL" '{
  hookSpecificOutput: {
    hookEventName: "PostCompact",
    additionalContext: (
      "A review chain is in flight. Chain manifest (.agentNotes/chain-state.json):\n"
      + $m
      + (if $l != "" then "\nLast gate verdicts (chain-log.jsonl):\n" + $l else "" end)
      + "\nResume with the first agent in `chain` that is not yet in `done`. Protocol: CLAUDE.md -> Chain state manifest."
    )
  }
}'
exit 0
