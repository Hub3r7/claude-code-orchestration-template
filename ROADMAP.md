# Roadmap & Verification Ledger

Two things in one file: an honest record of what has actually been verified, and the
executable recipes for what's next. The ledger is deliberately conservative — a box is
checked only for what has been observed, and partial results say so.

## Current verified status (2026-07-05)

Validated end-to-end on two real projects: **minitask** (a single-file CLI) and
**wp-toolkit** (a multi-module WordPress toolkit, four autonomous chains across Tiers
2–4). Plus a CI test suite (`scripts/test-hooks.sh`, `validate_agents.py`,
`validate_skills.py`, `validate_casebook.py`).

Highlights:
- **Tiers 1–4 each ran on a real task.** Both Tier 4 chains caught a real bug via the
  loop-back protocol — one was a fail-open security check (a bare-relative config path
  that silently skipped a git-tracking guard).
- **Casebook seeding works and is accurate.** Bootstrap seeded 3–5 project-specific cases
  from wp-toolkit's risk topology; all four task classifications traced to sound seeded
  cases (verified post-hoc).
- **The live run found a real template bug** that CI had missed: the read-only-agent notes
  hook truncated structured notes to their title. Fixed, with a regression test using the
  real note format. This is the headline result — a real project surfaced a defect the
  simplified unit test could not.

## Validation matrix

Legend: `[x]` verified live · `[~]` partial or unit-tested only · `[ ]` not yet exercised.

| Capability | Status | Evidence |
|-----------|:------:|----------|
| Tier 0 chain | `[ ]` | trivial path; never run as its own chain |
| Tier 1 chain | `[x]` | minitask (developer → quality-gate → docs) |
| Tier 2 chain | `[x]` | wp-toolkit Task 2 |
| Tier 3 chain | `[x]` | wp-toolkit Task 1 (hunter position ran) |
| Tier 4 chain | `[x]` | wp-toolkit Tasks 3 & 4 (hunter ∥ defender; both caught a real bug) |
| Casebook (seed + correction + portable format) | `[x]` | bootstrap Phase 3c cases; case-14 correction; JSONL parity in CI |
| Bootstrap | `[x]` | minitask + wp-toolkit |
| `doctor.sh` | `[x]` | wp-toolkit, all checks green on fresh install |
| Chain manifest via `chain.sh` | `[x]` | 4 chains: init → advance → complete, accurate FAIL counts |
| Verdict logging (`chain-log.jsonl`) | `[x]` | full log across 4 chains |
| Loop-back protocol (FAIL → fix → PASS) | `[x]` | 2 real catches on wp-toolkit Tier 4 |
| Circuit breaker (3-FAIL block) | `[~]` | unit-tested in `test-hooks.sh`; never hit 3 FAILs live |
| Destructive-git guard | `[x]` | unit-tested + live refusal (minitask `rm -rf`) |
| Orchestrator write block | `[x]` | live (minitask red-team: shell-bypass attempt closed) |
| Developer write exemption | `[x]` | live (developers edited across both projects) |
| Read-only notes persistence | `[~]` | bug found & fixed during this test; fix unit-tested, live re-validation pending |
| Resume / compaction re-orientation | `[~]` | PostCompact wiring fires (silent on finished chain); in-flight injection + SessionStart/UserPromptSubmit orientation not yet positively observed |
| Vendor drift check | `[x]` | monthly CI job, ran clean at build time |

## Known limits

- **Claude Code only.** Built on its sub-agent system, hooks, and skills; it does not work
  with other AI tools or IDEs.
- **Token overhead.** Multi-agent review costs more than a single pass; a Tier 4 chain is
  seven agent runs. The tiers scale the cost to the risk and the operating cards cut the
  fixed overhead, but the overhead is real.
- **Not a replacement for CI, human review, or security tooling.** An agent PASS is a
  review signal, not formal assurance. Hunter/defender review the attack and integrity
  surface; they do not prove the absence of vulnerabilities.
- **Needs more external validation.** So far it has run on two projects, both mine.

## Next external validation targets

- **3–5 independent repositories** that aren't mine, across different stacks, run through
  the recommended first-validation path.
- **One public demo transcript** of a full Tier 3/4 chain, including a real FAIL → fix.
- **One short demo video or GIF** of the status line and a chain in flight.
- **Clearer failure-mode docs** — what each hook block looks like and how to respond
  (seed exists in the operator guide; expand with real transcripts).
- **A contribution guide** — how to add agents, tiers, or casebook cases, and how to run
  the test suite.

---

## Verification history

### V1 — live smoke test of the hook suite (DONE 2026-07-05, minitask)
Passed on a single-file CLI. Confirmed live: tier classification, chain manifest
lifecycle, status line, SubagentStop verdict + chain-log, orchestrator-scope block with
working subagent exemption, PostCompact wiring (fires; silent on a finished chain by
design), destructive-op refusal → impact analysis → delegation. Also red-teamed: the model
proposed bypassing the scope block via Bash — closed the same day (Bash branch of
`orchestrator-scope.sh` + destructive-git pattern gaps). *Correction (found in V1.5): the
"notes-persist works" observation here held only for flat-bullet notes; structured notes
were being truncated — see V1.5.*

### V1.5 — full live test on a fresh project (DONE 2026-07-05, wp-toolkit)
Four autonomous chains (clear_cache multi-plugin, venv/requirements, multi-project support,
credential hardening). Results:
- Tier classification matched the seeded casebook on all four tasks; the model classified
  equal-to-or-higher than a blind human estimate, never lower, and every choice traced to a
  sound seeded case.
