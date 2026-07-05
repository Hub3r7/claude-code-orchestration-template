#!/bin/bash
# Stop hook: the orchestrator must not silently end its turn mid-chain.
#
# The verdict hook keeps review agents honest; this keeps the ORCHESTRATOR
# honest. If .agentNotes/chain-state.json shows an unfinished chain, the first
# attempt to stop is blocked with the chain position — the orchestrator either
# continues the chain or states explicitly why it is pausing (waiting on the
# user, or abandoning: remove the manifest and say why). The second stop passes
# (stop_hook_active), so this can never loop. A tripped circuit breaker (any
# gate at 3+ FAILs) is exempt: escalating to the user IS the protocol there,
# and that pause must go through unimpeded.

INPUT=$(cat)

# Already continued once because of this hook → let the stop through.
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
STATE="$CWD/.agentNotes/chain-state.json"

[ -s "$STATE" ] || exit 0
jq -e . "$STATE" >/dev/null 2>&1 || exit 0

# Conservative default: a malformed manifest must not block stops.
UNFINISHED=$(jq -r '
  if (.chain | type == "array") and (.done | type == "array")
  then ((.done | length) < (.chain | length))
  else false end
' "$STATE")
[ "$UNFINISHED" = "true" ] || exit 0

# Circuit breaker tripped → the escalation pause is correct behavior.
TRIPPED=$(jq -r '[(.fail_counts // {}) | to_entries[] | select(.value >= 3)] | length' "$STATE")
[ "$TRIPPED" != "0" ] && exit 0

POS=$(jq -r '
  ((.done // []) | length | tostring) + "/" + ((.chain // []) | length | tostring)
  + ", next: " + ((.chain // [])[((.done // []) | length)] // "?")
' "$STATE")

echo "Chain in flight ($POS). Continue the chain, or state explicitly why you are pausing — waiting on user input, or abandoning the chain (then remove .agentNotes/chain-state.json and say why). A chain must not be left dangling silently." >&2
exit 2
