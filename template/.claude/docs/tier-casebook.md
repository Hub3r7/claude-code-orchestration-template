# Tier Casebook — worked classification examples

Rules calibrate poorly on borderline cases; examples calibrate well. Consult this file
when the tier is not obvious. It is a **living document**: whenever the user corrects a
tier decision, append the case with a one-line rationale. Bootstrap may seed
project-specific cases below the generic set.

Match on the *reason* a task lands where it does — not on surface similarity of the
task description. When in doubt between two tiers, take the higher one (CLAUDE.md rule).

## Generic cases

| # | Task | Tier | Why |
|---|------|------|-----|
| 1 | Fix a typo in an error message | 0 | Text-only, no behavior change |
| 2 | Update a README section | 0 | Pure documentation — docs alone, developer not needed |
| 3 | Bump a retry timeout from 3s to 5s | 1 | Behavior-affecting config value, obvious fix, no new files |
| 4 | Add a null-check fixing a reported crash | 1 | Bug fix with clear reproduction, contained to one file |
| 5 | Patch-version dependency bump (lockfile only) | 1 | Routine, no API surface change |
| 6 | Major-version bump of a core framework | 3 | Same word ("bump") as #5, different reason: behavioral surface across shared code |
| 7 | New CLI subcommand reading local files only | 2 | New feature, contained scope; new files → at least Tier 2 |
| 8 | Extract a helper used by three modules into a shared util | 3 | Reads like a Tier 2 refactor, but touches shared/core code → at least Tier 3 |
| 9 | New feature calling an external HTTP API | 3 | External I/O → hunter reviews the input/attack surface |
| 10 | Add an on-disk cache layer | 3 | Persistent artifacts → defender reviews integrity and permissions |
| 11 | New CI workflow using repository secrets | 3 | Executes on shared infrastructure with credential access — an external surface despite being "just YAML" |
| 12 | Add login/session handling | 4 | Auth is security-critical → full chain, hunter and defender |
| 13 | Replace the serialization format used across modules | 4 | Core/shared code plus data integrity — a new major component in effect |

## Project-specific cases

<!-- [PROJECT-SPECIFIC] Bootstrap and user tier-corrections append cases here, same
     table format. The correction cases are the most valuable — they encode exactly
     where this project's intuition differs from the generic rules. -->
