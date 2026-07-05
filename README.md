<p align="center">
  <img src="assets/hero.svg" alt="Claude Code Orchestration Template — review scaled to the blast radius of the change" width="100%">
</p>

# Claude Code Orchestration Template

A control layer for Claude Code: every task is rated by blast radius (tier 0–4) and routed through a matching chain of agents — and the protocol is enforced by hooks, not prose.

A typo runs one agent. A security-critical component runs design, two review gates, offensive and defensive security in parallel, then docs.

```
 Tier 0    developer → docs
 Tier 1    developer → quality-gate → docs
 Tier 2    architect → quality-gate → developer → quality-gate → docs
 Tier 3    architect → quality-gate → developer → quality-gate → hunter / defender → docs
 Tier 4    architect → quality-gate → developer → quality-gate → hunter ∥ defender → docs
```

The whole thing is configuration, not code: one `CLAUDE.md` and one `.claude/` folder. Copy `template/` into a project, run `/bootstrap`, start working.

## The judgment layer

Running several agents on a codebase is the easy part. The judgment is the hard part: a one-line fix must not be wrapped in ceremony it doesn't need, and a risky change must not slip through without the review it does.

The tier follows the risk. New files push a task to at least tier 2; external I/O or a new security surface to tier 3; a new major component or anything security-critical to tier 4. When the orchestrator is unsure between two tiers, it takes the higher one.

## A casebook that learns

Rules calibrate poorly on borderline cases; examples calibrate well. The tier decision is therefore backed by a casebook of worked classification examples — "major-version bump of a core framework" is tier 3 while "patch bump, lockfile only" is tier 1, and each case records *why*. Every corrected tier decision is appended as a new case, so classification converges on the project's instincts instead of drifting: a learning blast-radius classifier, written in markdown. Bootstrap seeds it with cases derived from the project's own risk topology.

Each case also exists as a machine-readable JSONL record whose change characteristics — new files, shared code, external I/O, persistence, security surface, new component — mirror the tier rules one-to-one (`casebook-format.md` defines the schema; CI keeps the record and the human-readable table in sync). Casebooks are therefore portable: they can be shared between projects, aggregated into a corpus, or used as labeled data for evaluating how well a model estimates the blast radius of a change. The correction cases are the highest-signal rows — each one records exactly where a real orchestrator's estimate differed from a human's.

## Enforced, not promised

Instructions bend under context pressure; hooks don't. The protocol is mechanical — a hook suite ships in `settings.template.json`:

- **Verdicts are mandatory.** A review agent cannot finish without an explicit PASS/FAIL verdict or a declared BLOCKED state. Every verdict is recorded.
- **The circuit breaker is physical.** After three FAILs on the same gate, the next re-review is blocked outright — the orchestrator has to escalate to the operator; it cannot quietly keep looping.
- **Reviewers can't touch code.** `disallowedTools` keeps every gate and consultant read-only, down to shell redirects.
- **The orchestrator can't either.** A hook blocks main-session writes outside meta-configuration — including the common shell write forms (redirection, `tee`, `sed -i`) against existing project files. Code goes through the developer, or it doesn't go.
- **Chains survive long sessions.** A chain manifest holds tier, plan, and position; after a context compaction, a session restart, or `/resume`, a hook re-injects it, so an in-flight chain resumes mechanically instead of being reconstructed from memory. The manifest has one canonical writer — a small chain script (`init`/`advance`/`complete`/`abandon`) — so no model hand-edits state, whichever one is orchestrating.
- **Turns don't end mid-chain silently.** A stop guard refuses the orchestrator's first attempt to end its turn with an unfinished chain — it must continue, hand the decision to the operator, or abandon the chain explicitly. Circuit-breaker escalations pass through.
- **One semantic check.** A prompt hook on the small, cheap model verifies what regex can't: that a FAIL carries a numbered fix list and a PASS handoff carries acceptance criteria.
- **Destructive git is stopped twice.** A regex hook catches force pushes, `reset --hard`, `clean -f`, and `rm -rf` including the short and combined flag forms; underneath it, `permissions.deny` rules and Claude Code's OS sandbox add a categorical layer where the platform supports it.

The mechanical parts are covered by a CI test suite, and the suite was validated end-to-end in a live project run — which doubled as a red-team: the model proposed routing around the write boundary through the shell ("the hook only watches Edit/Write"), and that path was closed the same day. The default posture is auto mode inside Claude Code's OS sandbox, with the enforcement layer itself behind an approval gate: edits to the hooks or settings prompt for human confirmation. The status line shows the live chain — `T3 ▸ 2/6 ▸ next: developer ▸ FAIL quality-gate:1` — straight from the manifest, at zero token cost.

## The team

