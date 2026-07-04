# Project Guide for Claude Code

> **New project?** Run `/bootstrap` to customize all `[PROJECT-SPECIFIC]` sections for your project.

## Bootstrap Protocol (MANDATORY)

When this file contains `[PROJECT-SPECIFIC]` placeholders, the orchestrator MUST run `/bootstrap` before any work begins. If the user says "bootstrap" / "set up agents" / "configure for this project", or the orchestrator detects unfilled `[PROJECT-SPECIFIC]` placeholders on first read, invoke the bootstrap skill.

## What is this project?

<!-- [PROJECT-SPECIFIC] Replace with a 2-3 sentence description of the project's data engineering scope — what data it processes, what pipelines it builds, and what downstream consumers it serves. -->

_Describe what data the project processes, what pipelines it builds, who consumes the output, and its primary design goals._

## Core Principles (NEVER violate these)

1. **Explicit over magical.** Every transformation does exactly what its name says. No hidden side effects.
2. **Safe defaults.** Read operations and dry runs are always safe. Write operations require intent. Destructive operations (DROP, TRUNCATE, DELETE) require explicit confirmation.
3. **Artifacts as proof.** Pipeline runs produce traceable artifacts (run logs, data quality reports, lineage records, row counts).
4. **Minimal dependencies.** Standard library and core tools are the foundation. Every external dependency must justify its existence.
5. **Pipeline isolation.** Removing any pipeline must not break other pipelines or downstream consumers.
6. **No premature abstraction.** Write concrete transformations first, extract patterns only when 3+ instances exist.
7. **Data integrity first.** No silent data loss, no silent type coercion, no silent NULL handling. Every transformation must be auditable.
8. **Idempotency by default.** Every pipeline step must produce the same result when re-run with the same input. Non-idempotent operations require explicit documentation and safeguards.

<!-- [PROJECT-SPECIFIC] Add project-specific principles here (e.g., data retention policy, compliance requirements, cost constraints, SLA commitments). -->

## Architecture

<!-- [PROJECT-SPECIFIC] Replace with your project's directory structure. Example: -->

```
pipelines/        → pipeline definitions and DAGs
transforms/       → transformation logic (SQL, Python, dbt models)
schemas/          → schema definitions, migrations, contracts
sources/          → source connector configurations
targets/          → output/sink configurations
quality/          → data quality rules and expectations
config/           → environment and pipeline configuration
tests/            → test suites
docs/             → documentation
```

<!-- [PROJECT-SPECIFIC] Describe your pipeline contract, data flow patterns, and component boundaries. -->

## Claude Code — Orchestrator Role

Claude Code is the main orchestrator of all agent chains. The user is the product owner — sets direction and priorities. Claude Code manages execution, context, and handoffs between agents.

**Proceed autonomously (no approval needed):**
- Tier 1-2 chains
- Running tests, reading files, git status/diff/log
- Single-agent tasks with low blast radius

**Require explicit user approval before starting:**
- Tier 3-4 chains — present scope and full chain before invoking any agent
- Any push to remote repository
- Destructive or irreversible operations (DROP, TRUNCATE, DELETE, schema migration)
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
- Summarise results after the full chain completes (for real token/cost data use `/usage` or OTEL telemetry — see `.claude/docs/telemetry.md`)

**What Claude Code NEVER does:**
- Does NOT design pipelines or schemas — that is the architect's role
- Does NOT enter plan mode for implementation tasks — delegate to architect instead
- Does NOT write or review project files directly — delegate to builder (code) or docs (documentation)
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
| `/commit` | Create a conventional commit from current changes |
| `/push` | Push current branch to remote with safety checks |
| `/re-review` | Re-run review chain on existing code (review only, no changes) |
| `/deep-analysis` | Deep analysis of project structure, logic, and patterns |

## Agent Knowledge Hierarchy

All agents operate under a strict three-level knowledge hierarchy. Higher levels always override lower levels — no exceptions.

```
1. CLAUDE.md + agent .md instructions   ← authoritative, always wins
2. docs/ and project source files       ← reference, reflects current state
3. .agentNotes/<agent>/notes.md         ← working memory, subordinate to all above
```

Every agent reads CLAUDE.md **before** reading its own notes. If notes contradict CLAUDE.md or agent instructions, CLAUDE.md wins. Notes are local only — never committed to git.

## Dev Cycle — Task-driven Review Chain

**Claude Code (orchestrator) determines the tier and invokes the first agent.** Architect is only involved from Tier 2 upward. **docs is always last.**

