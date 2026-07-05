# documentation-and-adrs — operating card

> Distilled from [`../documentation-and-adrs/SKILL.md`](../documentation-and-adrs/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Record the why behind decisions — ADRs, why-comments, API docs, README, changelog — so future engineers and agents don't re-decide or re-derive context.

**Binding rules:**
- Write an ADR (in docs/decisions/) for any decision expensive to reverse: framework/dependency choice, data model, auth, API architecture.
- ADRs must capture Context, Decision, Alternatives Considered with rejection reasons, and Consequences — the rationale is the value.
- Never delete old ADRs; when a decision changes, write a new ADR that references and supersedes the old one.
- Comment the why, not the what: non-obvious intent, constraints, and gotchas; never restate what the code says.
- Delete commented-out code and stale TODOs — git has history; do the TODO now instead of leaving it.
- Document public APIs at the interface: params, returns, thrown errors, and an example (doc comments or OpenAPI).

**Do NOT apply when:**
- Don't document obvious, self-explanatory code — no comments that restate what the code already says.
- Don't write docs for throwaway prototypes.
- No ADR needed for routine, easily reversible implementation choices.

**Go deep — read the full SKILL.md — when:**
- You are about to write an ADR — pull the full template, lifecycle states, and numbering convention.
- The task is centrally documentation (README, changelog, API docs, agent rules files) — use the structures and verification checklist.
