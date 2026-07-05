#!/usr/bin/env bash
# Upstream drift check for the vendored agent-skills layer.
# Clones addyosmani/agent-skills at HEAD, diffs the vendored SKILL.md files and
# references/ against it, and exits 1 with a report when upstream moved.
# The refresh itself stays manual: operating cards must be regenerated with it
# (see template/.claude/agent-skills/INTEGRATION.md, bridge 6).
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VEND="$REPO_ROOT/template/.claude/agent-skills"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 -q https://github.com/addyosmani/agent-skills "$TMP/upstream" \
  || { echo "ERROR: upstream clone failed"; exit 2; }
UP="$TMP/upstream"

drift=0

for d in "$VEND"/*/; do
  n="$(basename "$d")"
  [ -f "$d/SKILL.md" ] || continue
  if [ -f "$UP/skills/$n/SKILL.md" ]; then
    diff -q "$d/SKILL.md" "$UP/skills/$n/SKILL.md" >/dev/null \
      || { echo "CHANGED upstream: $n"; drift=1; }
  else
    echo "REMOVED upstream: $n"; drift=1
  fi
done

for s in "$UP"/skills/*/; do
  n="$(basename "$s")"
  [ "$n" = "using-agent-skills" ] && continue  # deliberately un-vendored (distilled into CLAUDE.md)
  [ -d "$VEND/$n" ] || { echo "NEW upstream: $n"; drift=1; }
done

for r in "$UP"/references/*.md; do
  n="$(basename "$r")"
  if [ -f "$VEND/references/$n" ]; then
    diff -q "$VEND/references/$n" "$r" >/dev/null \
      || { echo "CHANGED upstream reference: $n"; drift=1; }
  else
    echo "NEW upstream reference: $n"; drift=1
  fi
done

if [ "$drift" -eq 0 ]; then
  echo "Vendored skills are in sync with upstream HEAD."
else
  echo
  echo "Upstream drift detected. Refresh recipe: re-fetch changed files byte-for-byte,"
  echo "bump the provenance pin in template/.claude/agent-skills/README.md, regenerate"
  echo "operating cards for the changed skills (INTEGRATION.md bridge 6), run validators."
fi
exit "$drift"
