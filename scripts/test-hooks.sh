#!/usr/bin/env bash
# Smoke tests for the destructive-git PreToolUse hook.
# Verifies the hook blocks (exit 2) what it should and lets safe commands pass (exit 0),
# and that all four teams ship an identical copy.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO_ROOT/teams/software-development/.claude/hooks/block-destructive-git.sh"

fail=0

run_hook() {
  # $1 = command string under test; echoes the hook's exit code
  jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK" >/dev/null 2>&1
  echo $?
}

expect() {
  # $1 = expected exit code, $2 = command
  local got
  got="$(run_hook "$2")"
  if [ "$got" != "$1" ]; then
    echo "  FAIL: expected exit $1, got $got for: $2"
    fail=1
  fi
}

echo "Hook: $HOOK"

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
  expect 2 "$cmd"
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
  expect 0 "$cmd"
done

# All four teams must ship an identical hook.
echo "Checking hook is identical across all teams..."
ref_sum="$(md5sum "$HOOK" | awk '{print $1}')"
for h in "$REPO_ROOT"/teams/*/.claude/hooks/block-destructive-git.sh; do
  sum="$(md5sum "$h" | awk '{print $1}')"
  if [ "$sum" != "$ref_sum" ]; then
    echo "  FAIL: $h differs from software-development copy"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "Hook tests OK."
else
  echo "Hook tests FAILED."
fi
exit "$fail"
