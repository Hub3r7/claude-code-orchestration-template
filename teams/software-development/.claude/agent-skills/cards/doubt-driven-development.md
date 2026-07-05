# doubt-driven-development — operating card

> Distilled from [`../doubt-driven-development/SKILL.md`](../doubt-driven-development/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Before any non-trivial decision stands, spawn a fresh-context reviewer biased to disprove it, and reconcile its findings while course-correction is cheap.

**Binding rules:**
- Name each non-trivial decision as a 2-3 line CLAIM (claim + why it matters) before it stands; if you can't, it's a vibe, not a decision.
- Send the reviewer ARTIFACT + CONTRACT only — never the CLAIM or your reasoning; conclusions handed over come back as validation.
- Prompt adversarially: 'find what is wrong, do not validate' — never 'is this good?'; issues-only output overrides persona defaults.
- Reconcile, don't defer: re-read the artifact and classify each finding — contract misread > actionable > trade-off > noise.
- Stop at trivial findings, 3 cycles, or user 'ship it'; after 3 cycles escalate — decompose big artifacts, never lift the bound.
- Offer cross-model review every interactive cycle — skip only visibly; never run an external CLI without explicit user authorization.

**Do NOT apply when:**
- Mechanical operations: renames, formatting, file moves, running tests, listing files.
- Following a clear unambiguous instruction, reading/summarizing code, or one-line changes with obvious correctness.
- The user has explicitly asked for speed over verification.

**Go deep — read the full SKILL.md — when:**
- Running an actual doubt cycle — the 5-step checklist, adversarial prompt template, and finding-classification order live in the full skill.
- Cross-model CLI invocation (Gemini/Codex) or applying doubt from inside a subagent — safety and fallback protocols are in the full skill.
