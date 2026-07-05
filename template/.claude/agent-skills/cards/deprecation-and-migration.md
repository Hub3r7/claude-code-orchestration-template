# deprecation-and-migration — operating card

> Distilled from [`../deprecation-and-migration/SKILL.md`](../deprecation-and-migration/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Treat code as a liability: sunset systems that no longer earn their keep, but only by actively migrating every consumer — never by announcement alone.

**Binding rules:**
- Never deprecate without a working, production-proven replacement covering all critical use cases — build it first.
- Answer the decision questions first: unique value, consumer count, replacement, per-consumer migration cost vs. maintenance cost.
- Deprecation planning starts at design time — when building a new system, ask "How would we remove this in 3 years?"
- Default to advisory deprecation; go compulsory only when security/maintenance cost justifies it, and then supply migration tooling and docs.
- Churn Rule: if you own the deprecated infrastructure, you migrate your users (or ship backward-compatible updates) — don't leave them to it.
- Migrate consumers incrementally (strangler, adapter, or feature-flag), verifying behavior at each step; remove only at confirmed zero usage.

**Do NOT apply when:**
- The system still provides unique value with no replacement planned — maintain it instead of deprecating.
- Ordinary feature work with no lifecycle dimension — nothing removed, consolidated, or migrated, and no new system being designed.
- Zombie code that gets an assigned owner and proper maintenance — investment is the valid alternative to removal.

**Go deep — read the full SKILL.md — when:**
- The task IS a deprecation/migration: planning a sunset, writing a deprecation notice, or choosing strangler vs. adapter vs. feature-flag.
- You need the full checklists — the decision questions, red-flags list, rationalization rebuttals, or the post-deprecation verification list.
