# source-driven-development — operating card

> Distilled from [`../source-driven-development/SKILL.md`](../source-driven-development/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Ground every framework-specific decision in fetched, current official documentation — verify, implement per docs, and cite so the user can check.

**Binding rules:**
- Read the dependency file first and state detected stack + exact versions; if versions are ambiguous, ask — never guess.
- Fetch the specific official docs page for the feature before writing framework-specific code; never implement APIs from memory.
- Cite only official docs/changelogs/standards — never Stack Overflow, blogs, or training data; use full deep-link URLs.
- Follow the current documented pattern; never use APIs the docs deprecate, even if they look correct from training data.
- When docs conflict with existing project code (or each other), surface the conflict with options — never silently pick one.
- If no official doc covers a pattern, mark it UNVERIFIED explicitly — a vague 'might be outdated' disclaimer is not allowed.

**Do NOT apply when:**
- Correctness does not depend on a version: renaming variables, fixing typos, moving files.
- Pure logic identical across versions — loops, conditionals, data structures.
- The user explicitly chooses speed over verification ('just do it quickly').

**Go deep — read the full SKILL.md — when:**
- Docs conflict with each other or with the codebase, or a pattern is undocumented — full conflict/UNVERIFIED protocols and templates apply.
- Building boilerplate or patterns to be copied project-wide — use the full source hierarchy, citation rules, and verification checklist.
