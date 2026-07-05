#!/usr/bin/env bash
# Smoke tests for the hook suite (PreToolUse, PostToolUse, PostToolUseFailure,
# SubagentStop, Stop, and the SessionStart/UserPromptSubmit/PostCompact
# orientation events). Verifies each hook blocks (exit 2) what it should and
# passes (exit 0) what it shouldn't, and that the verdict hook maintains
# circuit-breaker state correctly.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/template/.claude/hooks"
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
  "git -C repo push --force" \
  "git -c user.name=x push -f" \
  "git reset --hard HEAD~1" \
  "git -C /tmp/repo reset --hard" \
  "git checkout ." \
  "git checkout -- ." \
  "git restore ." \
  "git clean -f" \
  "git clean -xdf" \
  "git branch -D foo" \
  "git branch --delete --force foo" \
  "git stash drop" \
  "git stash clear" \
  "git reflog expire --expire=now --all" \
  "rm -rf build" \
  "rm -fr build" \
  "rm -r -f build" \
  "rm -f -r build" \
  "sudo rm -rf /tmp/x" \
  "echo done && rm -rf dist" \
  "find . -name '*.tmp' -delete" \
  "find . -name '*.o' -exec rm {} \;"; do
  check 2 "$(run_hook "$cmd")" "$cmd"
done

# Must PASS (exit 0)
for cmd in \
  "git push origin main" \
  "git push -u origin main" \
  "git push --follow-tags" \
  "git -C repo push origin main" \
  "git status" \
  "git checkout main" \
  "git checkout .github/workflows/ci.yml" \
  "git branch -d merged" \
  "git clean -n" \
  "git stash" \
  "git stash pop" \
  "git stash list" \
  "git reflog" \
  "rm file.txt" \
  "rm -r dir" \
  "rm -f stale.lock" \
  "find . -name '*.py'" \
  "find . -type f -exec grep -l TODO {} \;" \
  "ls -laf" \
  "npm run perf" \
  "git log --format=+%h"; do
  check 0 "$(run_hook "$cmd")" "$cmd"
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

# Outcome log: every verdict above was appended to chain-log.jsonl.
LOG="$WORK/.agentNotes/chain-log.jsonl"
check 7 "$(wc -l < "$LOG" | tr -d ' ')" "chain log has one line per verdict"
check FAIL "$(tail -1 "$LOG" | jq -r .verdict)" "chain log records the last verdict"
check defender "$(tail -1 "$LOG" | jq -r .agent)" "chain log records the agent"

# ---------------------------------------------------------------------------
# notes-persist.sh (PostToolUse on Agent/Task)
# ---------------------------------------------------------------------------
NOTES_HOOK="$HOOKS_DIR/notes-persist.sh"
echo "Hook: $NOTES_HOOK"

run_notes_str() {
  # $1 = tool_name, $2 = subagent_type, $3 = tool_response as plain string
  jq -cn --arg n "$1" --arg s "$2" --arg r "$3" --arg c "$WORK" \
    '{tool_name:$n,tool_input:{subagent_type:$s},cwd:$c,tool_response:$r}' \
    | bash "$NOTES_HOOK" >/dev/null 2>&1
  echo $?
}

run_notes_obj() {
  # $1 = subagent_type, $2 = text inside a content array
  jq -cn --arg s "$1" --arg t "$2" --arg c "$WORK" \
    '{tool_name:"Agent",tool_input:{subagent_type:$s},cwd:$c,tool_response:{content:[{type:"text",text:$t}]}}' \
    | bash "$NOTES_HOOK" >/dev/null 2>&1
  echo $?
}

with_notes="## RESULT
done

## NOTES UPDATE
- open finding: parser edge case
- reviewed: src/api.ts

## HANDOFF
- To: docs"

check 0 "$(run_notes_str Agent critic "$with_notes")" "notes section persisted (string response)"
if ! grep -q "parser edge case" "$WORK/.agentNotes/critic/notes.md" 2>/dev/null; then
  echo "  FAIL: critic notes not written from string response"; fail=1
fi
if grep -q "HANDOFF\|To: docs" "$WORK/.agentNotes/critic/notes.md" 2>/dev/null; then
  echo "  FAIL: notes extraction leaked past the section boundary"; fail=1
fi

check 0 "$(run_notes_obj optimizer "$with_notes")" "notes section persisted (content-array response)"
if ! grep -q "parser edge case" "$WORK/.agentNotes/optimizer/notes.md" 2>/dev/null; then
  echo "  FAIL: optimizer notes not written from content-array response"; fail=1
fi

