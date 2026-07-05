# Roadmap — executable recipes

Each item below is written as a recipe a mid-tier model can execute without design
work: the design decisions are already made here. Order within sections matters —
verification items gate the build items.

## Verify first (before building anything new)

### V1. Live smoke test of the hook suite
The shell hooks are covered by `scripts/test-hooks.sh`, but two assumptions have never
run in a real session: (a) SubagentStop input carries `agent_transcript_path` and
`agent_type`; (b) PreToolUse input inside a subagent carries `agent_type` (the
orchestrator-scope exemption depends on it).

1. Copy the sw-dev team into a scratch project, install `settings.template.json` as
   `.claude/settings.json`.
2. Run one Tier 1 chain (developer → quality-gate → docs) on a trivial bug.
3. Confirm: verdict recorded in `.agentNotes/chain-log.jsonl`; developer could edit
   project files (scope hook exempted it); orchestrator got blocked when editing a
   project file directly; status line rendered.
4. If a field is missing in practice, fix the affected hook's `jq` paths — the designs
   hold, only field names may drift.

### V2. Evidence review after ~2 weeks of use
Read `.agentNotes/chain-log.jsonl` across projects. Questions: how many FAILs were real
catches vs. noise? Does Tier 2's double quality-gate ever catch anything the single gate
wouldn't? Outcomes: (a) keep, (b) slim Tier 2 to one gate, (c) recalibrate tier
upgrade rules. Also sanity-check operating cards: if gate findings got shallower after
the cards landed, tighten the go-deep triggers in the affected cards.

## Build next (in this order)

### B1. Consolidation step — notes → project rules
**Why:** recurring findings should become preventive rules, not repeated catches.
1. New skill `/consolidate` (sw-dev team): read all `.agentNotes/*/notes.md` +
   `chain-log.jsonl`; propose (do not auto-apply) promotions: recurring code finding →
   `docs/project-rules.md`, recurring tier misjudgment → `tier-casebook.md`, obsolete
   notes → deletion list. Present as a diff for user approval.
2. Add one line to the docs agent: at the end of Tier 3-4 chains, recommend
   `/consolidate` if its notes contain a finding seen ≥3 times.

### B2. Model & effort reassignment (cost)
**Why:** cost is a binding constraint (July 2026).
1. In `bootstrap-protocol.md`, change the default: developer=Sonnet (Opus only on
   Tier 3-4 via an orchestrator note), architect stays Opus.
2. Gate agents: `effort: medium` for Tier 1-2 reviews — add a frontmatter comment and a
   bootstrap question. Keep `effort: high` on hunter/defender.
3. Measure with `/usage` before/after on comparable tasks; revert if quality visibly drops.

### B3. Plugin packaging
**Why:** distribution + updates; "copy a folder" doesn't version.
1. Create `plugin.json` (name: claude-code-orchestration, the sw-dev team as content:
   agents, skills, hooks, settings fragments). Follow the plugin layout from
   code.claude.com/docs plugins reference — verify current schema first, do not trust
   memory.
2. Marketplace entry: `.claude-plugin/marketplace.json` in this repo; users then install
   via marketplace add + `enabledPlugins`.
3. Keep the copy-a-folder path in README as the no-plugin fallback. Non-goal: porting
   the other three teams to the plugin — sw-dev only until someone asks.

### B4. Sandbox as third enforcement ring
**Why:** the destructive-git hook is regex; sandbox is categorical.
1. Add to `settings.template.json`: `"sandbox": {"enabled": true, "autoAllowBashIfSandboxed": true}`
   plus `permissions.deny` mirrors of the hook's worst cases (`Bash(git push --force*)`, …).
2. Keep the regex hook — layered defense, hook gives better error messages.
3. Test on Linux + macOS before committing; sandbox availability differs.

### B5. Self-maintenance automation
**Why:** the evidence loop must close without anyone remembering it.
1. Weekly (local `/loop` or a scheduled routine): run the V2 evidence review, output a
   short tuning report.
2. Monthly: `git clone --depth 1` upstream agent-skills, diff against vendored copies,
   report drift (the refresh itself stays manual — cards must be regenerated with it,
   see `INTEGRATION.md` bridge 6).

## Explicit non-goals
- LangGraph or any external runtime — wrong layer; deterministic chains, if ever needed,
  go through Claude Code's native workflow scripts.
- Vector-DB / external memory products — the file-based memory (.agentNotes, chain
  manifest, casebook) is deliberate; invest in consolidation (B1), not storage.
- Porting hooks to the other three teams before V1+V2 prove them on sw-dev.
