#!/usr/bin/env python3
"""Validate the vendored engineering-skills layer (software-development team).

Checks:
  - every skill dir has a SKILL.md with name+description frontmatter, name == dirname
  - every `references/<file>.md` link inside any SKILL.md resolves on disk
  - every cross-skill ``see `<skill>` `` reference resolves to a vendored skill
  - README.md and INTEGRATION.md exist
  - README's skill mapping is consistent with what's on disk, both ways:
      * every vendored skill is mentioned in README (no orphan)
      * every skill-looking name mentioned in README exists on disk (no ghost)

Exit 0 = all good, 1 = at least one violation. Stdlib + PyYAML only.
"""
from __future__ import annotations

import glob
import os
import re
import sys

import yaml

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS_DIR = os.path.join(
    REPO_ROOT, "teams", "software-development", ".claude", "agent-skills"
)


def frontmatter(text: str):
    if not text.startswith("---"):
        return None
    parts = text.split("\n")
    for i in range(1, len(parts)):
        if parts[i].strip() == "---":
            try:
                return yaml.safe_load("\n".join(parts[1:i]))
            except yaml.YAMLError:
                return None
    return None


def main() -> int:
    errors: list[str] = []

    if not os.path.isdir(SKILLS_DIR):
        print(f"ERROR: skills dir not found: {SKILLS_DIR}", file=sys.stderr)
        return 1

    skill_dirs = sorted(
        d
        for d in os.listdir(SKILLS_DIR)
        if os.path.isfile(os.path.join(SKILLS_DIR, d, "SKILL.md"))
    )
    skill_names = set(skill_dirs)

    # 1. Per-skill frontmatter + name/dirname match
    for name in skill_dirs:
        path = os.path.join(SKILLS_DIR, name, "SKILL.md")
        with open(path, encoding="utf-8") as fh:
            fm = frontmatter(fh.read())
        rel = os.path.relpath(path, REPO_ROOT)
        if not isinstance(fm, dict):
            errors.append(f"{rel}: missing or invalid frontmatter")
            continue
        if "name" not in fm or "description" not in fm:
            errors.append(f"{rel}: frontmatter must have name and description")
        if fm.get("name") != name:
            errors.append(f"{rel}: name '{fm.get('name')}' != dir '{name}'")

    # 2 + 3. references/ links and cross-skill `see` refs resolve
    ref_link = re.compile(r"references/([a-z0-9-]+\.md)")
    see_ref = re.compile(r"see `([a-z][a-z-]+)`")
    for name in skill_dirs:
        path = os.path.join(SKILLS_DIR, name, "SKILL.md")
        with open(path, encoding="utf-8") as fh:
            body = fh.read()
        rel = os.path.relpath(path, REPO_ROOT)
        for ref in sorted(set(ref_link.findall(body))):
            if not os.path.isfile(os.path.join(SKILLS_DIR, "references", ref)):
                errors.append(f"{rel}: dangling reference 'references/{ref}'")
        for ref in sorted(set(see_ref.findall(body))):
            # only flag tokens that look like a skill (kebab, plausible) and aren't vendored
            if "-" in ref and ref not in skill_names:
                errors.append(f"{rel}: 'see `{ref}`' does not match a vendored skill")

    # 4. README + INTEGRATION present
    readme = os.path.join(SKILLS_DIR, "README.md")
    integration = os.path.join(SKILLS_DIR, "INTEGRATION.md")
    for required in (readme, integration):
        if not os.path.isfile(required):
            errors.append(f"missing required file: {os.path.relpath(required, REPO_ROOT)}")

    # 4b. Operating cards: every vendored skill has cards/<name>.md and vice versa,
    # so a vendored refresh cannot silently ship a skill without its distillation.
    cards_dir = os.path.join(SKILLS_DIR, "cards")
    if not os.path.isdir(cards_dir):
        errors.append("missing cards/ directory (operating-cards layer)")
    else:
        card_names = {
            os.path.splitext(f)[0]
            for f in os.listdir(cards_dir)
            if f.endswith(".md")
        }
        for missing in sorted(skill_names - card_names):
            errors.append(f"cards/: missing operating card for vendored skill '{missing}'")
        for ghost in sorted(card_names - skill_names):
            errors.append(f"cards/{ghost}.md: no matching vendored skill")

    # 5. README mapping consistency (both directions)
    if os.path.isfile(readme):
        with open(readme, encoding="utf-8") as fh:
            readme_text = fh.read()
        mentioned = set(re.findall(r"`([a-z][a-z-]+)`", readme_text)) & skill_names
        orphans = skill_names - mentioned
        for o in sorted(orphans):
            errors.append(f"README.md: vendored skill '{o}' not mentioned in mapping")

    if errors:
        print(f"Skill validation FAILED ({len(errors)} issue(s)):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print(
        f"Skill validation OK — {len(skill_dirs)} skills, "
        f"references resolve, README mapping consistent."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
