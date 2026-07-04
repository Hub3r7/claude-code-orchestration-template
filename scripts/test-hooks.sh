#!/usr/bin/env bash
# Smoke tests for the PreToolUse/SubagentStop hooks.
# Verifies each hook blocks (exit 2) what it should and passes (exit 0) what it
# shouldn't, that the verdict hook maintains circuit-breaker state correctly,
# and that all four teams ship an identical destructive-git hook.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/teams/software-development/.claude/hooks"
HOOK="$HOOKS_DIR/block-destructive-git.sh"
VERDICT_HOOK="$HOOKS_DIR/gate-verdict-check.sh"
BREAKER_HOOK="$HOOKS_DIR/chain-circuit-breaker.sh"

fail=0

check() {
  # $1 = expected exit code, $2 = got, $3 = label
  if [ "$2" != "$1" ]; then
    echo "  FAIL: expected exit $1, got $2 for: $3"
    fail=1
  fi
}

# ---------------------------------------------------------------------------
# block-destructive-git.sh
# ---------------------------------------------------------------------------
echo "Hook: $HOOK"

run_hook() {
  jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK" >/dev/null 2>&1
  echo $?
}

# Must BLOCK (exit 2)
for cmd in \
  "git push --force" \
  "git push -f" \
  "git push origin main -f" \
  "git push origin +main" \
  "git push --force-with-lease" \
  "git push --no-verify --force" \
  "git reset --hard HEAD~1" \
  "git checkout ." \
  "git checkout -- ." \
  "git restore ." \
  "git clean -f" \
  "git clean -xdf" \
  "git branch -D foo" \
  "git branch --delete --force foo" \
  "rm -rf build" \
  "rm -fr build" \
  "sudo rm -rf /tmp/x" \
  "echo done && rm -rf dist"; do
  check 2 "$(run_hook "$cmd")" "$cmd"
done

# Must PASS (exit 0)
for cmd in \
  "git push origin main" \
  "git push -u origin main" \
  "git push --follow-tags" \
  "git status" \
  "git checkout main" \
  "git checkout .github/workflows/ci.yml" \
  "git branch -d merged" \
  "git clean -n" \
  "rm file.txt" \
  "rm -r dir" \
  "ls -laf" \
  "npm run perf" \
  "git log --format=+%h"; do
  check 0 "$(run_hook "$cmd")" "$cmd"
done

# All four teams must ship an identical destructive-git hook.
echo "Checking destructive-git hook is identical across all teams..."
ref_sum="$(md5sum "$HOOK" | awk '{print $1}')"
for h in "$REPO_ROOT"/teams/*/.claude/hooks/block-destructive-git.sh; do
  sum="$(md5sum "$h" | awk '{print $1}')"
  if [ "$sum" != "$ref_sum" ]; then
    echo "  FAIL: $h differs from software-development copy"
    fail=1
  fi
done

# ---------------------------------------------------------------------------
# gate-verdict-check.sh (SubagentStop)
# ---------------------------------------------------------------------------
echo "Hook: $VERDICT_HOOK"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STATE="$WORK/.agentNotes/chain-state.json"

mk_transcript() {
  # $1 = final assistant text; echoes transcript path
  local f="$WORK/transcript-$RANDOM.jsonl"
  jq -cn --arg t "$1" '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' > "$f"
  echo "$f"
}

run_verdict() {
  # $1 = agent_type, $2 = transcript path, $3 = stop_hook_active
  jq -cn --arg a "$1" --arg t "$2" --arg c "$WORK" --argjson s "$3" \
    '{agent_type:$a,agent_transcript_path:$t,cwd:$c,stop_hook_active:$s}' \
    | bash "$VERDICT_HOOK" >/dev/null 2>&1
  echo $?
}

fail_count() {
  jq -r --arg a "$1" '.fail_counts[$a] // 0' "$STATE" 2>/dev/null || echo "missing"
}

t_pass="$(mk_transcript "## RESULT
All good.

VERDICT: PASS

### HANDOFF
- To: docs")"
t_fail="$(mk_transcript "Issues found.

**VERDICT:** FAIL — returning to developer

1. Fix input validation")"
t_none="$(mk_transcript "Here is my review summary without a final call.")"
t_blocked="$(mk_transcript "## BLOCKED

- Reason: design spec missing")"

check 0 "$(run_verdict quality-gate "$t_pass" false)" "verdict PASS passes"
check 0 "$(fail_count quality-gate)" "PASS resets/keeps counter at 0"
check 0 "$(run_verdict quality-gate "$t_fail" false)" "verdict FAIL passes (counted, not blocked)"
check 1 "$(fail_count quality-gate)" "FAIL increments counter to 1"
check 0 "$(run_verdict quality-gate "$t_fail" false)" "second FAIL passes"
check 2 "$(fail_count quality-gate)" "second FAIL increments counter to 2"
check 0 "$(run_verdict quality-gate "$t_pass" false)" "PASS after FAILs passes"
check 0 "$(fail_count quality-gate)" "PASS resets counter to 0"
check 2 "$(run_verdict quality-gate "$t_none" false)" "missing verdict is blocked"
check 0 "$(run_verdict quality-gate "$t_none" true)" "missing verdict passes when stop_hook_active (no loop)"
check 0 "$(run_verdict hunter "$t_blocked" false)" "BLOCKED section is a valid terminal state"
check 0 "$(run_verdict developer "$t_none" false)" "non-review agent ignored"
check 0 "$(run_verdict quality-gate "$WORK/nonexistent.jsonl" false)" "unreadable transcript never blocks"

# ---------------------------------------------------------------------------
# chain-circuit-breaker.sh (PreToolUse on Agent/Task)
# ---------------------------------------------------------------------------
echo "Hook: $BREAKER_HOOK"

run_breaker() {
  # $1 = tool_name, $2 = subagent_type
  jq -cn --arg n "$1" --arg s "$2" --arg c "$WORK" \
    '{tool_name:$n,tool_input:{subagent_type:$s},cwd:$c}' \
    | bash "$BREAKER_HOOK" >/dev/null 2>&1
  echo $?
}

rm -f "$STATE"
check 0 "$(run_breaker Agent quality-gate)" "no state file passes"

echo '{"fail_counts":{"quality-gate":2,"hunter":3}}' > "$STATE"
check 0 "$(run_breaker Agent quality-gate)" "2 FAILs still passes"
check 2 "$(run_breaker Agent hunter)" "3 FAILs blocks the gate (Agent)"
check 2 "$(run_breaker Task hunter)" "3 FAILs blocks the gate (Task alias)"
check 0 "$(run_breaker Agent developer)" "non-gate subagent passes"
check 0 "$(run_breaker Bash hunter)" "non-Agent tool ignored"

# End-to-end: three FAIL verdicts trip the breaker for that gate.
rm -f "$STATE"
run_verdict defender "$t_fail" false >/dev/null
run_verdict defender "$t_fail" false >/dev/null
run_verdict defender "$t_fail" false >/dev/null
check 2 "$(run_breaker Agent defender)" "three recorded FAILs trip the breaker"
check 0 "$(run_breaker Agent quality-gate)" "other gates unaffected"

if [ "$fail" -eq 0 ]; then
  echo "Hook tests OK."
else
  echo "Hook tests FAILED."
fi
exit "$fail"
