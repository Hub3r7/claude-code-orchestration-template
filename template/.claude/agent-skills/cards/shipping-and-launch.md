# shipping-and-launch — operating card

> Distilled from [`../shipping-and-launch/SKILL.md`](../shipping-and-launch/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Deploy safely, not just deploy: every launch must be reversible, observable, and incremental — rollback plan, monitoring, and staged rollout ready first.

**Binding rules:**
- Write the rollback plan before deploying: trigger conditions, exact steps, DB migration rollback, expected time-to-rollback.
- Ship behind a feature flag: deploy flag-OFF, enable for team, then 5%→25%→50%→100%, with a 24-48h monitoring window at each stage.
- Set up monitoring and error reporting before launch, never after: error rate, p95 latency, client JS errors, key business metrics.
- Roll back immediately on error rate >2x baseline, P95 latency >50% above baseline, data-integrity issues, or a security vulnerability.
- In the first hour post-deploy: health check 200, no new error types, latency normal, test the critical flow manually, verify logs flow.
- Every flag gets an owner and expiration; test both states in CI; never nest flags; clean up within 2 weeks of full rollout.

**Do NOT apply when:**
- No production release is in the task — work ends before anything ships to users (local dev, review-only, docs changes).
- Deploys confined to staging/dev environments with no user-facing release step.

**Go deep — read the full SKILL.md — when:**
- The task IS a production launch, migration, or beta opening — run the full pre-launch checklist (code, security, perf, a11y, infra).
- Deciding advance/hold/rollback at a rollout stage or writing a rollback plan — use the thresholds table and plan template.