- Loop-back caught two real bugs (both Tier 4), including a fail-open security check.
- The circuit breaker never fired (max 1 FAIL per gate) — correct, no false escalation.
- The offline smoke test stayed green and was expanded by the tasks with security-aware
  checks — the Tier 4 ceremony produced real hardening depth.
- **Surfaced and fixed a real template bug:** `notes-persist.sh` truncated read-only agents'
  structured notes. Fixed + regression test.
- **Still not exercised:** in-flight resume/compaction re-orientation, the stop guard, the
  ask-gate on hook edits, and `/deep-analysis` fork (the run went straight through without a
  `/compact` or a hook edit). Tier 0 also never occurred naturally.

### V2 — evidence review
Can run as the closing step of a real project's use — `chain_complete` / `chain_abandoned`
events give per-chain evidence without waiting weeks. Questions: how many FAILs were real
catches vs. noise? Does Tier 2's double quality-gate ever catch what a single gate wouldn't?
Outcomes: keep / slim Tier 2 to one gate / recalibrate tier upgrade rules. First pass
(wp-toolkit, 4 chains): quality-gate 8 PASS / 2 FAIL, both FAILs productive; hunter and
defender all-PASS but too small a sample to judge (and their notes were lost to the
notes-persist bug — reassess once notes persist).

## Build log

### B1. Consolidation step — notes → project rules — DONE 2026-07-05
`/consolidate`: reads `.agentNotes/*/notes.md` + `chain-log.jsonl`, proposes (never
auto-applies) promotions — recurring finding → `docs/project-rules.md`, recurring tier
misjudgment → `tier-casebook.md`, obsolete notes → deletion. docs agent recommends it after
Tier 3-4 chains with a finding seen ≥3 times.

### B2. Model & effort reassignment (cost) — DONE 2026-07-05
developer = Sonnet (Opus only on Tier 3-4 via an orchestrator note); architect stays Opus.
Gate agents `effort: medium` for Tier 1-2; hunter/defender stay `high`. Bootstrap asks.

### B3. Plugin packaging — POSTPONED (revisit now that sharing has started)
`plugin.json` + `.claude-plugin/marketplace.json` so install versions instead of "copy a
folder". Verify the current plugin schema against code.claude.com/docs first. Keep the
copy-a-folder path as the no-plugin fallback. *This is the top remaining build item now
that the template is being shared — copying folders does not version or update.*

### B4. Sandbox as a categorical enforcement ring — DONE 2026-07-05 (macOS run unverified)
`settings.template.json` enables the OS sandbox + `permissions.deny` mirrors of the
destructive-git patterns. The regex hook stays for better error messages. Linux verified;
macOS sandbox availability still unconfirmed.

### B5. Self-maintenance automation — DONE 2026-07-05
Monthly CI drift check against upstream agent-skills; `/consolidate` cadence is manual or
`/loop`. The vendored refresh stays manual (cards regenerate with it — see `INTEGRATION.md`).

### B6. Casebook as a portable format — DONE 2026-07-05
Every case exists twice: a human-readable row in `tier-casebook.md` and a machine-readable
record in `tier-casebook.jsonl` (schema in `casebook-format.md`; change characteristics
mirror the tier rules 1:1). `validate_casebook.py` keeps the pair in sync in CI.

### B7. Agent Teams adapter — CONDITIONAL (start when Agent Teams leaves the experimental flag)
Translate tiers from *which sequential chain runs* to *how much autonomy a teammate gets*
(Tier 0-1 solo; Tier 2 gate before merge; Tier 3-4 gate + human approval), via a
`TaskCompleted` exit-2 hook reading the tier from the manifest. Platform facts verified
2026-07-05: Agent Teams is experimental behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, has
no session resumption, and costs more tokens; `TaskCompleted`/`TeammateIdle` fire only
inside Agent Teams; Outcomes rubrics are a Managed Agents API feature, not in the CLI. Keep
the sequential chain + SubagentStop suite as the stable core — it runs on stock Claude Code
with no flags. If the CLI ever ships a native structured verdict channel, retire the verdict
regex in favor of it.

### B8. Subagent native memory — EVALUATE (during the next real project week)
Subagents support persistent memory natively (`memory: user|project|local`, GA v2.1.59),
overlapping `.agentNotes` + `notes-persist.sh`. Native memory is machine-local and outside
the repo; `.agentNotes` is in-repo, protocol-capped, and feeds `/consolidate`. Enable
`memory: project` on one consultant (critic) alongside the notes, compare over a week, then
adopt / complement / reject with evidence. *Extra relevance after the notes-persist bug:
native memory is a candidate second path for read-only agents.*

**Optional refactor (no urgency):** per-agent `hooks` frontmatter could move the verdict
check into the gate agents' own files (self-contained definitions). Same behavior, nicer
packaging; do it opportunistically.

## Explicit non-goals

- **LangGraph or any external runtime** — wrong layer; deterministic chains, if ever needed,
  go through Claude Code's native workflow scripts.
- **Vector-DB / external memory products** — the file-based memory (`.agentNotes`, chain
  manifest, casebook) is deliberate; invest in consolidation (B1), not storage.
- **Resurrecting the retired teams** (devops-sre, data-engineering, research-analysis) — they
  live at the `four-teams` git tag; adapt the single template instead.
- **Agent `skills:` preloading** — it injects full skill content at spawn; the operating
  cards' two-tier read exists precisely to avoid paying that on every invocation.
- **CLAUDE.md `@imports`** — imported files load at launch anyway: same tokens, more churn.
- **`type: "agent"` hooks and other experimental hook surface** — same rule as Agent Teams
  (B7): adapters wait for GA.
- **Per-agent `isolation: worktree` defaults** — worktree isolation stays an orchestrator
  judgment call for high-blast-radius Tier 3-4 work.
