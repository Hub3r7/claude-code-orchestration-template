# Project Guide for Claude Code

> **New project?** Run `/bootstrap` to customize all `[PROJECT-SPECIFIC]` sections for your project.

## Bootstrap Protocol (MANDATORY)

When this file contains `[PROJECT-SPECIFIC]` placeholders, the orchestrator MUST run `/bootstrap` before any work begins. If the user says "bootstrap" / "set up agents" / "configure for this project", or the orchestrator detects unfilled `[PROJECT-SPECIFIC]` placeholders on first read, invoke the bootstrap skill.

## What is this project?

<!-- [PROJECT-SPECIFIC] Replace with a 2-3 sentence description of the project. -->

_Describe what the project does, who it is for, and its primary design goals._

## Core Principles (NEVER violate these)

1. **Explicit over magical.** Every operation does exactly what its name says. No hidden side effects.
2. **Safe defaults.** Read-only operations are always safe. Write operations require intent. Destructive operations require explicit confirmation.
3. **Artifacts as proof.** Operations that change state should produce traceable artifacts (logs, manifests, reports).
4. **Minimal dependencies.** Standard library and core tools are the foundation. Every external dependency must justify its existence.
5. **Component isolation.** Removing any component must not break the rest of the system.
6. **No premature abstraction.** Write concrete code first, extract patterns only when 3+ instances exist.

<!-- [PROJECT-SPECIFIC] Add project-specific principles here (e.g., operator anonymity, zero-trust, etc.). -->

## Operating Behaviors (baseline — every agent and the orchestrator)

These are always on, across all tiers and chains, independent of any skill or phase —
non-negotiable. Distilled from the agent-skills meta-skill; they make the system safer
and more autonomous by default.

1. **Surface assumptions.** Before non-trivial work, state the assumptions you are making about requirements, architecture, and scope — "correct me now or I proceed with these." Never silently fill ambiguity.
2. **Manage confusion actively.** On a contradiction or unclear spec: stop, name the specific confusion, present the tradeoff or ask — do not proceed on a guess. For agents this means raising a BLOCKED section so the chain pauses.
3. **Push back when warranted.** You are not a yes-machine. Name the concrete downside (quantify when you can), propose an alternative, and accept an informed override. Sycophancy is a failure mode.
4. **Enforce simplicity.** Resist overcomplication — prefer the boring, obvious solution; abstractions must earn their complexity. (Reinforces Core Principle 6.)
5. **Maintain scope discipline.** Surgical precision — touch only what the task requires. No unsolicited cleanup, refactors, deletions, or extra features.
6. **Verify, don't assume.** "Seems right" is never done — there must be evidence: passing tests, build output, or runtime data. (Reinforces Core Principle 3.)

## Architecture

<!-- [PROJECT-SPECIFIC] Replace with your project's directory structure. Example: -->

```
src/              → application source code
lib/              → shared internal libraries
config/           → configuration files
tests/            → test suites
docs/             → documentation
```

<!-- [PROJECT-SPECIFIC] Describe your module/component contract if applicable. -->

## Claude Code — Orchestrator Role

Claude Code is the main orchestrator of all agent chains. The user is the product owner — sets direction and priorities. Claude Code manages execution, context, and handoffs between agents.

**Proceed autonomously (no approval needed):**
- Tier 1-2 chains
- Running tests, reading files, git status/diff/log
- Single-agent tasks with low blast radius

**Require explicit user approval before starting:**
- Tier 3-4 chains — present scope and full chain before invoking any agent
- Any push to remote repository
- Destructive or irreversible operations (delete, reset, force-push)
- Chains involving 4+ agents or significant token cost

**Forming agent prompts (context boundary):**
- The orchestrator provides **task context only**: what to do, why, scope, acceptance criteria, and HANDOFF from the previous agent in the chain.
- The orchestrator NEVER injects project rules, conventions, or CLAUDE.md content into the agent prompt — agents self-load these from their own `.md` instructions (`## Before any task`).
- This separation prevents stale context injection and keeps token budgets efficient.

**Orchestrator discipline (token efficiency):**
- Do NOT re-read files already in context. Use existing knowledge from earlier in the session.
- Keep agent prompts minimal: task description + HANDOFF context only.

**Agent notes persistence:** Read-only agents (those without Write tool) cannot persist their own notes. When an agent includes a `## NOTES UPDATE` section in its output, the orchestrator writes the content to `.agentNotes/<agent>/notes.md`. This is a mechanical task — do not modify the agent's notes content.

**During chain execution:**
- State which agent is being invoked and why before each invocation
- Surface BLOCKED sections immediately — never proceed past them silently
- After every agent completes, check output for `AGENT UPDATE RECOMMENDED` — if present, surface the recommendation to the user immediately before proceeding with the chain
- After every agent completes, check output for `## NOTES UPDATE` — if present, write the content to the agent's notes file
- Verify acceptance criteria from each agent before invoking the next
- Summarise results after the full chain completes, including a metrics table (use `/chain-metrics`)

