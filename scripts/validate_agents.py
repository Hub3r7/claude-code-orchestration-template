#!/usr/bin/env python3
"""Validate agent definitions.

Checks, for every `template/.claude/agents/*.md`:
  - frontmatter is present and parses as YAML
  - required keys exist (name, description, model, maxTurns, tools)
  - model is one of the supported tiers
  - `name` matches the filename stem
  - `tools` is a non-empty list
  - read-only agents (no Write/Edit in tools) carry disallowedTools: [Edit, Write, Bash]
  - mandatory body sections are present (## Before any task, ## Collaboration protocol)

Exit code 0 = all good, 1 = at least one violation. No third-party deps beyond PyYAML.
"""
from __future__ import annotations

import glob
import os
import sys

import yaml

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGENT_GLOB = os.path.join(REPO_ROOT, "template", ".claude", "agents", "*.md")

REQUIRED_KEYS = ("name", "description", "model", "maxTurns", "tools")
VALID_MODELS = {"opus", "sonnet", "haiku"}
READONLY_DISALLOWED = {"Edit", "Write", "Bash"}
WRITE_TOOLS = {"Write", "Edit"}
MANDATORY_SECTIONS = ("## Before any task", "## Collaboration protocol")


def split_frontmatter(text: str):
    """Return (frontmatter_str, body_str) or (None, None) if no frontmatter block."""
    if not text.startswith("---"):
        return None, None
    parts = text.split("\n")
    if parts[0].strip() != "---":
        return None, None
    for i in range(1, len(parts)):
        if parts[i].strip() == "---":
            return "\n".join(parts[1:i]), "\n".join(parts[i + 1:])
    return None, None


def validate_file(path: str) -> list[str]:
    errors: list[str] = []
    rel = os.path.relpath(path, REPO_ROOT)
    stem = os.path.splitext(os.path.basename(path))[0]

    with open(path, encoding="utf-8") as fh:
        text = fh.read()

    fm_str, body = split_frontmatter(text)
    if fm_str is None:
        return [f"{rel}: missing or malformed frontmatter block"]

    try:
        fm = yaml.safe_load(fm_str)
    except yaml.YAMLError as exc:
        return [f"{rel}: frontmatter is not valid YAML: {exc}"]

    if not isinstance(fm, dict):
        return [f"{rel}: frontmatter did not parse to a mapping"]

    for key in REQUIRED_KEYS:
        if key not in fm:
            errors.append(f"{rel}: missing required key '{key}'")

    if fm.get("name") != stem:
        errors.append(f"{rel}: name '{fm.get('name')}' does not match filename stem '{stem}'")

    if fm.get("model") not in VALID_MODELS:
        errors.append(f"{rel}: model '{fm.get('model')}' not in {sorted(VALID_MODELS)}")

    tools = fm.get("tools")
    if not isinstance(tools, list) or not tools:
        errors.append(f"{rel}: 'tools' must be a non-empty list")
        tools = []

    is_readonly = not (WRITE_TOOLS & set(tools))
    if is_readonly:
        disallowed = set(fm.get("disallowedTools") or [])
        missing = READONLY_DISALLOWED - disallowed
        if missing:
            errors.append(
                f"{rel}: read-only agent must set disallowedTools "
                f"{sorted(READONLY_DISALLOWED)}, missing {sorted(missing)}"
            )

    if body is not None:
        for section in MANDATORY_SECTIONS:
            if section not in body:
                errors.append(f"{rel}: missing mandatory section '{section}'")

    return errors


def main() -> int:
    files = sorted(glob.glob(AGENT_GLOB))
    if not files:
        print(f"ERROR: no agent files matched {AGENT_GLOB}", file=sys.stderr)
        return 1

    all_errors: list[str] = []
    for path in files:
        all_errors.extend(validate_file(path))

    if all_errors:
        print(f"Agent validation FAILED ({len(all_errors)} issue(s)):", file=sys.stderr)
        for err in all_errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"Agent validation OK — {len(files)} agent files passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
