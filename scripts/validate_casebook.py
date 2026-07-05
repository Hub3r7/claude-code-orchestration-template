#!/usr/bin/env python3
"""Keep tier-casebook.md and tier-casebook.jsonl in sync, and validate the records.

The markdown table is the human/model-facing render; the JSONL file is the portable
record (schema: template/.claude/docs/casebook-format.md). Every case must exist in
both, with the same tier.
"""
import json
import sys
from pathlib import Path

DOCS = Path(__file__).resolve().parent.parent / "template" / ".claude" / "docs"
MD = DOCS / "tier-casebook.md"
JSONL = DOCS / "tier-casebook.jsonl"

SOURCES = {"seed", "bootstrap", "correction", "consolidate"}
SURFACES = {"docs", "code", "config", "test", "dependency", "ci", "schema", "infra"}
FILES_BUCKETS = {"one", "few", "many"}
CHANGE_BOOLS = ["new_files", "behavior", "shared_code", "external_io",
                "persistence", "security", "new_component"]

errors = []


def md_cases():
    """id -> tier (int, or None for principle rows like 'by change type')."""
    cases = {}
    for line in MD.read_text().splitlines():
        cells = [c.strip() for c in line.split("|")]
        if len(cells) < 5 or not cells[1].isdigit():
            continue
        rid = int(cells[1])
        if rid in cases:
            errors.append(f"tier-casebook.md: duplicate case id {rid}")
        cases[rid] = int(cells[3]) if cells[3].isdigit() else None
    return cases


def jsonl_cases():
    cases = {}
    for n, line in enumerate(JSONL.read_text().splitlines(), 1):
        if not line.strip():
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError as e:
            errors.append(f"jsonl line {n}: invalid JSON ({e})")
            continue
        rid = rec.get("id")
        if not isinstance(rid, int):
            errors.append(f"jsonl line {n}: missing or non-integer id")
            continue
        if rid in cases:
            errors.append(f"jsonl line {n}: duplicate id {rid}")
        if rec.get("schema") != 1:
            errors.append(f"case {rid}: schema must be 1")
        for key in ("task", "why"):
            if not (isinstance(rec.get(key), str) and rec[key].strip()):
                errors.append(f"case {rid}: {key} must be a non-empty string")
        tier = rec.get("tier")
        if tier is not None and tier not in range(5):
            errors.append(f"case {rid}: tier must be 0-4 or null")
        if rec.get("source") not in SOURCES:
            errors.append(f"case {rid}: source must be one of {sorted(SOURCES)}")
        change = rec.get("change")
        if change is None:
            if tier is not None:
                errors.append(f"case {rid}: change may be null only for principle "
                              f"cases (tier null)")
        elif isinstance(change, dict):
            surface = change.get("surface")
            if not (isinstance(surface, list) and surface
                    and set(surface) <= SURFACES):
                errors.append(f"case {rid}: change.surface must be a non-empty "
                              f"subset of {sorted(SURFACES)}")
            if change.get("files") not in FILES_BUCKETS:
                errors.append(f"case {rid}: change.files must be one of "
                              f"{sorted(FILES_BUCKETS)}")
            for key in CHANGE_BOOLS:
                if not isinstance(change.get(key), bool):
                    errors.append(f"case {rid}: change.{key} must be a boolean")
        else:
            errors.append(f"case {rid}: change must be an object or null")
        cases[rid] = tier
    return cases


md = md_cases()
jl = jsonl_cases()

for rid in sorted(md.keys() - jl.keys()):
    errors.append(f"case {rid} is in tier-casebook.md but has no jsonl record")
for rid in sorted(jl.keys() - md.keys()):
    errors.append(f"case {rid} is in tier-casebook.jsonl but has no markdown row")
for rid in sorted(md.keys() & jl.keys()):
    if md[rid] != jl[rid]:
        errors.append(f"case {rid}: tier differs (md: {md[rid]}, jsonl: {jl[rid]})")

if errors:
    print(f"validate_casebook: {len(errors)} error(s)")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"validate_casebook: OK ({len(jl)} cases, md and jsonl in sync)")
