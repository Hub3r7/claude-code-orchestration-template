# Roadmap — executable recipes

Each item below is written as a recipe a mid-tier model can execute without design
work: the design decisions are already made here. Order within sections matters —
verification items gate the build items.

## Verify first (before building anything new)

### V1. Live smoke test of the hook suite — DONE 2026-07-05

**Result:** passed on a real project (minitask). Confirmed live: tier classification,
chain manifest lifecycle, statusline, SubagentStop verdict + chain-log, orchestrator-scope
block with working subagent exemption, notes-persist (critic's notes written by the hook),
PostCompact wiring (fires, silent on finished chain by design), post-compact
self-orientation, destructive-op refusal → impact analysis → delegation. The test also
red-teamed the suite: the model proposed bypassing the scope block via Bash — closed the
same day (Bash branch of orchestrator-scope.sh + destructive-git pattern gaps). Residual:
PostCompact additionalContext injection with an IN-FLIGHT chain not yet positively
observed — check during the next real Tier 2+ chain. Also note: a trivial single-file
project never generates Tier 3/4 naturally — to exercise the upper tiers, run one
deliberately scoped Tier 3 task (e.g. an HTTP/export feature) or test on a real project.
The shell hooks are covered by `scripts/test-hooks.sh`, but two assumptions have never
run in a real session: (a) SubagentStop input carries `agent_transcript_path` and
`agent_type`; (b) PreToolUse input inside a subagent carries `agent_type` (the
orchestrator-scope exemption depends on it).

1. Copy `template/` contents into a scratch project, install `settings.template.json`
   as `.claude/settings.json`.
2. Run one Tier 1 chain (developer → quality-gate → docs) on a trivial bug.
3. Confirm: verdict recorded in `.agentNotes/chain-log.jsonl`; developer could edit
   project files (scope hook exempted it); orchestrator got blocked when editing a
   project file directly; status line rendered.
4. If a field is missing in practice, fix the affected hook's `jq` paths — the designs
   hold, only field names may drift.

### V1.5. Full live test on a fresh project — NEXT (user has a candidate project)
Install the template on a project that never had it (cp + `doctor.sh` + `/bootstrap`),
then work normally for a few sessions. Checklist — each item is a residual no CI test
covers:
1. `doctor.sh` passes on the fresh install; `/bootstrap` seeds the profile, the active
   skill set, and 3-5 project casebook cases (Phase 3c).
2. One Tier 1 chain end-to-end driven by `chain.sh` (init → advance → complete lands a
   `chain_complete` line in the log; statusline tracks it).
3. One deliberate Tier 3 task (external I/O — e.g. an HTTP export) → hunter/defender
   position runs; the Tier 3 approval gate is presented first.
4. Mid-chain: restart or `/resume` the session → SessionStart re-injects the manifest;
   send an unrelated prompt → the UserPromptSubmit one-line reminder appears.
5. Stop guard: at least one blocked turn-end mid-chain; the model reacts by continuing
   or explicitly pausing (never loops).
6. Ask-gate: ask the model to tweak a hook — the approval prompt must appear.
7. `/deep-analysis` runs forked (main context stays small — verify with `/usage`).
8. Finish with `/consolidate` as V2-lite: verdicts, `chain_complete` rows, tool
   failures, casebook proposals. Record conclusions in V2 below.

### V2. Evidence review after ~2 weeks of use
Can run as the closing step of V1.5 — `chain_complete`/`chain_abandoned` events give
per-chain evidence without waiting two weeks.
Read `.agentNotes/chain-log.jsonl` across projects. Questions: how many FAILs were real
catches vs. noise? Does Tier 2's double quality-gate ever catch anything the single gate
wouldn't? Outcomes: (a) keep, (b) slim Tier 2 to one gate, (c) recalibrate tier
upgrade rules. Also sanity-check operating cards: if gate findings got shallower after
the cards landed, tighten the go-deep triggers in the affected cards.

## Build next (in this order)

### B1. Consolidation step — notes → project rules — DONE 2026-07-05
**Why:** recurring findings should become preventive rules, not repeated catches.
1. New skill `/consolidate` (sw-dev team): read all `.agentNotes/*/notes.md` +
   `chain-log.jsonl`; propose (do not auto-apply) promotions: recurring code finding →
   `docs/project-rules.md`, recurring tier misjudgment → `tier-casebook.md`, obsolete
   notes → deletion list. Present as a diff for user approval.
2. Add one line to the docs agent: at the end of Tier 3-4 chains, recommend
   `/consolidate` if its notes contain a finding seen ≥3 times.

### B2. Model & effort reassignment (cost) — DONE 2026-07-05
**Why:** cost is a binding constraint (July 2026).
1. In `bootstrap-protocol.md`, change the default: developer=Sonnet (Opus only on
   Tier 3-4 via an orchestrator note), architect stays Opus.
2. Gate agents: `effort: medium` for Tier 1-2 reviews — add a frontmatter comment and a
   bootstrap question. Keep `effort: high` on hunter/defender.
3. Measure with `/usage` before/after on comparable tasks; revert if quality visibly drops.

### B3. Plugin packaging — POSTPONED (deliberately; revisit when distribution matters)
**Why:** distribution + updates; "copy a folder" doesn't version.
1. Create `plugin.json` (name: claude-code-orchestration, the `template/` content:
   agents, skills, hooks, settings fragments). Follow the plugin layout from
   code.claude.com/docs plugins reference — verify current schema first, do not trust
   memory.
2. Marketplace entry: `.claude-plugin/marketplace.json` in this repo; users then install
   via marketplace add + `enabledPlugins`.
3. Keep the copy-a-folder path in README as the no-plugin fallback.

### B4. Sandbox as third enforcement ring — DONE 2026-07-05 (macOS run still unverified)
**Why:** the destructive-git hook is regex; sandbox is categorical.
1. Add to `settings.template.json`: `"sandbox": {"enabled": true, "autoAllowBashIfSandboxed": true}`
   plus `permissions.deny` mirrors of the hook's worst cases (`Bash(git push --force*)`, …).
2. Keep the regex hook — layered defense, hook gives better error messages.
3. Test on Linux + macOS before committing; sandbox availability differs.

### B5. Self-maintenance automation — DONE 2026-07-05 (drift check in CI monthly; /consolidate cadence is manual or /loop)
**Why:** the evidence loop must close without anyone remembering it.
1. Weekly (local `/loop` or a scheduled routine): run the V2 evidence review, output a
   short tuning report.
2. Monthly: `git clone --depth 1` upstream agent-skills, diff against vendored copies,
   report drift (the refresh itself stays manual — cards must be regenerated with it,
   see `INTEGRATION.md` bridge 6).

### B6. Casebook as a portable format — DONE 2026-07-05
**Why:** external review (July 2026): the casebook is a learning blast-radius
classifier written in markdown; a defined record schema makes casebooks shareable
across projects, aggregatable, and eval-ready. Each case now exists twice: a
human-readable row in `tier-casebook.md` (what the orchestrator reads) and a
machine-readable record in `tier-casebook.jsonl` (the interchange format — schema in
`casebook-format.md`; the change characteristics mirror the tier upgrade rules 1:1).
`scripts/validate_casebook.py` keeps the pair in sync in CI.

### B7. Agent Teams adapter — CONDITIONAL (start when Agent Teams leaves the experimental flag, or at first real Teams use)
**Why:** external review (July 2026): "risk-tiered autonomy for parallel agent teams"
— translate tiers from *which sequential chain runs* to *how much autonomy a teammate
gets*. Platform facts verified 2026-07-05: Agent Teams is experimental behind
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, has no session resumption, and costs
significantly more tokens; `TaskCompleted`/`TeammateIdle` hooks exist (exit-2
blocking) but fire only inside Agent Teams; Outcomes rubrics are a Managed Agents API
feature, NOT in the Claude Code CLI.
1. Map tiers to autonomy levels: Tier 0-1 = teammate acts alone; Tier 2 =
   quality-gate review before merge; Tier 3-4 = gate + human approval on every merge.
2. Implement as a `TaskCompleted` exit-2 hook reading the tier from the chain
   manifest — in teams mode this replaces transcript-grep as the verdict substrate.
3. Keep the sequential chain + SubagentStop suite as the stable core: it runs on
   stock Claude Code with no flags (a distribution advantage), and the chain manifest
   keeps doing what Dreaming does not (in-flight chain state, FAIL counters,
   statusline, PostCompact re-injection).
4. If the CLI ever ships a native structured verdict channel, kill the verdict regex
   in `gate-verdict-check.sh` in its favor.

### B8. Subagent native memory — EVALUATE (during the next real project week)
**Why:** subagents support persistent memory natively (`memory: user|project|local`
frontmatter, GA v2.1.59) — overlapping `.agentNotes` + `notes-persist.sh`. Do NOT
swap blindly: native memory is machine-local and lives outside the repo, while
`.agentNotes` is in-repo, protocol-capped, and feeds `/consolidate`.
1. Enable `memory: project` on ONE consultant (critic) alongside the existing notes.
2. After a week of real use compare: what native memory retained vs the hook-written
   notes; whether `/consolidate` can reach it; whether the 200-line discipline holds.
3. Decide adopt / complement / reject — record the evidence here either way.

**Optional refactor (no urgency):** agent frontmatter supports per-agent `hooks` —
the verdict check could move from global settings into the three gate agents' own
files (self-contained definitions). Same behavior, nicer packaging; do it
opportunistically when those agents are next touched.

## Explicit non-goals
- LangGraph or any external runtime — wrong layer; deterministic chains, if ever needed,
  go through Claude Code's native workflow scripts.
- Vector-DB / external memory products — the file-based memory (.agentNotes, chain
  manifest, casebook) is deliberate; invest in consolidation (B1), not storage.
- Resurrecting the retired teams (devops-sre, data-engineering, research-analysis) —
  they live at the `four-teams` git tag; adapt the single template instead.
- Agent `skills:` preloading — it injects full skill content at spawn; the operating
  cards' two-tier read exists precisely to avoid paying that on every invocation.
- CLAUDE.md `@imports` — imported files load at launch anyway: same tokens, more churn.
- `type: "agent"` hooks and other experimental hook surface — same rule as Agent
  Teams (B7): adapters wait for GA.
- Per-agent `isolation: worktree` defaults — worktree isolation stays an orchestrator
  judgment call for high-blast-radius Tier 3-4 work.
