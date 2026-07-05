# code-simplification — operating card

> Distilled from [`../code-simplification/SKILL.md`](../code-simplification/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Simplify code for faster comprehension while preserving behavior exactly — never rewrite, only re-express, scoped to what changed.

**Binding rules:**
- Preserve behavior exactly: same outputs, side effects, ordering, errors; all tests pass unmodified — if unsure, don't change it.
- Chesterton's Fence: never simplify code you don't understand — know its callers, edge cases, and git-blame context first.
- Scope to recently modified code; no drive-by refactors of unrelated code unless explicitly asked.
- Apply one simplification at a time, run tests after each; ship refactors in separate PRs from features or fixes.
- Clarity over cleverness and consistency over preference: match project conventions; comprehension speed, not line count, is the goal.
- Don't over-simplify: keep named helpers, deliberate abstractions, and error handling; merging unrelated logic isn't simpler.

**Do NOT apply when:**
- Code is already clean and readable — don't simplify for its own sake.
- Code is performance-critical and the simpler version would be measurably slower.
- The module is about to be rewritten entirely — simplifying throwaway code wastes effort.

**Go deep — read the full SKILL.md — when:**
- A dedicated simplification pass is the task — use the full opportunity tables and verification checklist.
- A refactor would touch 500+ lines (Rule of 500: automate) or tests must change to pass — consult the full process.
