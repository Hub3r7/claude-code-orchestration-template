# observability-and-instrumentation — operating card

> Distilled from [`../observability-and-instrumentation/SKILL.md`](../observability-and-instrumentation/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Instrument every production-bound feature as you build it, so on-call can answer "what is the system doing and why?" from telemetry alone.

**Binding rules:**
- Before instrumenting, write 2-4 questions on-call will ask; every signal must answer one — else you log everything and learn nothing.
- Log structured events (stable event name + machine-readable fields), never string-interpolated prose; consistent levels.
- Attach a correlation/request ID to every log line, span, and outbound call; never log secrets, tokens, or unredacted PII.
- Metric labels only from small fixed sets — never user IDs, raw URLs, or error text; track percentiles via histograms, never averages.
- Instrument RED (rate, errors, duration histogram) on every new endpoint and external dependency; USE for resources.
- Alert on symptoms users feel, not causes; every alert is actionable, has a runbook link, and only two severities: page or ticket.

**Do NOT apply when:**
- Diagnosing a failure happening right now — that is debugging-and-error-recovery territory.
- Profiling or optimizing measured slowness — use performance-optimization.
- Launch-day monitoring checklists and rollback triggers — shipping-and-launch covers those.

**Go deep — read the full SKILL.md — when:**
- The task is centrally observability: adding logging/metrics/tracing/alerting, a new service or integration, or reviewing alert rules.
- You need the OpenTelemetry/metrics setup patterns, the telemetry verification steps, or the pre-launch instrumentation checklist.
