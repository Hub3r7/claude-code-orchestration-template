#!/bin/bash
# PreToolUse hook on Edit|Write|NotebookEdit: enforce the orchestrator's write scope.
#
# CLAUDE.md says the orchestrator never writes project files directly — it may
# only edit meta-configuration (CLAUDE.md, .claude/**, .agentNotes/**,
# docs/project-rules.md); code goes through developer, documentation through
# docs. This hook makes that rule mechanical for the MAIN session only:
# subagent tool calls carry agent_type/agent_id in the hook input and are
# exempt — their access is governed by their own frontmatter (and read-only
# agents already carry disallowedTools).

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL" in
  Edit|Write|NotebookEdit) ;;
  *) exit 0 ;;
esac

# Subagent context → not the orchestrator.
AGENT=$(echo "$INPUT" | jq -r '.agent_type // .agent_id // empty')
[ -n "$AGENT" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -n "$FILE" ] || exit 0

# Normalize to a project-relative path; anything outside the project root
# (scratch files, /tmp) is not project code and passes.
case "$FILE" in
  "$CWD"/*) REL="${FILE#"$CWD"/}" ;;
  /*) exit 0 ;;
  *) REL="$FILE" ;;
esac

case "$REL" in
  CLAUDE.md|.claude/*|.agentNotes/*|docs/project-rules.md) exit 0 ;;
esac

echo "Orchestrator scope: '$REL' is project content, not meta-configuration. Delegate the change — developer for code, docs for documentation. The orchestrator may write only CLAUDE.md, .claude/**, .agentNotes/**, and docs/project-rules.md." >&2
exit 2
