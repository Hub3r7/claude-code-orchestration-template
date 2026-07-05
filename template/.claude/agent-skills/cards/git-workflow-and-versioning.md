# git-workflow-and-versioning — operating card

> Distilled from [`../git-workflow-and-versioning/SKILL.md`](../git-workflow-and-versioning/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Treat git as the safety net: small atomic commits as save points on short-lived branches, with versions and changelogs as the contract to consumers.

**Binding rules:**
- Commit each verified slice immediately — implement, test, commit; never accumulate large uncommitted changes.
- One logical change per commit; never mix refactors or formatting with behavior changes.
- Write messages as <type>: <desc> explaining the WHY; target ~100 lines, split anything near 1000.
- Before committing: review the staged diff, grep it for secrets, run tests/lint/typecheck.
- Keep main deployable; branch as feature/fix/chore/<desc>, merge within 1-3 days, delete after merge.
- Version by consumer impact (breaking=major — assume breaking when unsure), tag releases, write the changelog entry with the change.

**Do NOT apply when:**
- Release/versioning rules apply only when something has consumers — no tag/changelog contract for code nothing depends on yet.
- Trunk-based flow is the default, not law — teams on gitflow keep the commit discipline but adapt the branching model.

**Go deep — read the full SKILL.md — when:**
- Cutting a release: choosing a semver bump, tagging, deprecating, or writing a changelog — read the Release & Versioning section.
- Running parallel work streams (worktrees), bisecting a regression, or deciding what generated files to commit.
