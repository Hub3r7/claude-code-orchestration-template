# Project Context

*Quick-load context for new sessions. Full operational rules: `CLAUDE.md`. This file is generated during bootstrap — do not edit manually unless you know what you're doing.*

## What and Why

<!-- [PROJECT-SPECIFIC] Describe what the project does, who it is for, and primary design goals. -->

## Components

<!-- [PROJECT-SPECIFIC] Table of modules/components with status and purpose. Replace the example row. -->

| Component | Status | Purpose |
|-----------|--------|---------|
| _example_ | _planned_ | _Example component_ |

## Agent Team

| Agent | Role | When |
|-------|------|------|
| `architect` | Design + review chain selection | Tier 2-4 only |
| `ui-designer` | UI/UX design + accessibility | Tier 2-4 (UI changes only) |
| `developer` | Implementation | Tier 1-4 |
| `quality-gate` | Security + architecture review | Tier 1-4 (all code changes) |
| `hunter` | Attack surface / input analysis | Tier 3 (external I/O) and Tier 4 |
| `defender` | Defensive / artifact analysis | Tier 3 (data/artifacts) and Tier 4 |
| `docs` | Documentation | Always last in chain |
| `critic` | Consultant — fresh-eyes challenge of designs/reasoning | On demand, any tier |
| `incident` | Consultant — failure modes, rollback, live incidents | On demand, any tier |
| `optimizer` | Consultant — performance deep-dive | On demand, any tier |
| `researcher` | Consultant — evidence-based web research (cited) | On demand, any tier |

Review chains Tier 0-4. Architect enters from Tier 2. quality-gate mandatory from Tier 1. Tier 3 adds hunter OR defender depending on task type; Tier 4 adds both. Every review agent issues PASS or FAIL — FAIL loops back to developer, chain paused until PASS. Consultants are read-only advisors outside the tier table and never issue verdicts. Full table: `CLAUDE.md` → Dev Cycle.

## Skills

| Skill | Purpose |
|-------|---------|
| `/bootstrap` | Customize all `[PROJECT-SPECIFIC]` sections |
| `/tier-check` | Analyze task → recommend tier and chain |
| `/commit` | Conventional commit from current changes |
| `/push` | Push to remote with safety checks |
| `/re-review` | Re-run review chain (review only) |
| `/deep-analysis` | Deep project/subsystem analysis |

## Engineering Skills (active set)

<!-- [PROJECT-SPECIFIC] The engineering skills active for this project, chosen during bootstrap Phase 3b from the project profile. Agents in each phase operate under these as mandatory workflow. Full catalog and per-agent mapping: `.claude/agent-skills/README.md`. -->

| Phase | Active skills |
|-------|---------------|
| _PLAN_ | _e.g. planning-and-task-breakdown, spec-driven-development, api-and-interface-design_ |
| _BUILD/VERIFY_ | _e.g. incremental-implementation, test-driven-development, debugging-and-error-recovery_ |
| _REVIEW_ | _e.g. code-review-and-quality, code-simplification, security-and-hardening_ |
| _SHIP_ | _e.g. documentation-and-adrs, git-workflow-and-versioning_ |

_Inactive (vendored on disk but unused for this project):_ <!-- e.g. frontend-ui-engineering, browser-testing-with-devtools — no UI -->

## Key Architectural Decisions

<!-- [PROJECT-SPECIFIC] List decisions that shape the project's design (e.g., auth model, data flow, key trade-offs). -->

## Current Phase

<!-- [PROJECT-SPECIFIC] Describe what has been built so far and what is next. -->

## If Context Was Lost

New session or after compaction: read this file first, then `CLAUDE.md`. If `.agentNotes/chain-state.json` exists with an unfinished chain, a chain is in flight — resume position from it. The two together restore full orientation without re-reading source files. Agent instructions are in `.claude/agents/`.
