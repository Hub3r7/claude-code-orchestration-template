# Casebook format — portable tier-classification records

The tier casebook is a learning blast-radius classifier: worked examples plus the rule
that every tier correction is appended. This file defines its portable record format so
casebooks can travel — shared between projects, aggregated, and used as labeled data for
evaluating how well a model estimates the blast radius of a change.

Every case exists twice:

- **`tier-casebook.md`** — the human/model-facing render (a markdown table row). This is
  what the orchestrator reads during classification.
- **`tier-casebook.jsonl`** — the record: one JSON object per line, same `id`. This is
  the interchange format.

Append both when adding a case. CI (`scripts/validate_casebook.py`) fails when they
drift apart.

## Record schema (`schema: 1`)

| Field | Type | Meaning |
|-------|------|---------|
| `schema` | int | Format version. Currently `1`. |
| `id` | int | Matches the `#` column in `tier-casebook.md`. |
| `task` | string | One-line task description. |
| `change` | object \| null | Diff characteristics (below). `null` only for principle cases. |
| `tier` | 0-4 \| null | Assigned tier. `null` for principle cases that state a classification rule rather than an example. |
| `why` | string | The rationale, verbatim from the table row. |
| `source` | string | `seed` (ships with the template) \| `bootstrap` (project seeding) \| `correction` (a live tier decision was corrected) \| `consolidate` (promoted by `/consolidate`). |
| `corrected_from` | int \| null | The tier originally assigned, when the case records a correction. |
| `project` | string \| null | `null` for generic cases; the project name for project-specific ones. |
| `date` | string \| null | `YYYY-MM-DD`; `null` for the seed set. |

### `change` — diff characteristics

The booleans mirror the tier upgrade rules in `CLAUDE.md` one-to-one, which is what
makes the records eval-ready: each is a labeled (characteristics → tier) example.

| Field | Type | Meaning |
|-------|------|---------|
| `surface` | array | What kind of thing changes: `docs`, `code`, `config`, `test`, `dependency`, `ci`, `schema`, `infra`. |
| `files` | string | Files touched, approximate: `one` \| `few` \| `many`. |
| `new_files` | bool | Creates new files (→ at least Tier 2). |
| `behavior` | bool | The running system behaves differently after the change. |
| `shared_code` | bool | Touches code other components depend on (→ at least Tier 3). |
| `external_io` | bool | Network or shared external infrastructure (→ at least Tier 3). |
| `persistence` | bool | Creates or alters durable data/artifacts (→ at least Tier 3). |
| `security` | bool | Auth, crypto, secrets, or credentials surface (→ Tier 4). |
| `new_component` | bool | A new major component, in effect (→ Tier 4). |

### Example

```json
{"schema": 1, "id": 9, "task": "New feature calling an external HTTP API", "change": {"surface": ["code"], "files": "few", "new_files": true, "behavior": true, "shared_code": false, "external_io": true, "persistence": false, "security": false, "new_component": false}, "tier": 3, "why": "External I/O → hunter reviews the input/attack surface", "source": "seed", "corrected_from": null, "project": null, "date": null}
```

## Versioning

Adding optional fields is allowed within `schema: 1`. Renaming, removing, or changing
the meaning of a field bumps `schema` — consumers should skip records with a higher
version than they understand.

## Aggregation

Concatenating `tier-casebook.jsonl` files from several projects is a valid corpus: the
`project` field disambiguates, generic seed cases deduplicate on `(id, project: null)`,
and `correction` records are the highest-signal rows — they encode exactly where a real
orchestrator's estimate differed from a human's.
