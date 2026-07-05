# Real Token & Cost Telemetry

Earlier versions shipped a `/chain-metrics` skill that asked the model to fill in a
metrics table after a chain run. Those numbers were estimates — the orchestrator cannot
see subagent token usage — so the skill was removed. Use real instrumentation instead.

## In-session: /usage

Claude Code's built-in `/usage` command (aliases: `/cost`, `/stats`) shows session cost
and a breakdown by skill, subagent, plugin, and MCP server. This is the quickest way to
see what an agent chain actually cost right after it ran.

Caveats: requires Claude Code v2.1+; per-subagent breakdowns require a paid plan;
subscription (Pro/Max) sessions show usage against plan limits rather than dollar cost.

## Durable: OpenTelemetry metrics

For numbers you can chart across sessions (e.g. cost per tier over time), enable Claude
Code's OTEL exporter and point it at your collector:

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

Relevant metrics:

| Metric | Meaning |
|--------|---------|
| `claude_code.token.usage` | Tokens consumed (tagged by type: input / output / cache) |
| `claude_code.cost.usage` | Session cost in USD |
| `claude_code.session.count` | Sessions started |

Docs: https://code.claude.com/docs/en/monitoring-usage

## Cost knobs (settings.json)

User-level settings that cap spend before any chain runs. Set them in
`~/.claude/settings.json` or a project's `settings.local.json` — the template
deliberately ships none of them, they are per-user policy:

| Key | Effect |
|-----|--------|
| `model` | Default main-loop model (e.g. `sonnet`) |
| `effortLevel` | Persist a session effort level (`low`–`xhigh`) |
| `availableModels` + `enforceAvailableModels` | Restrict which models can be selected at all |
| `alwaysThinkingEnabled` | Extended thinking on every turn — leave off to save tokens |
| `fallbackModel` | Fallback when the primary model is unavailable |

Docs: https://code.claude.com/docs/en/settings
