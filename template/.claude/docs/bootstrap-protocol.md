# Bootstrap Protocol — From Generic to Project-Specific

This document defines the bootstrap conversation that the orchestrator (Claude Code) runs
when first setting up the agent framework for a new project.

**CRITICAL:** The orchestrator MUST execute every phase in sequence. This is a strict protocol,
not a reference to consult loosely. Skipping phases or reordering produces unstable results.

## Purpose

The framework ships with generic agent instructions containing `[PROJECT-SPECIFIC]`
placeholder sections. The bootstrap protocol replaces those placeholders with concrete,
project-specific rules through a structured conversation with the user.

## When to run

Run bootstrap when:
- Starting a new project with this framework
- `CLAUDE.md` still contains `[PROJECT-SPECIFIC]` placeholders
- The user invokes `/bootstrap` or says "bootstrap", "set up agents", or "configure for this project"

## File language rule

**All file content is always written in English** — regardless of what communication language the user prefers. This applies to: `CLAUDE.md`, all agent `.md` files, `project-context.md`, `bootstrap-protocol.md`, `.agentNotes/`, and any other file created or modified during bootstrap or normal operation.

The communication language (what the orchestrator says to the user) is separate and is determined in Phase 0 below.

## Bootstrap phases

### Phase 0 — Language Negotiation

Before anything else, ask the user in a neutral/common language (or detect from their message):

> "What language would you like me to communicate in during this session?"

Record the answer. Use that language for all conversation with the user throughout bootstrap and normal operation. All file content remains in English regardless of the answer.

If the user's message is already in a specific language, match it and confirm: "I'll communicate in [language]. All file content will be written in English."

Per-user preferences like communication language belong in the user's own layer —
`~/.claude/settings.json` (`"language"`) or a gitignored `CLAUDE.local.md` — never in
the shared project files. If the user asks to persist such a preference, point them
there; a teammate cloning the project must not inherit it.

### Phase 1 — Project Discovery (orchestrator ↔ user)

**Before asking anything, survey the repository inline:** `Glob` the tree, `Read` the
README, the manifests (package.json / pyproject.toml / go.mod / …), and the test layout.
Use what you find to pre-fill your understanding and skip questions the repo already
answers. **Do not spawn a subagent for the survey** — bootstrap runs in the main session;
delegating the survey has failed in practice (malformed Task parameters) and costs more
than it returns.

Then ask the user about the project. Cover these topics (adapt phrasing naturally):

1. **What is the project?** — Name, purpose, who is it for, what problem does it solve.
2. **Tech stack** — Language(s), framework(s), runtime, package manager, database (if any).
3. **Architecture** — Monolith vs microservices, directory structure, component model, module/plugin system.
4. **Environment** — How to set up locally, how to run, how to test, virtual environments, CI/CD.
5. **Conventions** — Naming rules, code style, commit conventions, existing patterns.
6. **Security posture** — What is sensitive? Auth model? External integrations? Data handling?
7. **Special principles** — Any project-specific non-negotiables (e.g., operator anonymity, zero-trust, offline-first).

Do NOT ask all 7 at once. Start with 1-3 and let the conversation flow. Ask follow-ups
based on answers. The goal is understanding, not interrogation.

### Phase 1b — Agent Consultation (optional)

If the orchestrator judges that a specific agent's domain expertise would sharpen project
understanding, it MAY invoke that agent with targeted questions — e.g., architect for
architecture clarity, security agent for threat model assessment.