check 0 "$(run_notes_str Agent hunter "just a normal answer, no section")" "no section → no write"
if [ -f "$WORK/.agentNotes/hunter/notes.md" ]; then
  echo "  FAIL: notes file created despite missing NOTES UPDATE section"; fail=1
fi

check 0 "$(run_notes_str Agent "../evil" "$with_notes")" "path-unsafe agent name ignored"
if [ -e "$WORK/.agentNotes/../evil" ] || [ -e "$WORK/evil" ]; then
  echo "  FAIL: unsafe agent name reached the filesystem"; fail=1
fi

check 0 "$(run_notes_str Bash critic "$with_notes")" "non-Agent tool ignored"

# ---------------------------------------------------------------------------
# orchestrator-scope.sh (PreToolUse on Edit|Write|NotebookEdit)
# ---------------------------------------------------------------------------
SCOPE_HOOK="$HOOKS_DIR/orchestrator-scope.sh"
echo "Hook: $SCOPE_HOOK"

run_scope() {
  # $1 = tool_name, $2 = file_path, $3 = agent_type ("" for main session)
  jq -cn --arg n "$1" --arg f "$2" --arg a "$3" --arg c "$WORK" \
    '{tool_name:$n,tool_input:{file_path:$f},cwd:$c}
     + (if $a != "" then {agent_type:$a} else {} end)' \
    | bash "$SCOPE_HOOK" >/dev/null 2>&1
  echo $?
}

check 2 "$(run_scope Write "$WORK/src/main.py" "")" "orchestrator blocked from project code"
check 2 "$(run_scope Edit "README.md" "")" "orchestrator blocked from project docs"
check 0 "$(run_scope Write "$WORK/CLAUDE.md" "")" "CLAUDE.md is meta-config"
check 0 "$(run_scope Edit "$WORK/.claude/agents/developer.md" "")" "agent files are meta-config"
check 0 "$(run_scope Write "$WORK/.agentNotes/chain-state.json" "")" "chain state is meta-config"
check 0 "$(run_scope Edit "$WORK/docs/project-rules.md" "")" "project-rules.md is meta-config"
check 0 "$(run_scope Write "/tmp/scratch.txt" "")" "paths outside the project pass"
check 0 "$(run_scope Write "$WORK/src/main.py" "developer")" "subagents are exempt"
check 0 "$(run_scope Grep "$WORK/src/main.py" "")" "non-watched tool ignored"

# Bash branch: shell write forms against existing project files.
run_scope_bash() {
  # $1 = command string, $2 = agent_type ("" for main session)
  jq -cn --arg c "$1" --arg a "$2" --arg w "$WORK" \
    '{tool_name:"Bash",tool_input:{command:$c},cwd:$w}
     + (if $a != "" then {agent_type:$a} else {} end)' \
    | bash "$SCOPE_HOOK" >/dev/null 2>&1
  echo $?
}

mkdir -p "$WORK/src" && echo "x = 1" > "$WORK/src/app.py"

check 2 "$(run_scope_bash "echo hacked > src/app.py" "")" "redirect into existing project file blocked"
check 2 "$(run_scope_bash "python3 gen.py >> src/app.py" "")" "append into existing project file blocked"
check 2 "$(run_scope_bash "sed -i 's/x/y/' src/app.py" "")" "sed -i on existing project file blocked"
check 2 "$(run_scope_bash "cat patch | tee src/app.py" "")" "tee into existing project file blocked"
check 0 "$(run_scope_bash "echo hacked > src/app.py" "developer")" "subagent shell writes are exempt"
check 0 "$(run_scope_bash "echo x > /tmp/scratch.txt" "")" "shell write outside project passes"
check 0 "$(run_scope_bash "echo '{}' > .agentNotes/chain-state.json" "")" "shell write to meta-config passes"
check 0 "$(run_scope_bash "python3 -m unittest > new-report.txt" "")" "redirect to a NEW file passes"
check 0 "$(run_scope_bash "grep -n foo src/app.py" "")" "read-only shell command passes"
check 0 "$(run_scope_bash "echo warn >&2 && git status 2>/dev/null" "")" "fd/devnull redirects pass"

# Enforcement-layer carve-out: hooks/settings must go through Edit/Write so the
# permissions ask-gate applies — shell writes are blocked even for NEW files.
check 2 "$(run_scope_bash "echo x > .claude/hooks/new-hook.sh" "")" "shell write into .claude/hooks blocked (even new files)"
check 2 "$(run_scope_bash "sed -i 's/a/b/' .claude/settings.json" "")" "shell edit of settings.json blocked"
check 2 "$(run_scope_bash "cat x | tee .claude/settings.local.json" "")" "tee into settings.local.json blocked"
check 0 "$(run_scope_bash "echo x > .claude/agents/foo.md" "")" "non-enforcement meta-config shell write passes"

