#!/bin/bash
# PreToolUse hook on Agent/Task: mechanical circuit breaker for review loops.
#
# gate-verdict-check.sh counts FAIL verdicts per review agent in
# .agentNotes/chain-state.json. Once a gate has issued 3 FAILs, this hook
# blocks the next invocation of that gate — the orchestrator cannot silently
# keep looping developer → gate and must escalate to the user instead
# (repeated FAILs signal a spec or design flaw, not an implementation slip).
#
# Counters reset on a PASS from the gate, or explicitly via
# `chain.sh reset <gate>` / `chain.sh abandon` after the user has decided how
# to proceed. Stale counters can only over-block (escalate one review too
# early), never under-block — the safe direction.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL" in
  Agent|Task) ;;
  *) exit 0 ;;
esac

SUBAGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')
case "$SUBAGENT" in
  quality-gate|hunter|defender) ;;
  *) exit 0 ;;
esac

CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
STATE="$CWD/.agentNotes/chain-state.json"
[ -s "$STATE" ] || exit 0

COUNT=$(jq -r --arg a "$SUBAGENT" '.fail_counts[$a] // 0' "$STATE")

if [ "$COUNT" -ge 3 ]; then
  echo "Circuit breaker: $SUBAGENT has issued FAIL $COUNT times on this work. Do not re-enter the review loop — escalate to the user with the outstanding findings (repeated FAILs signal unclear requirements or a design flaw). After the user decides: continue with 'bash .claude/scripts/chain.sh reset $SUBAGENT', or abandon with 'bash .claude/scripts/chain.sh abandon \"<reason>\"'." >&2
  exit 2
fi

exit 0
