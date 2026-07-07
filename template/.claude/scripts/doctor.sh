#!/bin/bash
# doctor.sh — verify the template installation in the current project.
#
# Run from the project root after copying template/ in:
#   bash .claude/scripts/doctor.sh
# Exit 0 = ready to work; exit 1 = at least one problem (each printed as FAIL).

set -u
fail=0
ok()  { printf '  OK   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; fail=1; }

echo "Template doctor — checking $(pwd)"

command -v jq >/dev/null 2>&1 \
  && ok "jq installed ($(jq --version 2>/dev/null))" \
  || bad "jq missing — every hook depends on it (apt install jq / brew install jq)"

[ -f CLAUDE.md ] && ok "CLAUDE.md at project root" \
  || bad "CLAUDE.md missing — copy template/CLAUDE.md to the project root"

AGENTS=$(ls .claude/agents/*.md 2>/dev/null | wc -l | tr -d ' ')
[ "$AGENTS" -ge 7 ] && ok "agent definitions present ($AGENTS)" \
  || bad ".claude/agents incomplete ($AGENTS found) — copy template/.claude here"

[ -d .claude/hooks ] && ok ".claude/hooks present" || bad ".claude/hooks missing"

if [ -f .claude/settings.json ]; then
  jq -e . .claude/settings.json >/dev/null 2>&1 \
    && ok ".claude/settings.json is valid JSON (hooks active)" \
    || bad ".claude/settings.json is not valid JSON — hooks will not load"
else
  bad "no .claude/settings.json — hooks NOT active (cp .claude/settings.template.json .claude/settings.json)"
fi

NX=$(find .claude/hooks .claude/scripts -name '*.sh' ! -perm -u+x 2>/dev/null | wc -l | tr -d ' ')
[ "$NX" = "0" ] && ok "hooks and scripts executable" \
  || bad "$NX script(s) not executable — chmod +x .claude/hooks/*.sh .claude/scripts/*.sh"

if command -v jq >/dev/null 2>&1 && [ -f .claude/hooks/statusline-chain.sh ]; then
  echo '{"model":{"display_name":"doctor"}}' | bash .claude/hooks/statusline-chain.sh >/dev/null 2>&1 \
    && ok "statusline renders" \
    || bad "statusline-chain.sh errored on sample input"
fi

mkdir -p .agentNotes 2>/dev/null && touch .agentNotes/.doctor 2>/dev/null && rm -f .agentNotes/.doctor \
  && ok ".agentNotes writable" \
  || bad "cannot create/write .agentNotes/"

# Match the comment form of a real UNFILLED placeholder, not the bare string — a
# bootstrapped CLAUDE.md still mentions `[PROJECT-SPECIFIC]` in its instructional prose.
grep -qE "<!--[[:space:]]*\[PROJECT-SPECIFIC\]" CLAUDE.md 2>/dev/null \
  && echo "  NOTE CLAUDE.md still has [PROJECT-SPECIFIC] placeholders — run /bootstrap before real work"

if [ "$fail" -eq 0 ]; then
  echo "Doctor: all checks passed."
else
  echo "Doctor: problems found — fix the FAIL lines above."
fi
exit "$fail"
