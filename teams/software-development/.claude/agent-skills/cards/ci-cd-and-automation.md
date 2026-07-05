# ci-cd-and-automation — operating card

> Distilled from [`../ci-cd-and-automation/SKILL.md`](../ci-cd-and-automation/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Enforce automated quality gates so no change merges or deploys unverified — checks shifted left, releases small and frequent, rollbacks ready.

**Binding rules:**
- Pass every change through all gates before merge: lint, types, tests, build, security audit — skip none, even for trivial changes.
- Fix failures at the source: never disable a lint rule, skip a failing test, or re-run a flaky test — fix the code or the flakiness.
- Shift left: order checks static analysis → tests → staging → production; a bug caught in lint costs minutes, in production hours.
- Keep production secrets out of CI and code — CI gets its own separate test credentials, stored in a secrets manager, never hardcoded.
- Make every deploy reversible: staging before production, monitor ~15 min after deploy, roll back on errors — no rollback path, no deploy.
- On CI failure, feed the exact error back into the loop, fix, and verify locally before pushing again — never ignore or silence red CI.

**Do NOT apply when:**
- The task touches no pipeline, automated check, or deployment config — no CI setup, modification, or CI-failure debugging involved.
- Designing test content or debugging application logic itself — this governs the enforcement pipeline, not how tests or fixes are written.

**Go deep — read the full SKILL.md — when:**
- Task is centrally CI/CD: writing or restructuring workflow YAML, setting up a new pipeline, or choosing a deployment strategy.
- Pipeline exceeds 10 min (optimization ladder) or rollout mechanics needed: feature-flag lifecycle, staged rollout, rollback workflow.
