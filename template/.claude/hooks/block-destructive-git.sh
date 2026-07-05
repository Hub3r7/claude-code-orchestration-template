#!/bin/bash
# PreToolUse hook: block destructive operations unless explicitly approved.
# Reads JSON from stdin (Claude Code hook contract).
#
# Patterns deliberately match flags anywhere in the command segment (not just
# immediately after the subcommand) and cover short/combined flag forms —
# `git push origin main -f` is just as destructive as `git push --force`.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

block() {
  echo "Blocked: $1 requires explicit user approval." >&2
  exit 2
}

# Force push: --force / --force-with-lease, short -f (incl. combined, e.g. -uf),
# or force-via-refspec (git push origin +main).
if echo "$COMMAND" | grep -qE 'git\s+push[^|&;]*(\s--force(-with-lease)?\b|\s-[a-zA-Z]*f|\s\+\S+)'; then
  block "force push"
fi

# Discarding local changes: reset --hard, checkout/restore of the whole tree.
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard|git\s+(checkout|restore)\s+(--\s+)?\.(\s|$)'; then
  block "discarding local changes"
fi

# git clean with -f anywhere in the flags (e.g. -f, -fd, -xdf).
if echo "$COMMAND" | grep -qE 'git\s+clean[^|&;]*\s-[a-zA-Z]*f'; then
  block "git clean"
fi

# Force branch deletion: -D (incl. combined), or --delete + --force in any order.
if echo "$COMMAND" | grep -qE 'git\s+branch[^|&;]*\s(-[a-zA-Z]*D|--delete[^|&;]*\s--force\b|--force[^|&;]*\s--delete\b)'; then
  block "force branch deletion"
fi

# Recursive force delete: rm -rf / -fr (incl. combined flags) or long-form
# --recursive + --force in any order.
if echo "$COMMAND" | grep -qE '(^|[|&;[:space:]])rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[a-zA-Z]*\b|(^|[|&;[:space:]])rm\s+[^|&;]*(--recursive[^|&;]*\s--force\b|--force[^|&;]*\s--recursive\b)'; then
  block "recursive force delete (rm -rf)"
fi

exit 0
