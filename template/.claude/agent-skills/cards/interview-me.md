# interview-me — operating card

> Distilled from [`../interview-me/SKILL.md`](../interview-me/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Extract what the user actually wants, one question at a time with a guess attached, until ~95% confidence — before any plan, spec, or code exists.

**Binding rules:**
- Open with a one-sentence hypothesis and an honest confidence number; below ~70%, name on the same line what is still missing.
- Ask exactly one question per turn, each with your guess and its reasoning attached; wait for the user's reaction before the next.
- When answers are buzzwords or convention ('scalable', 'standard approach'), ask: if you didn't have to justify this, what would you want?
- Restate intent in the user's words: Outcome, User, Why now, Success, Constraint, Out of scope — the Out of scope line is non-negotiable.
- Gate on an explicit yes; 'whatever you think', 'sounds good', or silence are not confirmation — re-ask with two concrete options.
- Stop only when you can predict the user's reaction to your next three questions; no spec, plan, or intent doc before the confirmed yes.

**Do NOT apply when:**
- The ask is unambiguous and self-contained, a pure information request, or a mechanical operation (rename, typo fix, format, file move).
- The user explicitly asked for speed over verification, or you already hold a defensible ~95% confidence.
- Non-interactive contexts (CI, scheduled runs, loops): flag the underspecified ask as a blocker for the user instead of interviewing.

**Go deep — read the full SKILL.md — when:**
- The user explicitly invokes it ('interview me', 'grill me', 'are we sure?', 'stress-test my thinking') — run the full step protocol.
- Confidence is not visibly rising after ~3 rounds, or the user keeps deferring — use the full rationalization table and stall-floor rule.