**Rules:**
- This is NOT mandatory — only use when user answers leave gaps in a specific domain.
- Not every agent needs to be consulted — only the ones relevant to the gap.
- The agent provides domain-specific follow-up questions; the orchestrator relays them to the user.
- The orchestrator remains the single point of contact with the user throughout.
- When consulting an agent, call the Agent tool with exactly two inputs: `subagent_type`
  (one of the team's agents, by name) and a plain-text prompt containing the questions.
  Nothing else — malformed parameters are the most common bootstrap failure.

### Phase 2 — Confirmation

Summarize what you learned in a structured format:

```
PROJECT PROFILE
===============
Name:           <name>
Type:           <CLI tool / web app / API service / library / etc.>
Stack:          <language, framework, key deps>
Architecture:   <brief structural description>
Environment:    <how to run, test, build>
Conventions:    <key naming/style rules>
Security:       <key security considerations>
Principles:     <project-specific non-negotiables>
```

Present the profile **as a normal assistant message first**, then ask: "Does this capture
the project correctly? Anything to add or change?"

If you ask for the confirmation through a question dialog (AskUserQuestion), embed the
full profile block inside the question text itself — text emitted between tool calls may
not be rendered in the console, and the user must see what they are confirming.

### Phase 3 — Model Assignment

Discuss model selection for each agent with the user. The goal is to balance capability
against cost — not every agent needs the most powerful (and expensive) model.

**Available models (ordered by capability and cost):**
- **Opus** — Most capable, highest cost. Best for complex reasoning, design, and implementation.
- **Sonnet** — Strong balance of capability and cost. Good for review, analysis, and structured tasks.
- **Haiku** — Fast and cheapest. Suitable for straightforward, well-defined tasks.

**Default recommendation for this team:**

```
MODEL ASSIGNMENT (default)
==========================
architect       Opus      (complex design decisions, tier selection)
ui-designer     Sonnet    (UI/UX design with clear patterns)
developer       Sonnet    (cost-aware default; orchestrator may one-off override to Opus for complex Tier 3-4 work)
quality-gate    Sonnet    (structured review with clear criteria)
hunter          Sonnet    (security analysis with defined patterns)
defender        Sonnet    (defensive review with defined patterns)
docs            Sonnet    (documentation with clear templates)
critic          Sonnet    (adversarial reasoning review — consultant)
incident        Sonnet    (failure-mode analysis with clear checklists — consultant)
optimizer       Sonnet    (perf analysis with defined patterns — consultant)
researcher      Sonnet    (systematic web research with citations — consultant)
```

**Present this table to the user and ask:**
1. "Here is the recommended model assignment. Do you want to adjust any agent's model?"
2. If the user wants to minimize costs: suggest downgrading architect to Sonnet (if project
   is straightforward).
3. If the user wants maximum quality: suggest upgrading developer to Opus permanently, and
   quality-gate to Opus with `effort: high`.
4. Ask about review effort: quality-gate ships with `effort: medium` (routine correctness
   gate). Offer `effort: high` for security- or correctness-critical projects. hunter and
   defender always stay at `effort: high`.

**After confirmation**, record the final assignment in `CLAUDE.md` under the Agent Team table
and in each agent's `.md` file header.

**Cost awareness rule:** The orchestrator should mention approximate relative cost:
Opus ≈ 3× Sonnet ≈ 15× Haiku. This helps users make informed trade-offs.

### Phase 3b — Skill Activation

The team ships 23 vendored **engineering skills** in `.claude/agent-skills/` (the full
catalog and per-agent mapping are in `.claude/agent-skills/README.md`). Not every project
needs every skill. The orchestrator infers the **active set** from the project profile
gathered in Phases 1–2, proposes it, and the user confirms or adjusts.

**Inference rules (derive from the profile, do not ask separately):**

- **Always active** (every software project): `planning-and-task-breakdown`, `spec-driven-development`, `incremental-implementation`, `test-driven-development`, `debugging-and-error-recovery`, `code-review-and-quality`, `code-simplification`, `security-and-hardening`, `documentation-and-adrs`, `git-workflow-and-versioning`, `context-engineering`.
- **Has a UI / user-facing frontend** → add `frontend-ui-engineering`, `browser-testing-with-devtools`; the `ui-designer` agent is active. Otherwise these are inactive and ui-designer is dormant.
- **Exposes or consumes an HTTP/RPC API, or has module boundaries that matter** → add `api-and-interface-design`.
- **Runs in production / is a long-lived service or web app** → add `performance-optimization`, `observability-and-instrumentation`, `shipping-and-launch`, `ci-cd-and-automation`.
- **Will retire or migrate existing systems** → add `deprecation-and-migration`.
- **DEFINE helpers** `interview-me` and `idea-refine` are orchestrator-level and always available for underspecified or vague asks — no activation needed.

**Present the proposed active set grouped by lifecycle phase** (PLAN / BUILD-VERIFY /
REVIEW / SHIP), name what was left **inactive** and why (e.g. "no UI → frontend and
browser-testing skills inactive"), and ask: *"Does this match how you want the agents to
work? Anything to switch on or off?"*

Record the confirmed active set in Phase 4 (in `CLAUDE.md` and `project-context.md`).
Inactive skills stay vendored on disk but are dropped from the agents' active mapping, so
no agent reads doctrine that does not apply to the project.

### Phase 3c — Casebook Seeding

Tier calibration should not start from zero. From the project profile, derive **3-5
project-specific tier cases** — the changes this particular project will actually see,
classified by ITS risk topology. Examples of the pattern (do not copy literally):

- a web app with auth: "any change under the session/auth middleware" → Tier 4
- a CLI tool with a config parser: "new config key with validation" → Tier 2
- a data pipeline: "schema change in the events table" → Tier 3 (persistence)

Present the proposed cases with one-line rationales for user confirmation. On approval,
append each to `.claude/docs/tier-casebook.md` (Project-specific cases table) AND as a
record in `tier-casebook.jsonl` with `"source": "bootstrap"` and the project name —
schema in `casebook-format.md`. Skip silently only if the user declines.

### Phase 4 — Agent Specialization

Once confirmed, update the following files by replacing `[PROJECT-SPECIFIC]` sections:

1. **`CLAUDE.md`** — Fill in:
   - Project description
   - Architecture section (directory structure, component model)
   - Project-specific principles
   - Language & style
   - Naming conventions
   - Testing (test runner, directory structure, coverage expectations)
   - Environment section
   - What NOT to do (project-specific additions)
   - Current status
   - Response language (the language determined in Phase 0 — write the language name in English, e.g. "Communicate with the user in Spanish.")
   - The **active engineering skill set** from Phase 3b — record it in the "Engineering Skills" section (mark inactive skills and why).

2. **`.claude/agents/architect.md`** — Add:
   - Project-specific review criteria (what to check during design review)
   - Component contract details (if the project has a module/plugin system)

3. **`.claude/agents/ui-designer.md`** — Add:
   - Design system, component library, breakpoints, color palette, typography
   - Accessibility standards and requirements

4. **`.claude/agents/developer.md`** — Add:
   - Project-specific implementation rules
   - Framework conventions, file patterns, import rules

5. **`.claude/agents/quality-gate.md`** — Add:
   - Project-specific security review criteria
   - Framework-specific vulnerability patterns (e.g., XSS for web, injection for APIs)

6. **`.claude/agents/hunter.md`** — Add:
   - Project-specific attack surface areas
   - Technology-specific vulnerability classes to watch for

7. **`.claude/agents/defender.md`** — Add:
   - Project-specific defensive review criteria
   - Data integrity, logging, and audit trail expectations

8. **`.claude/agents/docs.md`** — Add:
   - Documentation templates for the project's component type
   - What documents to maintain and their update triggers

9. **`.claude/docs/project-context.md`** — Fill in all sections, including the "Engineering Skills (active set)" table from Phase 3b (must match the active set written to `CLAUDE.md`).
10. **`docs/project-rules.md`** — Create this file during bootstrap with project-specific implementation rules extracted from CLAUDE.md. Move detailed conventions (language & style, naming, testing, environment, what NOT to do) here. This keeps CLAUDE.md lean for the orchestrator while agents get full rules.
11. **Agent self-load update** — After creating `docs/project-rules.md`, update every agent's `## Before any task` section to include:
    ```
    1. Read `CLAUDE.md` for project principles and chain rules.
    2. Read `docs/project-rules.md` for implementation conventions.
    ```
    Agents that also need `docs/command-conventions.md` or equivalent should list it as item 3.

### Phase 5 — Verification

After updating all files:
1. Read back each modified file to verify no `[PROJECT-SPECIFIC]` placeholders remain (check `CLAUDE.md`, all 7 agent files under `.claude/agents/`, `.claude/docs/project-context.md`, AND `docs/project-rules.md`)
2. Verify consistency across files (same architecture description, same conventions, and the **active engineering skill set is identical** in `CLAUDE.md` and `project-context.md`)
3. Report to the user:

```
BOOTSTRAP COMPLETE
==================
Updated: CLAUDE.md, 7 agent files, project-context.md, project-rules.md
Active engineering skills: <N> of 23 (inactive: <list or "none">)
Remaining placeholders: 0
Ready to start development.
```

## Bootstrap principles

- **Listen first, configure second.** Never assume — always ask.
- **Minimal viable specificity.** Don't over-specify. Leave room for the agents to adapt through iteration. Add only what is known now, not what might be needed later.
- **Consistency is king.** The same fact must not be described differently in two files.
- **User approves.** Show the profile before writing. Don't silently customize.
- **Iterative refinement.** Bootstrap doesn't have to be perfect on the first pass. The agents will learn through their notes and the framework will improve through real use.

## Re-bootstrap

If the project evolves significantly (new language, new architecture, major pivot):
- The user can say "re-bootstrap" to run the protocol again
- Previous project-specific content is shown for comparison
- Only changed sections are updated (preserve what still applies)

## Troubleshooting the setup

- Run `/memory` to verify which CLAUDE.md and `.claude/rules/` files actually loaded —
  a rule that isn't listed there isn't in context.
- For deeper debugging of path-scoped rules, register an `InstructionsLoaded` hook to
  log exactly which instruction files load and when.
