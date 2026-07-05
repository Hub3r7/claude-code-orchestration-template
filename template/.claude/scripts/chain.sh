#!/bin/bash
# chain.sh — the canonical writer for the chain manifest (.agentNotes/chain-state.json).
#
# The orchestrator drives the review chain through these commands instead of
# hand-editing JSON: one writer keeps the format canonical for every reader
# (statusline, chain-orient, circuit breaker, stop guard) and works the same
# for any orchestrating model. Hooks own fail_counts (the verdict hook
# increments, PASS resets); this script touches them only at init and on an
# explicit, user-approved reset.
#
#   chain.sh init <tier> "<task>" <agent> [<agent>...]   start a fresh chain
#   chain.sh advance <agent>     mark the next position done (must match order)
#   chain.sh complete            verify all positions done + log chain_complete
#   chain.sh abandon "<reason>"  log chain_abandoned + remove the manifest
#   chain.sh reset <gate>        zero a gate's FAIL counter (after user approval)
#   chain.sh show                print the manifest + recent log lines
#
# Exit 0 = ok, 1 = usage/state error (message on stderr). Hand-editing the JSON
# remains a fallback when this script is unavailable — same schema.

set -u
CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
NOTES="$CWD/.agentNotes"
STATE="$NOTES/chain-state.json"
LOG="$NOTES/chain-log.jsonl"

die() { echo "chain: $*" >&2; exit 1; }
need_state() {
  [ -s "$STATE" ] || die "no chain manifest at $STATE"
  jq -e . "$STATE" >/dev/null 2>&1 || die "manifest is not valid JSON: $STATE"
}

CMD="${1:-}"; [ $# -gt 0 ] && shift
case "$CMD" in
  init)
    [ $# -ge 3 ] || die 'usage: chain.sh init <tier> "<task>" <agent> [<agent>...]'
    TIER="${1#T}"; TASK="$2"; shift 2
    case "$TIER" in 0|1|2|3|4) ;; *) die "tier must be 0-4 (got '$TIER')" ;; esac
    if [ -s "$STATE" ] && jq -e '(.chain | length) > (.done | length)' "$STATE" >/dev/null 2>&1; then
      die "a chain is already in flight — 'complete' or 'abandon' it first (see 'show')"
    fi
    mkdir -p "$NOTES"
    jq -cn --arg task "$TASK" --argjson tier "$TIER" \
      '{task: $task, tier: $tier, chain: $ARGS.positional, done: [],
        fail_counts: {}, started: (now | todate)}' --args "$@" > "$STATE"
    echo "chain: T$TIER started with $# position(s): $*"
    ;;
  advance)
    [ $# -eq 1 ] || die "usage: chain.sh advance <agent>"
    need_state
    EXPECTED=$(jq -r '(.chain // [])[((.done // []) | length)] // ""' "$STATE")
    [ -n "$EXPECTED" ] || die "all positions already done — use 'complete'"
    [ "$1" = "$EXPECTED" ] || die "next position is '$EXPECTED', not '$1' (a FAIL re-review loop does not advance until the gate passes)"
    TMP=$(mktemp) && jq --arg a "$1" '.done += [$a]' "$STATE" > "$TMP" && mv "$TMP" "$STATE"
    LEFT=$(jq -r '(.chain | length) - (.done | length)' "$STATE")
    echo "chain: $1 done, $LEFT position(s) left"
    ;;
  complete)
    need_state
    jq -e '(.done | length) == (.chain | length)' "$STATE" >/dev/null 2>&1 \
      || die "chain not finished — next position: $(jq -r '(.chain // [])[((.done // []) | length)] // "?"' "$STATE")"
    STARTED=$(jq -r '.started // ""' "$STATE")
    FAILS=$(jq -rs --arg s "$STARTED" '
      [.[] | select((.verdict? // "") == "FAIL")
           | select($s == "" or ((.ts? // "") >= $s))] | length
    ' "$LOG" 2>/dev/null) || FAILS=0
    [ -n "$FAILS" ] || FAILS=0
    jq -c --arg f "$FAILS" \
      '{ts: (now | todate), event: "chain_complete", tier: .tier, task: .task,
        fails: ($f | tonumber)}' "$STATE" >> "$LOG"
    echo "chain: complete — T$(jq -r .tier "$STATE"), $FAILS FAIL iteration(s) on the way (logged)"
    ;;
  abandon)
    [ $# -ge 1 ] || die 'usage: chain.sh abandon "<reason>"'
    need_state
    jq -c --arg r "$*" \
      '{ts: (now | todate), event: "chain_abandoned", tier: .tier, task: .task,
        done: (.done | length), of: (.chain | length), reason: $r}' "$STATE" >> "$LOG"
    rm -f "$STATE"
    echo "chain: abandoned and logged — reason: $*"
    ;;
  reset)
    [ $# -eq 1 ] || die "usage: chain.sh reset <gate>"
    need_state
    TMP=$(mktemp) && jq --arg g "$1" '.fail_counts[$g] = 0' "$STATE" > "$TMP" && mv "$TMP" "$STATE"
    echo "chain: FAIL counter for '$1' reset to 0"
    ;;
  show)
    if [ ! -s "$STATE" ]; then
      echo "chain: no chain in flight"
    else
      jq . "$STATE" 2>/dev/null || echo "chain: manifest is not valid JSON: $STATE"
    fi
    if [ -s "$LOG" ]; then
      echo "--- last chain-log lines:"
      tail -5 "$LOG"
    fi
    ;;
  *)
    die "unknown command '${CMD:-}' — use init|advance|complete|abandon|reset|show"
    ;;
esac
exit 0
