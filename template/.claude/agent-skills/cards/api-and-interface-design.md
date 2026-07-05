# api-and-interface-design — operating card

> Distilled from [`../api-and-interface-design/SKILL.md`](../api-and-interface-design/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Design stable, hard-to-misuse interfaces: contract defined first, every observable behavior treated as a commitment to consumers.

**Binding rules:**
- Define the typed contract (inputs, outputs, error behavior) before implementing — the contract is the spec.
- Hyrum's Law: every observable behavior becomes a de facto contract; expose intentionally and never leak implementation details.
- One-Version Rule: design for a single live version; never fork or maintain concurrent versions of an API or dependency — extend it.
- Extend, never break: new fields are additive and optional; do not change types of or remove existing fields.
- Pick one error strategy and use it everywhere — same structured shape, consistent status codes; never mix throw/null/{error}.
- Validate only at system edges (user input, third-party responses, env config); third-party data is untrusted. Trust internal typed code.

**Do NOT apply when:**
- Internal-only implementation code that changes no interface — private helpers already behind a validated, typed contract.
- No public surface is being created or modified — no endpoints, module boundaries, props, or type contracts in play.
- Adding validation between internal functions or on data from your own database — the skill explicitly excludes this.

**Go deep — read the full SKILL.md — when:**
- Task is centrally API design: a new REST/GraphQL surface, module contract, or schema — naming, pagination, and TS patterns needed.
- Changing or removing an existing public interface — need the Hyrum's Law implications, rationalization table, and verification checklist.