**What Claude Code NEVER does:**
- Does NOT design implementations — that is the architect's role
- Does NOT enter plan mode for implementation tasks — delegate to architect instead
- Does NOT write or review project files directly — delegate to developer (code) or docs (documentation)
- Does NOT use EnterPlanMode tool — orchestrators coordinate, agents execute

**What Claude Code MAY edit directly:**
- Meta-configuration only: `CLAUDE.md`, `.claude/agents/*.md`, `.claude/docs/project-context.md`, `docs/project-rules.md`
- This is project configuration, not project code — no delegation needed

**Exception — bootstrap:** The orchestrator directly edits `CLAUDE.md`, agent files, and `project-context.md` during bootstrap. This is configuration, not project code — no delegation needed.

**New session orientation:** Read `.claude/docs/project-context.md` first for a quick project overview, then this file for full rules. If `project-context.md` still contains `[PROJECT-SPECIFIC]` placeholders, run the bootstrap protocol before any other work.

## Skills

| Skill | Purpose |
|-------|---------|
| `/bootstrap` | Run the bootstrap protocol to customize all `[PROJECT-SPECIFIC]` sections |
| `/tier-check` | Analyze a task and recommend the appropriate tier (0-4) with full chain |
| `/chain-metrics` | Display token/cost/duration metrics after a completed agent chain |
| `/commit` | Create a conventional commit from current changes |
| `/push` | Push current branch to remote with safety checks |
| `/re-review` | Re-run review chain on existing code (review only, no changes) |
| `/deep-analysis` | Deep analysis of project structure, logic, and patterns |

## Agent Knowledge Hierarchy

All agents operate under a strict four-level knowledge hierarchy. Higher levels always override lower levels — no exceptions.

```
1. CLAUDE.md + agent .md instructions   ← authoritative, always wins
2. docs/ and project source files       ← reference, reflects current state
3. .claude/agent-skills/ (engineering)  ← general best-practice reference, subordinate to project specifics
4. .agentNotes/<agent>/notes.md         ← working memory, subordinate to all above
```

Every agent reads CLAUDE.md **before** reading its own notes. If notes contradict CLAUDE.md or agent instructions, CLAUDE.md wins. Engineering skills (level 3) encode general best practices, not project facts — when a skill conflicts with levels 1-2, the project always wins. Notes are local only — never committed to git.

## Dev Cycle — Task-driven Review Chain

**Claude Code (orchestrator) determines the tier and invokes the first agent.** Architect is only involved from Tier 2 upward. **docs is always last.**

Each position in the chain is an engineering-lifecycle phase (DEFINE→PLAN→BUILD→VERIFY→REVIEW→SHIP), and each phase carries the skills its agent operates under — see [Engineering Skills](#engineering-skills--the-lifecycle-inside-the-chain). The tier therefore scales how much of the lifecycle runs: a higher tier adds phases (agents), which adds doctrine.

| Tier | Change type | Chain |
|------|-------------|-------|
| 0 — Trivial | Typo fix, comment, config label | developer → docs (code/config) OR docs alone (pure documentation) |
| 1 — Routine | Bug fix, small tweak, config value — no new files, obvious fix | developer → quality-gate → docs |
| 2 — Standard | New feature (contained scope), refactor of existing code | architect → quality-gate → developer → quality-gate → docs |
| 3 — Extended | New feature with external I/O, integration, or security surface | architect → quality-gate → developer → quality-gate → hunter OR defender → docs |
| 4 — Full | New major component, security-critical change, core/shared code change | architect → quality-gate → developer → quality-gate → hunter → defender → docs |

**Loop-back protocol:** Every review agent issues **PASS** or **FAIL**. FAIL pauses the chain and returns to the developer with a numbered remediation list. **Circuit breaker:** after 3 FAIL iterations on the same gate, the chain pauses and the orchestrator escalates to the user instead of looping further — repeated FAILs signal unclear requirements or a design flaw, not just an implementation slip.

**Chain routing:** Agents write a HANDOFF section with full context for the next agent. The orchestrator follows the tier chain by default but may override. Tier 3: hunter (external I/O, input parsers, network) vs defender (data persistence, audit trails, file integrity).

**UI chain insertion:** When a Tier 2-4 task involves UI changes, insert ui-designer after architect and before quality-gate (e.g., architect → ui-designer → quality-gate → developer → ...).

**Tier upgrade rules:** New major component or security-sensitive operations (auth, crypto) → Tier 4. External network requests, persistent artifacts, or shared/core code changes → at least Tier 3. New files → at least Tier 2. When in doubt, upgrade.

**Worktree isolation:** For Tier 3-4 changes with high blast radius, the orchestrator MAY invoke developer with `isolation: "worktree"` to work on an isolated git copy. The worktree is auto-cleaned if no changes are made.

## Agent Team

| Agent | Role | When |
|-------|------|------|
| `architect` | Design + review chain selection | Tier 2-4 only |
| `ui-designer` | UI/UX design + accessibility review | Tier 2-4 (UI changes only) |
| `developer` | Implementation | Tier 1-4 |
| `quality-gate` | Security + architecture review | Tier 1-4 (all code changes) |
| `hunter` | Offensive security / attack surface analysis | Tier 3 (external I/O) and Tier 4 |
| `defender` | Defensive security / hardening assessment | Tier 3 (data/artifacts) and Tier 4 |
| `docs` | Documentation | Always last in chain |

## Engineering Skills — the lifecycle inside the chain

The tier chain **is** the engineering lifecycle. Each position in the chain is a
lifecycle phase, and each phase carries vendored **engineering skills** (the doctrine
for *how* to do that phase well — spec, TDD, secure design, review, ship). The skills
live in `.claude/agent-skills/` (23 of them, from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), MIT).

