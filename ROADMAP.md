# Roadmap

Where the template is headed. Everything here is forward-looking; design decisions are
already made, so each item is a recipe rather than an open question.

## Planned

### Plugin packaging
Ship as a Claude Code plugin (`plugin.json` + `.claude-plugin/marketplace.json`) so
installs version and update, instead of copying a folder. Verify the current plugin schema
against the Claude Code plugins reference first. Keep the copy-a-folder path as the
no-plugin fallback.

### Agent Teams adapter — when Agent Teams leaves the experimental flag
Translate tiers from *which sequential chain runs* to *how much autonomy a teammate gets*:
Tier 0-1 = teammate acts alone, Tier 2 = quality-gate review before merge, Tier 3-4 = gate
plus human approval on every merge. Implement as a `TaskCompleted` exit-2 hook that reads
the tier from the chain manifest. Keep the sequential chain and the SubagentStop suite as
the stable core — they run on stock Claude Code with no flags. If the CLI ever ships a
native structured verdict channel, retire the verdict regex in favor of it.

### Native subagent memory — evaluate as a second path
Subagents support persistent memory natively (`memory: user|project|local`). It is
machine-local and lives outside the repo, where `.agentNotes` is in-repo, protocol-capped,
and feeds `/consolidate`. Enable it on one consultant alongside the existing notes, compare
over real use, then adopt, complement, or reject with evidence.

## Non-goals

- **LangGraph or any external runtime** — wrong layer; deterministic chains, if ever needed,
  go through Claude Code's native workflow scripts.
- **Vector-DB / external memory products** — the file-based memory (`.agentNotes`, chain
  manifest, casebook) is deliberate; invest in consolidation, not storage.
- **Agent `skills:` preloading** — it injects full skill content at spawn; the operating
  cards' two-tier read exists precisely to avoid paying that on every invocation.
- **CLAUDE.md `@imports`** — imported files load at launch anyway: same tokens, more churn.
- **Experimental hook surface** (`type: "agent"` hooks, Agent Teams internals) — adapters
  wait for GA.
- **Per-agent `isolation: worktree` defaults** — worktree isolation stays an orchestrator
  judgment call for high-blast-radius Tier 3-4 work.
