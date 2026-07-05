# test-driven-development — operating card

> Distilled from [`../test-driven-development/SKILL.md`](../test-driven-development/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Prove every behavior with a test written before the code — tests are the proof of done; "seems right" and manual checks are not.

**Binding rules:**
- Write the failing test first and see it fail — a test that passes on its first run proves nothing.
- Bug fix: write a reproduction test that fails before any fix; after fixing, run the full suite to guard regressions.
- Assert outcomes/state, never internal call sequences — interaction-based tests break refactors that preserve behavior.
- Prefer real implementations > fakes > stubs > mocks; mock only slow, non-deterministic, or uncontrollable side-effecting boundaries.
- Write the minimum code to go green, then refactor with tests re-run after every step.
- Never skip or disable tests to make the suite pass, and never claim 'all tests pass' without actually running them.

**Do NOT apply when:**
- Pure configuration changes with no behavioral impact.
- Documentation updates or static content changes.

**Go deep — read the full SKILL.md — when:**
- The change runs in a browser — the DevTools runtime-verification workflow, checks table, and security boundaries are needed in full.
- Shaping a test suite (unit/integration/E2E mix, test sizes, anti-patterns) — pyramid ratios and the resource model are needed in full.