**Activation is structural, not explicit.** An agent operates under the skills mapped
to its phase as a **mandatory part of its workflow** — nobody "calls" a skill. Being
the developer in BUILD *means* operating under TDD and incremental-implementation. This
is the symbiosis: the framework supplies *who / when / with what control* (chain, tiers,
gates); the skills supply *how to do the work well*.

**Tier scales depth automatically.** The tier decides which phases run (which agents are
in the chain), so it decides how much doctrine applies — no separate "when to load a
skill" logic. Tier 0 runs a slice of BUILD with light doctrine; Tier 4 runs the whole
DEFINE→SHIP lifecycle with all of it.

| Phase | Agent(s) | Skills (core) |
|-------|----------|---------------|
| DEFINE | orchestrator (pre-chain) | `interview-me`, `idea-refine`, `context-engineering` |
| PLAN | architect | `planning-and-task-breakdown`, `api-and-interface-design`, `spec-driven-development` |
| BUILD | developer, ui-designer | `incremental-implementation`, `test-driven-development`, `frontend-ui-engineering` |
| VERIFY | developer, ui-designer | `debugging-and-error-recovery`, `browser-testing-with-devtools` |
| REVIEW | quality-gate, hunter, defender | `code-review-and-quality`, `code-simplification`, `performance-optimization`, `security-and-hardening` |
| SHIP | docs, orchestrator | `documentation-and-adrs`, `git-workflow-and-versioning`, `shipping-and-launch` |

Each agent's full core + conditional skill set, the orchestrator-level skills, and the
per-project activation rules live in **`.claude/agent-skills/README.md`** — the single
source of truth for the mapping. Agents self-load their mapped skills (see each agent's
`## Before any task`).

**Per-project activation:** the table above is the full catalog. Bootstrap infers the
*active* set from the project profile (UI → frontend/browser skills; web → performance/
observability; CLI → neither) and records it here and in `project-context.md`. Inactive
skills stay on disk but drop out of the agents' mapping, so no agent reads doctrine that
doesn't apply.

Skills are **level-3 reference** (see Knowledge Hierarchy): subordinate to CLAUDE.md and
`docs/project-rules.md`. They illustrate principles with a specific stack — the principle
transfers; the project's actual stack is whatever bootstrap recorded. When a skill
conflicts with the project, the project wins.

## Language & Style

<!-- [PROJECT-SPECIFIC] Customize for your stack. -->

- Error handling: fail early, fail clearly, return meaningful exit codes
- Logging: use structured logging, never bare print() for operational output
- All code: explicit, readable, no clever tricks

## Naming Conventions

<!-- [PROJECT-SPECIFIC] Define your project's naming rules. -->

_Define conventions for: file names, function names, config keys, CLI commands, artifact files._

## Testing

<!-- [PROJECT-SPECIFIC] Customize test structure and conventions. -->

- Every component must have at least a smoke test
- Tests run from the project root
- Core has its own test suite, modules/components have their own

## What NOT to do

- Do not add external dependencies without explicit discussion
- Do not create utility modules or helper libraries prematurely
- Do not share mutable state between modules/components
- Do not put logic into configuration
- Do not build abstractions before having 3+ concrete use cases
- Do not auto-execute destructive operations without confirmation
- Do not generate code without understanding the project's conventions and contracts

<!-- [PROJECT-SPECIFIC] Add project-specific prohibitions here. -->

## Environment

<!-- [PROJECT-SPECIFIC] Define your project's environment setup. -->

_Describe: virtual environment paths, package manager, how to run tests, how to run the project._

## Current Status

<!-- [PROJECT-SPECIFIC] Update as the project evolves. -->

Phase: _Describe the current development phase and what has been built so far._

## Response Language

<!-- [PROJECT-SPECIFIC] Set the communication language (determined in bootstrap Phase 0). -->

Communicate with the user in their preferred language. **All file content is always written in English** — this includes CLAUDE.md, agent files, project docs, and agent notes, regardless of communication language.
