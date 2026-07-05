#!/bin/bash
# PreToolUse hook: block destructive operations unless explicitly approved.
# Reads JSON from stdin (Claude Code hook contract).
#
# Patterns deliberately match flags anywhere in the command segment (not just
# immediately after the subcommand) and cover short/combined flag forms —
# `git push origin main -f` is just as destructive as `git push --force`.
# Git global options between `git` and the subcommand (`git -C repo push -f`,
# `git -c a=b reset --hard`) are covered by the $G prefix.

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

# git, optionally followed by global options (-C <path>, -c <kv>, --git-dir=…,
# --work-tree=…), then the subcommand.
G='git(\s+-[cC]\s+\S+|\s+--(git-dir|work-tree)(=|\s+)\S+)*\s+'

# Force push: --force / --force-with-lease, short -f (incl. combined, e.g. -uf),
# or force-via-refspec (git push origin +main).
if echo "$COMMAND" | grep -qE "${G}push[^|&;]*(\s--force(-with-lease)?\b|\s-[a-zA-Z]*f|\s\+\S+)"; then
  block "force push"
fi

# Discarding local changes: reset --hard, checkout/restore of the whole tree.
if echo "$COMMAND" | grep -qE "${G}reset\s+--hard|${G}(checkout|restore)\s+(--\s+)?\.(\s|$)"; then
  block "discarding local changes"
fi

# git clean with -f anywhere in the flags (e.g. -f, -fd, -xdf).
if echo "$COMMAND" | grep -qE "${G}clean[^|&;]*\s-[a-zA-Z]*f"; then
  block "git clean"
fi

# Force branch deletion: -D (incl. combined), or --delete + --force in any order.
if echo "$COMMAND" | grep -qE "${G}branch[^|&;]*\s(-[a-zA-Z]*D|--delete[^|&;]*\s--force\b|--force[^|&;]*\s--delete\b)"; then
  block "force branch deletion"
fi

# Destroying stashed or unreachable work: stash drop/clear, reflog expire
# (the classic prelude to making a reset --hard unrecoverable).
if echo "$COMMAND" | grep -qE "${G}stash\s+(drop|clear)\b|${G}reflog\s+expire\b"; then
  block "destroying stash/reflog history"
fi

# Recursive force delete: rm -rf / -fr (combined), long-form --recursive +
# --force in any order, or the SEPARATED short flags (rm -r -f, rm -f -r).
if echo "$COMMAND" | grep -qE '(^|[|&;[:space:]])rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[a-zA-Z]*\b|(^|[|&;[:space:]])rm\s+[^|&;]*(--recursive[^|&;]*\s--force\b|--force[^|&;]*\s--recursive\b)'; then
  block "recursive force delete (rm -rf)"
fi
if echo "$COMMAND" | grep -qE '(^|[|&;[:space:]])rm\s+[^|&;]*(-[a-zA-Z]*r[a-zA-Z]*\s[^|&;]*-[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*\s[^|&;]*-[a-zA-Z]*r)'; then
  block "recursive force delete (rm -r -f, separated flags)"
fi

# Mass deletion via find: -delete, or -exec with rm.
if echo "$COMMAND" | grep -qE 'find\s+[^|&;]*-delete\b|find\s+[^|&;]*-exec\s+[^|&;]*\brm\b'; then
  block "mass delete via find"
fi

exit 0