# ---------------------------------------------------------------------------
# chain-orient.sh (SessionStart / UserPromptSubmit / PostCompact)
# ---------------------------------------------------------------------------
ORIENT_HOOK="$HOOKS_DIR/chain-orient.sh"
echo "Hook: $ORIENT_HOOK"

run_orient() {
  # $1 = hook_event_name
  jq -cn --arg c "$WORK" --arg e "$1" '{cwd:$c,hook_event_name:$e}' \
    | bash "$ORIENT_HOOK" 2>/dev/null
}

rm -f "$STATE"
for ev in PostCompact SessionStart UserPromptSubmit; do
  if [ -n "$(run_orient "$ev")" ]; then
    echo "  FAIL: $ev emitted output with no chain state"; fail=1
  fi
done

echo '{"task":"t","tier":3,"chain":["architect","developer","docs"],"done":["architect"],"fail_counts":{}}' > "$STATE"
for ev in PostCompact SessionStart; do
  OUT="$(run_orient "$ev")"
  if ! printf '%s' "$OUT" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
    echo "  FAIL: $ev did not emit additionalContext for an unfinished chain"; fail=1
  elif ! printf '%s' "$OUT" | grep -q "architect"; then
    echo "  FAIL: $ev context does not carry the manifest"; fail=1
  elif [ "$(printf '%s' "$OUT" | jq -r '.hookSpecificOutput.hookEventName')" != "$ev" ]; then
    echo "  FAIL: $ev echoed the wrong hookEventName"; fail=1
  fi
done

OUT="$(run_orient UserPromptSubmit)"
if ! printf '%s' "$OUT" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  echo "  FAIL: UserPromptSubmit did not emit a reminder for an unfinished chain"; fail=1
elif ! printf '%s' "$OUT" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "next: developer"; then
  echo "  FAIL: UserPromptSubmit reminder does not name the next agent"; fail=1
elif [ "$(printf '%s' "$OUT" | jq -r '.hookSpecificOutput.additionalContext' | wc -l | tr -d ' ')" != "1" ]; then
  echo "  FAIL: UserPromptSubmit reminder is not a single line"; fail=1
fi

echo '{"task":"t","tier":1,"chain":["developer","docs"],"done":["developer","docs"],"fail_counts":{}}' > "$STATE"
for ev in PostCompact SessionStart UserPromptSubmit; do
  if [ -n "$(run_orient "$ev")" ]; then
    echo "  FAIL: $ev emitted output for a finished chain"; fail=1
  fi
done

# ---------------------------------------------------------------------------
# stop-chain-guard.sh (Stop)
# ---------------------------------------------------------------------------
STOP_HOOK="$HOOKS_DIR/stop-chain-guard.sh"
echo "Hook: $STOP_HOOK"

run_stop() {
  # $1 = stop_hook_active
  jq -cn --arg c "$WORK" --argjson s "$1" '{cwd:$c,stop_hook_active:$s}' \
    | bash "$STOP_HOOK" >/dev/null 2>&1
  echo $?
}

rm -f "$STATE"
check 0 "$(run_stop false)" "no chain state → stop passes"

echo '{"task":"t","tier":2,"chain":["architect","quality-gate","developer","quality-gate","docs"],"done":["architect"],"fail_counts":{}}' > "$STATE"
check 2 "$(run_stop false)" "unfinished chain blocks the first stop"
check 0 "$(run_stop true)" "stop_hook_active lets the second stop through (no loop)"

echo '{"task":"t","tier":2,"chain":["architect","developer"],"done":["architect"],"fail_counts":{"quality-gate":3}}' > "$STATE"
check 0 "$(run_stop false)" "tripped circuit breaker exempts the escalation pause"

echo '{"task":"t","tier":1,"chain":["developer","docs"],"done":["developer","docs"],"fail_counts":{}}' > "$STATE"
check 0 "$(run_stop false)" "finished chain → stop passes"

echo 'not json' > "$STATE"
check 0 "$(run_stop false)" "malformed manifest never blocks a stop"

# ---------------------------------------------------------------------------
# tool-failure-log.sh (PostToolUseFailure on Agent/Task)
# ---------------------------------------------------------------------------
FAILLOG_HOOK="$HOOKS_DIR/tool-failure-log.sh"
echo "Hook: $FAILLOG_HOOK"

run_faillog() {
  # $1 = tool_name, $2 = subagent_type, $3 = error text
  jq -cn --arg n "$1" --arg s "$2" --arg e "$3" --arg c "$WORK" \
    '{tool_name:$n,tool_input:{subagent_type:$s},cwd:$c,error:$e}' \
    | bash "$FAILLOG_HOOK" >/dev/null 2>&1
  echo $?
}

