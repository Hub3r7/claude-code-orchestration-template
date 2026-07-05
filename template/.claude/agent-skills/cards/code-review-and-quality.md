# code-review-and-quality — operating card

> Distilled from [`../code-review-and-quality/SKILL.md`](../code-review-and-quality/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Gate every change through an honest five-axis review — correctness, readability, architecture, security, performance — before it merges.

**Binding rules:**
- Review every change on all five axes before merge — no exceptions; tests passing alone is never sufficient.
- Approve when the change definitely improves code health, even if imperfect; never block because it isn't how you'd have written it.
- Label every finding Critical/Required/Nit/Optional/FYI and lead with correctness and security — don't bury real issues under nits.
- Don't rubber-stamp or soften: quantify problems, push back on flawed approaches, and never accept 'I'll clean it up later'.
- Flag structure with a named remedy (dispatcher, extract helper, delete wrapper) — prefer moves that remove concepts, not relocate them.
- Split ~1000-line changes; separate refactoring from feature work; judge the resulting file structure, not just the diff size.

**Do NOT apply when:**
- You are writing or designing code, not evaluating a proposed change — this doctrine governs review, not implementation.
- Deep security hardening or performance profiling is the task — this covers review-level checks; dedicated skills own the detail.

**Go deep — read the full SKILL.md — when:**
- A review verdict is your deliverable — run the full checklist, severity table, review steps, and presumptive blockers verbatim.
- A change is oversized, disputed, or structurally smelly — you need the splitting strategies, disagreement hierarchy, or remedy list.
