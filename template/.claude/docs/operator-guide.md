# Operator Guide — working with the template as a human

The hooks talk to the model; this page talks to you. One page: what to run, what the
status line means, and what to do when the template blocks something.

## Install & health check

```bash
cp <template-repo>/template/CLAUDE.md your-project/
cp -r <template-repo>/template/.claude your-project/
cp your-project/.claude/settings.template.json your-project/.claude/settings.json
cd your-project && bash .claude/scripts/doctor.sh
```

`doctor.sh` verifies jq, agents, hooks, settings, and permissions — fix any FAIL line
before starting. Then open Claude Code and run `/bootstrap`.

## Daily commands

| Command | When you use it |
|---------|-----------------|
| `/bootstrap` | Once per project (and on major pivots — say "re-bootstrap") |
| `/tier-check` | Before a task, when you want the tier + chain preview |
| `/chain-status` | "Where are we?" — position, FAIL counters, recent verdicts |
| `/abandon` | Stop the in-flight chain cleanly (logged, with your reason) |
| `/re-review` | Fresh review of existing code, no changes |
| `/deep-analysis` | Deep dive into the codebase (runs in a forked context) |
| `/consolidate` | Weekly: do the gates earn their cost + promote recurring findings |
| `/commit`, `/push` | Guarded git operations |

## Reading the status line

```
Sonnet | T3 ▸ 2/6 ▸ next: developer ▸ FAIL quality-gate:1
```

A Tier 3 chain, 2 of 6 positions done, developer runs next, and quality-gate has
issued one FAIL on this work. Three FAILs on the same gate trip the circuit breaker.

## When the template blocks something

**"Orchestrator scope: ... is project content"** — the main session tried to write a
project file directly. That is the design: code goes through the developer agent. If
you want that file changed, just ask — the orchestrator will delegate it.

**Approval prompt on `.claude/hooks/**` or `settings*.json`** — the ask-gate: nobody,
model included, changes the enforcement layer without your click. Deny it if you did
not ask for that change.

**"Circuit breaker: <gate> has issued FAIL 3 times"** — the review loop is stopped on
purpose; repeated FAILs usually mean the spec or design is off, not the
implementation. Options: refine the task and continue (`bash .claude/scripts/chain.sh
reset <gate>`), or `/abandon` and restart with a better-scoped task.

**"Chain in flight (n/m)" when a turn ends** — the stop guard: the model must finish
the chain or tell you explicitly why it is pausing. If you want the chain dropped,
say so or run `/abandon`.

**Destructive git denied** (`push --force`, `reset --hard`, `rm -rf`, …) — layered
deny: hook + permission rules + OS sandbox. If you truly need such a command, run it
yourself in your own terminal — the template deliberately never does.

## Correcting the model

- **Wrong tier?** Say so ("this is Tier 1, not 3"). The correction is appended to
  `.claude/docs/tier-casebook.md` and its `.jsonl` record, so classification converges
  on your project's instincts over time.
- **Gate too strict or too lax?** Run `/consolidate` — it reports whether the gates
  catch real issues and proposes recalibration from evidence, not vibes.

## Notifications & quality of life

- Long chain, walked away? Set `"inputNeededNotifEnabled": true` (plus a
  `preferredNotifChannel`) in your `~/.claude/settings.json` to get pinged for
  approvals, circuit-breaker escalations, and questions.
- Personal preferences (communication language, favorite test data) belong in
  `~/.claude/settings.json` or a gitignored `CLAUDE.local.md` — never in the shared
  project files.
- `/memory` shows which instruction files actually loaded;
  `bash .claude/scripts/doctor.sh` re-checks the installation anytime.
