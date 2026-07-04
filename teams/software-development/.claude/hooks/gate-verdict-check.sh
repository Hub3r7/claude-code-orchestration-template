#!/bin/bash
# SubagentStop hook: enforce the loop-back protocol mechanically.
# Matched on review agents (quality-gate|hunter|defender) in settings.json.
#
# Two jobs:
#   1. A review agent may not finish without an explicit verdict (or a BLOCKED
#      section) in its final message — otherwise it is sent back to emit one.
#   2. Verdicts update the circuit-breaker state in .agentNotes/chain-state.json:
#      FAIL increments the agent's counter, PASS resets it. The PreToolUse
#      circuit breaker (chain-circuit-breaker.sh) reads these counters.
#
# The verdict must be in the LAST assistant message (protocol: verdict before
# HANDOFF), so earlier mentions of the protocol text don't count as a verdict.

INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_type // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.agent_transcript_path // .transcript_path // empty')
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

case "$AGENT" in
  quality-gate|hunter|defender) ;;
  *) exit 0 ;;
esac

# No readable transcript → never false-block.
[ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ] || exit 0

FINAL=$(jq -rs '
  [ .[] | select(.type=="assistant") | .message.content
    | if type=="array" then (map(select(.type=="text") | .text) | join("\n"))
      elif type=="string" then .
      else empty end
  ] | map(select(length>0)) | last // ""
' "$TRANSCRIPT" 2>/dev/null)

# Tolerate markdown around the verdict: "VERDICT: PASS", "**VERDICT:** FAIL", …
VERDICT=$(echo "$FINAL" | grep -oE 'VERDICT[^A-Za-z0-9]{1,8}(PASS|FAIL)' | tail -1 | grep -oE '(PASS|FAIL)$')

if [ -z "$VERDICT" ]; then
  # A BLOCKED section is a legitimate terminal state (agent cannot proceed).
  if echo "$FINAL" | grep -qE '^#{1,3}\s*BLOCKED'; then
    exit 0
  fi
  # Already forced to continue once — don't loop forever.
  if [ "$STOP_ACTIVE" = "true" ]; then
    exit 0
  fi
  echo "Review protocol: you must end with an explicit verdict. Emit 'VERDICT: PASS' or 'VERDICT: FAIL — returning to <agent>' (with a numbered remediation list on FAIL), or a '## BLOCKED' section if you cannot proceed." >&2
  exit 2
fi

STATE_DIR="$CWD/.agentNotes"
STATE="$STATE_DIR/chain-state.json"
mkdir -p "$STATE_DIR"
[ -s "$STATE" ] || echo '{"fail_counts":{}}' > "$STATE"

if [ "$VERDICT" = "FAIL" ]; then
  jq --arg a "$AGENT" '.fail_counts[$a] = ((.fail_counts[$a] // 0) + 1)' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
else
  jq --arg a "$AGENT" '.fail_counts[$a] = 0' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
fi

# Outcome log: append-only verdict history. This is the evidence side of the
# framework — review it periodically to see whether gates catch real issues.
printf '{"ts":"%s","agent":"%s","verdict":"%s"}\n' \
  "$(date -u +%FT%TZ)" "$AGENT" "$VERDICT" >> "$STATE_DIR/chain-log.jsonl"

exit 0