| Tier | Change type | Chain |
|------|-------------|-------|
| 0 — Trivial | Doc edit, comment, config label | builder → docs (code/config) OR docs alone (pure documentation) |
| 1 — Routine | Minor transform fix, config change, no new data sources | builder → quality → docs |
| 2 — Standard | New transformation, refactor existing pipeline, new validation rule | architect → quality → builder → quality → docs |
| 3 — Extended | New data source integration, new output target, schema migration | architect → quality → builder → quality → security OR optimizer → docs |
| 4 — Full | New pipeline, new data domain, PII handling, cross-system integration | architect → quality → builder → quality → security → optimizer → docs |

**Loop-back protocol:** Every review agent issues **PASS** or **FAIL**. FAIL pauses the chain and returns to the builder with a numbered remediation list. **Circuit breaker:** after 3 FAIL iterations on the same gate, the chain pauses and the orchestrator escalates to the user instead of looping further — repeated FAILs signal unclear requirements or a design flaw, not just an implementation slip.

**Chain routing:** Agents write a HANDOFF section with full context for the next agent. The orchestrator follows the tier chain by default but may override. Tier 3: security (PII, compliance, access control) vs optimizer (performance, cost, query optimization).

**Tier upgrade rules:** New pipeline or data domain → Tier 4. PII or compliance-sensitive data → Tier 4. New external data source, production writes, or schema migrations → at least Tier 3. When in doubt, upgrade.

## Agent Team

| Agent | Role | When |
|-------|------|------|
| `architect` | Pipeline design, schema design, data modeling, technology selection | Tier 2-4 only |
| `builder` | ETL/ELT implementation, pipeline code, transformations | Tier 1-4 |
| `quality` | Data quality checks, validation, testing, schema verification | Tier 1-4 (all code changes) |
| `analyst` | Exploratory analysis, SQL review, business logic validation | On user request only |
| `security` | PII detection, access control, GDPR/compliance, data masking | Tier 3 (PII/compliance) and Tier 4 |
| `optimizer` | Performance tuning, partitioning, cost optimization, query optimization | Tier 3 (performance) and Tier 4 |
| `docs` | Data dictionary, lineage docs, pipeline docs, runbooks | Always last in chain |

## Language & Style

<!-- [PROJECT-SPECIFIC] Customize for your stack (e.g., SQL dialect, Python version, dbt, Spark, Airflow). -->

- Error handling: fail early, fail clearly, return meaningful exit codes
- Logging: use structured logging, never bare print() for operational output
- SQL: explicit column lists, no SELECT *, meaningful aliases, consistent formatting
- All code: explicit, readable, no clever tricks
- Transformations: document business logic in comments, not just technical steps

## Naming Conventions

<!-- [PROJECT-SPECIFIC] Define your project's naming rules. -->

_Define conventions for: table names, column names, pipeline names, transformation files, schema versions, artifact files._

## Testing

<!-- [PROJECT-SPECIFIC] Customize test structure and conventions. -->

- Every pipeline must have at least a smoke test
- Every transformation must have input/output validation
- Data quality rules must be testable independently
- Schema changes must have migration tests
- Tests run from the project root

## What NOT to do

- Do not add external dependencies without explicit discussion
- Do not create utility modules or helper libraries prematurely
- Do not share mutable state between pipelines
- Do not put business logic into configuration
- Do not build abstractions before having 3+ concrete use cases
- Do not auto-execute destructive operations (DROP, TRUNCATE, DELETE) without confirmation
- Do not generate pipeline code without understanding the project's conventions and contracts
- Do not silently drop, coerce, or modify data without explicit documentation
- Do not bypass data quality checks, even in development
- Do not hardcode credentials, connection strings, or environment-specific values

<!-- [PROJECT-SPECIFIC] Add project-specific prohibitions here. -->

## Environment

<!-- [PROJECT-SPECIFIC] Define your project's environment setup. -->

_Describe: virtual environment paths, package manager, how to run tests, how to run pipelines locally, database connections, orchestration tool setup._

## Current Status

<!-- [PROJECT-SPECIFIC] Update as the project evolves. -->

Phase: _Describe the current development phase, what pipelines are built, and what is next._

## Response Language

<!-- [PROJECT-SPECIFIC] Set the communication language (determined in bootstrap Phase 0). -->

Communicate with the user in their preferred language. **All file content is always written in English** — this includes CLAUDE.md, agent files, project docs, and agent notes, regardless of communication language.
