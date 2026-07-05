<p align="center">
  <img src="assets/hero.svg" alt="Claude Code Orchestration Template — review scaled to the blast radius of the change" width="100%">
</p>

# Claude Code Orchestration Template

The orchestrator reads each task, rates how much it could break on a scale of 0 to 4, and routes it through the matching chain of agents. A typo runs one agent. A new security-critical component runs the whole chain: design, two review gates, offensive and defensive security in parallel, then docs. The higher the tier, the longer the chain.

```
 Tier 0    developer → docs
 Tier 1    developer → quality-gate → docs
 Tier 2    architect → quality-gate → developer → quality-gate → docs
 Tier 3    architect → quality-gate → developer → quality-gate → hunter / defender → docs
 Tier 4    architect → quality-gate → developer → quality-gate → hunter ∥ defender → docs
```

It's configuration, not code: one `CLAUDE.md` and a `.claude/` folder. Copy `template/` into your project, run `/bootstrap`, and start working. I built it for my own work and this is the third version. Sharing it in case it's useful, no expectations.

## The judgment layer

Running several agents on a codebase is the easy part. The judgment is the hard part: not wrapping a one-line fix in ceremony it doesn't need, and not letting a risky change through without the review it does.

The tier follows the risk. New files push a task to at least tier 2, external I/O or a new security surface to tier 3, a new major component or anything security-critical to tier 4. When the orchestrator is unsure between two, it picks the higher one. Borderline cases are calibrated by a casebook of worked examples — and every time you correct a tier decision, the case is appended, so classification converges on your project's instincts instead of drifting.

## Enforced, not promised

Earlier versions asked the model to follow the protocol and hoped. This version makes the protocol mechanical — a hook suite ships in `settings.template.json`:

- **Verdicts are mandatory.** A review agent cannot finish without an explicit PASS/FAIL verdict or a declared BLOCKED state. Every verdict is recorded.
- **The circuit breaker is physical.** After three FAILs on the same gate, the next re-review is blocked outright — the orchestrator has to escalate to you; it can't quietly keep looping.
- **Reviewers can't touch code.** `disallowedTools` keeps every gate and consultant read-only, down to shell redirects.
- **The orchestrator can't either.** A hook blocks main-session writes outside meta-configuration — code goes through the developer, or it doesn't go.
- **Chains survive long sessions.** A chain manifest holds tier, plan, and position; after a context compaction a hook re-injects it, so an in-flight chain resumes mechanically instead of being reconstructed from memory.
- **One semantic check.** A prompt hook on the small, cheap model verifies what regex can't: that a FAIL carries a numbered fix list and a PASS handoff carries acceptance criteria.
- **Destructive git is stopped twice.** A regex hook catches force pushes, `reset --hard`, `clean -f`, and `rm -rf` including the short and combined flag forms; underneath it, `permissions.deny` rules and Claude Code's OS sandbox add a categorical layer where the platform supports it.

The mechanical parts are covered by a CI test suite. The status line shows the live chain — `T3 ▸ 2/6 ▸ next: developer ▸ FAIL quality-gate:1` — straight from the manifest, at zero token cost.

## The team

Eleven agents. Seven run the chain: architect, ui-designer, developer, quality-gate, hunter (offensive security), defender (defensive security), docs. Four consultants sit outside the tiers: critic (fresh-eyes challenge to designs and reasoning), incident (production-failure perspective, live-incident triage and postmortems), optimizer (performance deep-dives), researcher (cited web research for technology decisions). Consultants inform, they don't gate — no verdicts, read-only, pulled in when a chain or you wants a second perspective.

Costs default sane: the developer runs on Sonnet (the orchestrator may one-off override to Opus for genuinely complex tier 3-4 work, and says so), the routine gate reviews at medium effort, the security agents stay at high. Bootstrap asks before raising any of it.

## Engineering skills, read in two tiers

Each chain position maps to an engineering-lifecycle phase — define, plan, build, verify, review, ship — and each phase carries the practices that belong to it. The developer works under test-driven and incremental-implementation doctrine, the quality gate under code-review and simplification, the security agents under hardening. Nothing "calls" a skill: being the developer in the build phase means operating under those practices. The tier sets how many phases run, so it also sets how much doctrine applies.

The practices are 23 skill files vendored byte-for-byte from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT), so upstream updates re-pull cleanly — a monthly CI job watches for drift. Everything binding them to this framework lives in one bridge file, `INTEGRATION.md`. Each skill also carries a distilled ten-line **operating card**: agents read the card every time and open the full doctrine only when the card says to go deep. Depth is paid for when it matters, not on every invocation. Bootstrap works out which skills your project actually needs — a CLI tool doesn't need browser-testing — and deactivates the rest.

## Evidence over vibes

Every gate verdict lands in an append-only log. Run `/consolidate` weekly: it reports whether the gates actually catch things — and whether a tier's ceremony earns its cost — and proposes promotions: a finding caught three times becomes a rule in your project conventions, so it stops happening instead of being caught again. For spend, use Claude Code's `/usage` or the OTEL setup in `.claude/docs/telemetry.md`. The template deliberately reports no metrics of its own — earlier versions had a skill that estimated them, and estimated metrics dressed up as measurements are worse than none.

## Quick start

```bash
git clone https://github.com/Hub3r7/claude-code-orchestration-template.git

cp claude-code-orchestration-template/template/CLAUDE.md /path/to/your/project/
cp -r claude-code-orchestration-template/template/.claude /path/to/your/project/
# recommended: enable the hook suite, sandbox, and status line
cp /path/to/your/project/.claude/settings.template.json /path/to/your/project/.claude/settings.json
```

Then open Claude Code in your project and run `/bootstrap`. It asks about your project (stack, structure, conventions, what's sensitive), confirms what it understood, proposes a model for each agent and which skills to switch on, and fills in every `[PROJECT-SPECIFIC]` section. After that, tasks get classified and routed on their own.

It needs Claude Code — it's built on its sub-agent system, hooks, and skills, so it won't work with other AI tools or IDEs. The hooks need `jq`.

## Adapting it

Earlier versions shipped four parallel teams; maintaining four copies of the machinery diluted the work into copies nobody ran, so the template is now the one team I actually use. The retired three (devops-sre, data-engineering, research-analysis) live at the git tag [`four-teams`](../../tree/four-teams) as adaptation references. To adapt to another domain: rename the agents and adjust their roles, edit the tier table for your workflow, update the bootstrap questions. Keep the core protocols — handoff, PASS/FAIL, the hierarchy, agent notes — and it holds together. None of this is specific to software.

## What to expect

A personal project in active use — rough edges included. It spends tokens: multi-agent review costs more than a single pass. The tiers scale that cost to the risk and the operating cards cut the fixed overhead, but a tier 4 chain is still seven agent runs — that's the trade for the depth. Open items, pending verifications, and deliberate non-goals live in [ROADMAP.md](ROADMAP.md).

## Credit and license

The engineering skills are vendored from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) by Addy Osmani (MIT). Credit to that project for the doctrine. Everything else is MIT as well; see [LICENSE](LICENSE).

Questions or feedback: hub3r7@pm.me
