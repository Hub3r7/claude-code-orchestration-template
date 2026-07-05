#!/bin/bash
# PreToolUse hook on Edit|Write|NotebookEdit AND Bash: enforce the
# orchestrator's write scope.
#
# CLAUDE.md says the orchestrator never writes project files directly — it may
# only edit meta-configuration (CLAUDE.md, .claude/**, .agentNotes/**,
# docs/project-rules.md); code goes through developer, documentation through
# docs. This hook makes that rule mechanical for the MAIN session only:
# subagent tool calls carry agent_type/agent_id in the hook input and are
# exempt — their access is governed by their own frontmatter (and read-only
# agents already carry disallowedTools).
#
# The Bash branch exists because the first live test showed the model
# proposing to route around the Edit/Write block via shell ("the hook only
# watches Edit/Write"). It catches the common write forms — output
# redirection, tee, sed -i — when they target an EXISTING project file
# outside the meta-config allowlist. Best-effort by design: the full rule
# lives in CLAUDE.md, and routing around it is a protocol violation, not a
# loophole.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL" in
  Edit|Write|NotebookEdit|Bash) ;;
  *) exit 0 ;;
esac

# Subagent context → not the orchestrator.
AGENT=$(echo "$INPUT" | jq -r '.agent_type // .agent_id // empty')
[ -n "$AGENT" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# Sets REL_BLOCKED and returns 1 when the path is project content;
# returns 0 for meta-config or out-of-project paths.
path_allowed() {
  local f="$1" rel
  case "$f" in
    "$CWD"/*) rel="${f#"$CWD"/}" ;;
    /*) return 0 ;;
    *) rel="$f" ;;
  esac
  case "$rel" in
    CLAUDE.md|.claude/*|.agentNotes/*|docs/project-rules.md) return 0 ;;
  esac
  REL_BLOCKED="$rel"
  return 1
}

block() {
  echo "Orchestrator scope: '$1' is project content, not meta-configuration. Delegate the change — developer for code, docs for documentation. The orchestrator may write only CLAUDE.md, .claude/**, .agentNotes/**, and docs/project-rules.md. Do not route around this via shell redirection, tee, sed -i, or heredocs — same rule, same reason." >&2
  exit 2
}

if [ "$TOOL" != "Bash" ]; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
  [ -n "$FILE" ] || exit 0
  path_allowed "$FILE" || block "$REL_BLOCKED"
  exit 0
fi

# --- Bash branch: catch common shell write forms against existing project files.
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -n "$CMD" ] || exit 0

CANDIDATES=$(
  {
    # output redirection targets: > file, >> file (fd dups like 2>&1 filtered below)
    echo "$CMD" | grep -oE '>{1,2}[[:space:]]*[^[:space:];|&<>]+' | sed -E 's/^>{1,2}[[:space:]]*//'
    # tee targets: tee [-a] file
    echo "$CMD" | grep -oE '(^|[|;&][[:space:]]*)tee[[:space:]]+(-a[[:space:]]+)?[^[:space:];|&]+' | sed -E 's/.*tee[[:space:]]+(-a[[:space:]]+)?//'
    # in-place sed: last path-looking token of a 'sed -i' segment
    echo "$CMD" | grep -oE 'sed[[:space:]]+-i[^|;&]*' | grep -oE '[^[:space:]]+$'
  } | sed -E "s/^[\"']//; s/[\"']$//" | sort -u
)

for t in $CANDIDATES; do
  case "$t" in
    "&"*|/dev/*) continue ;; # fd duplication (>&2), device sinks
  esac
  # Enforcement layer: hooks and settings changes must go through Edit/Write so
  # the permissions ask-gate applies — shell writes would skip it. Blocked even
  # for new files. Residual, accepted: a subagent with Bash is exempt above;
  # hooks are snapshotted at session start, so mid-session edits don't apply.
  REL_ENF="$t"
  case "$t" in "$CWD"/*) REL_ENF="${t#"$CWD"/}" ;; esac
  case "$REL_ENF" in
    .claude/hooks/*|.claude/settings.json|.claude/settings.*.json|.claude/settings.template.json)
      echo "Enforcement layer: '$REL_ENF' must be changed via Edit/Write so the permissions ask-gate applies — not via shell writes." >&2
      exit 2 ;;
  esac
  if ! path_allowed "$t"; then
    # Only block writes to files that already exist in the project —
    # scratch output to a new file stays allowed.
    if [ -e "$CWD/$REL_BLOCKED" ]; then
      block "$REL_BLOCKED"
    fi
  fi
done

exit 0
