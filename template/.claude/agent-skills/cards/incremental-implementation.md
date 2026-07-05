# incremental-implementation — operating card

> Distilled from [`../incremental-implementation/SKILL.md`](../incremental-implementation/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Deliver every multi-file change as thin vertical slices — implement, test, verify, commit — leaving the system working after each one.

**Binding rules:**
- Run the cycle per slice: implement the smallest complete piece, test, verify, commit — never write >100 lines untested.
- Keep it compilable: build and existing tests must pass after every increment; never leave the codebase broken between slices.
- One logical change per increment — don't mix a feature, a refactor, and config in one commit; separate them.
- Scope discipline: touch only what the task requires; note adjacent improvements, don't fix them.
- Simplicity first: implement the naive obviously-correct version; no abstraction before the third use case demands it.
- Gate incomplete merged work behind a feature flag now, not later; keep each increment independently revertable.

**Do NOT apply when:**
- Single-file, single-function changes where the scope is already minimal.
- Pure re-runs of unchanged code: repeating a passing build/test command adds no information.

**Go deep — read the full SKILL.md — when:**
- Choosing a slicing strategy for a big feature (vertical vs contract-first vs risk-first) or parallel backend/frontend work.
- You're rationalizing batching ('test at the end') or a slice keeps failing — read the full checklist and red flags.
