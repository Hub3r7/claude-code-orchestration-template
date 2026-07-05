#!/bin/bash
# Status line: live chain position from .agentNotes/chain-state.json.
# Shows "model | T<tier> > done/total > next: <agent> [> FAIL gate:n]" while a
# chain is in flight; falls back to the model name otherwise. Zero tokens —
# it reads a file, nothing more.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // .workspace.current_dir // "."')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // empty')
STATE="$CWD/.agentNotes/chain-state.json"

if [ -s "$STATE" ] && jq -e . "$STATE" >/dev/null 2>&1; then
  OUT=$(jq -r '
    def fails: [(.fail_counts // {}) | to_entries[] | select(.value > 0) | "\(.key):\(.value)"] | join(" ");
    if (.chain | type == "array") and ((.done // []) | length) < (.chain | length) then
      "T\(.tier // "?") ▸ \((.done // []) | length)/\(.chain | length) ▸ next: \(.chain[((.done // []) | length)])"
      + (if (fails | length) > 0 then " ▸ FAIL " + fails else "" end)
    else empty end
  ' "$STATE" 2>/dev/null)
  if [ -n "$OUT" ]; then
    printf '%s | %s' "${MODEL:-claude}" "$OUT"
    exit 0
  fi
fi

printf '%s' "${MODEL:-claude}"