Eleven agents. Seven run the chain: architect, ui-designer, developer, quality-gate, hunter (offensive security), defender (defensive security), docs. Four consultants sit outside the tiers: critic (fresh-eyes challenge to designs and reasoning), incident (production-failure perspective, live-incident triage and postmortems), optimizer (performance deep-dives), researcher (cited web research for technology decisions). Consultants inform, they don't gate — no verdicts, read-only, pulled in when a chain or the operator wants a second perspective.

Cost defaults are deliberate: the developer runs on Sonnet (the orchestrator may one-off override to Opus for genuinely complex tier 3-4 work, and says so), the routine gate reviews at medium effort, the security agents stay at high. Bootstrap asks before raising any of it.

## Engineering skills, read in two tiers

Each chain position maps to an engineering-lifecycle phase — define, plan, build, verify, review, ship — and each phase carries the practices that belong to it. The developer works under test-driven and incremental-implementation doctrine, the quality gate under code-review and simplification, the security agents under hardening. Nothing "calls" a skill: being the developer in the build phase means operating under those practices. The tier sets how many phases run, so it also sets how much doctrine applies.

The practices are 23 skill files vendored byte-for-byte from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT), so upstream updates re-pull cleanly — a monthly CI job watches for drift. Everything binding them to this framework lives in one bridge file, `INTEGRATION.md`. Each skill also carries a distilled ten-line **operating card**: agents read the card every time and open the full doctrine only when the card says to go deep. Depth is paid for when it matters, not on every invocation. Bootstrap works out which skills the project actually needs — a CLI tool doesn't need browser-testing — and deactivates the rest.

## Evidence over vibes

Every gate verdict lands in an append-only log, and every chain ends with a record — completed, with its FAIL-iteration count, or abandoned, with the reason (abandoned chains are evidence, not garbage). `/consolidate` turns the log into decisions: it reports whether the gates actually catch things — and whether a tier's ceremony earns its cost — and proposes promotions: a finding caught three times becomes a rule in the project conventions, so it stops happening instead of being caught again, and a corrected tier call becomes a casebook case. For spend, use Claude Code's `/usage` or the OTEL setup in `.claude/docs/telemetry.md`. The template deliberately reports no metrics of its own: estimated metrics dressed up as measurements are worse than none.

## Quick start

```bash
git clone https://github.com/Hub3r7/claude-code-orchestration-template.git

cp claude-code-orchestration-template/template/CLAUDE.md /path/to/your/project/
cp -r claude-code-orchestration-template/template/.claude /path/to/your/project/
# recommended: enable the hook suite, sandbox, and status line
cp /path/to/your/project/.claude/settings.template.json /path/to/your/project/.claude/settings.json

# verify the install
cd /path/to/your/project && bash .claude/scripts/doctor.sh
```

Then open Claude Code in the project and run `/bootstrap`. It asks about the project (stack, structure, conventions, what's sensitive), confirms what it understood, proposes a model for each agent and which skills to switch on, seeds the starter tier casebook, and fills in every `[PROJECT-SPECIFIC]` section. From there, tasks are classified and routed automatically.

Requirements: Claude Code (the template is built on its sub-agent system, hooks, and skills — it will not work with other AI tools or IDEs) and `jq` for the bash hooks; on Windows, run under WSL or Git Bash. The one-page [operator guide](template/.claude/docs/operator-guide.md) covers the daily commands, the status line, and what to do when a gate blocks something.

## Repository layout

- `template/` — the product: the `CLAUDE.md` and `.claude/` you copy into your project
- `scripts/` — the CI validators and the hook test suite
- `ROADMAP.md` — verification status, next steps, and deliberate non-goals

## Adapting it

The template ships as a single software-development team by design — one copy of the machinery that actually gets exercised. The earlier four-team layout (devops-sre, data-engineering, research-analysis) is preserved at the git tag [`four-teams`](../../tree/four-teams) as an adaptation reference. To adapt to another domain: rename the agents and adjust their roles, edit the tier table for the new workflow, update the bootstrap questions. The core protocols — handoff, PASS/FAIL, the knowledge hierarchy, agent notes — carry over unchanged; none of them are specific to software.

## Trade-offs

Multi-agent review costs more tokens than a single pass — that is the price of the depth. The tiers exist to scale that price to the risk and the operating cards cut the fixed overhead, but a tier 4 chain is still seven agent runs. Open items, pending verifications, and deliberate non-goals are tracked in [ROADMAP.md](ROADMAP.md).

## Credit and license

The engineering skills are vendored from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) by Addy Osmani (MIT). Credit to that project for the doctrine. Everything else is MIT as well; see [LICENSE](LICENSE).

Questions or feedback: hub3r7@pm.me
