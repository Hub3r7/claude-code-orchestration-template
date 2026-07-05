# spec-driven-development — operating card

> Distilled from [`../spec-driven-development/SKILL.md`](../spec-driven-development/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Write and validate a structured spec with the human before coding — the spec, not the code, is the shared source of truth for what "done" means.

**Binding rules:**
- Spec before code — code without a spec is guessing; even simple tasks get at least a two-line spec with acceptance criteria.
- List your assumptions explicitly before drafting ('correct me now or I proceed') — never silently fill ambiguous requirements.
- Gate each phase: SPECIFY -> PLAN -> TASKS -> IMPLEMENT; the human reviews and validates before you advance to the next.
- Reframe vague asks into specific, testable success criteria (e.g. 'faster' -> LCP < 2.5s) and confirm the targets.
- Cover the six core areas: Objective, Commands, Project Structure, Code Style, Testing Strategy, Boundaries (Always / Ask first / Never).
- Keep the spec alive: when scope or decisions change, update the spec first, then implement; commit it alongside the code.

**Do NOT apply when:**
- Single-line fixes and typo corrections.
- Changes whose requirements are unambiguous and self-contained.

**Go deep — read the full SKILL.md — when:**
- Drafting the actual spec, plan, or task list — use the full six-area spec template, task template, and per-phase mechanics.
- New project or feature, architectural decision, multi-file change, or any task over ~30 minutes — run the full gated workflow.