LOG_BEFORE="$(wc -l < "$LOG" | tr -d ' ')"
check 0 "$(run_faillog Agent developer "InputValidationError: unexpected field")" "agent failure logged"
check "$((LOG_BEFORE + 1))" "$(wc -l < "$LOG" | tr -d ' ')" "failure appended one log line"
check tool_failure "$(tail -1 "$LOG" | jq -r .event)" "failure line carries the event type"
check developer "$(tail -1 "$LOG" | jq -r .agent)" "failure line carries the agent"
check 0 "$(run_faillog Bash developer "boom")" "non-Agent failure ignored"
check "$((LOG_BEFORE + 1))" "$(wc -l < "$LOG" | tr -d ' ')" "non-Agent failure not logged"

# ---------------------------------------------------------------------------
# statusline-chain.sh
# ---------------------------------------------------------------------------
SL_HOOK="$HOOKS_DIR/statusline-chain.sh"
echo "Hook: $SL_HOOK"

run_statusline() {
  jq -cn --arg c "$WORK" '{cwd:$c,model:{display_name:"TestModel"}}' | bash "$SL_HOOK" 2>/dev/null
}

echo '{"task":"t","tier":3,"chain":["architect","developer","docs"],"done":["architect"],"fail_counts":{"quality-gate":1}}' > "$STATE"
OUT="$(run_statusline)"
case "$OUT" in
  *T3*1/3*next:\ developer*FAIL\ quality-gate:1*) ;;
  *) echo "  FAIL: statusline for in-flight chain rendered: '$OUT'"; fail=1 ;;
esac

rm -f "$STATE"
check TestModel "$(run_statusline)" "statusline falls back to model name"

# ---------------------------------------------------------------------------
# chain.sh (canonical manifest writer)
# ---------------------------------------------------------------------------
CHAIN="$REPO_ROOT/template/.claude/scripts/chain.sh"
echo "Script: $CHAIN"

run_chain() { (cd "$WORK" && bash "$CHAIN" "$@") >/dev/null 2>&1; echo $?; }

rm -f "$STATE"
check 1 "$(run_chain advance developer)" "advance without a manifest fails"
check 0 "$(run_chain init 1 "fix bug" developer quality-gate docs)" "init writes a fresh manifest"
check 1 "$(run_chain init 1 "another" developer)" "init refuses while a chain is in flight"
check developer "$(jq -r '.chain[0]' "$STATE")" "manifest records the chain"
check 1 "$(run_chain advance quality-gate)" "advance out of order fails"
check 0 "$(run_chain advance developer)" "advance in order passes"
check 1 "$(run_chain complete)" "complete refuses an unfinished chain"
run_chain advance quality-gate >/dev/null
run_chain advance docs >/dev/null
check 0 "$(run_chain complete)" "complete passes when all positions are done"
check chain_complete "$(tail -1 "$LOG" | jq -r .event)" "chain_complete logged"
check 0 "$(run_chain init 2 "task2" architect developer)" "init allowed after complete"
check 0 "$(run_chain reset quality-gate)" "reset zeroes a gate counter"
check 0 "$(run_chain abandon "scope changed")" "abandon logs and clears state"
check chain_abandoned "$(tail -1 "$LOG" | jq -r .event)" "chain_abandoned logged with reason"
if [ -e "$STATE" ]; then echo "  FAIL: abandon left the manifest behind"; fail=1; fi
check 0 "$(run_chain show)" "show works with no chain in flight"

# ---------------------------------------------------------------------------
# doctor.sh (fresh-install verification)
# ---------------------------------------------------------------------------
DOCTOR="$REPO_ROOT/template/.claude/scripts/doctor.sh"
echo "Script: $DOCTOR"

INSTALL="$(mktemp -d)"
cp "$REPO_ROOT/template/CLAUDE.md" "$INSTALL/"
cp -r "$REPO_ROOT/template/.claude" "$INSTALL/"
cp "$INSTALL/.claude/settings.template.json" "$INSTALL/.claude/settings.json"
if ! (cd "$INSTALL" && bash .claude/scripts/doctor.sh >/dev/null 2>&1); then
  echo "  FAIL: doctor reports problems on a clean template install"; fail=1
fi
rm -f "$INSTALL/.claude/settings.json"
if (cd "$INSTALL" && bash .claude/scripts/doctor.sh >/dev/null 2>&1); then
  echo "  FAIL: doctor passed without settings.json (hooks inactive)"; fail=1
fi
rm -rf "$INSTALL"

if [ "$fail" -eq 0 ]; then
  echo "Hook tests OK."
else
  echo "Hook tests FAILED."
fi
exit "$fail"
