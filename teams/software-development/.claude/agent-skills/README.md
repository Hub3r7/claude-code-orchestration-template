# Engineering Skills (vendored doctrine)

These encode *how to do engineering work well* — the lifecycle doctrine senior
engineers follow (spec before code, TDD, incremental delivery, secure design, review,
ship). They are **reference documents, not orchestrator slash-commands**: an agent
operates under the skills mapped to its phase as a mandatory part of its workflow,
not an optional lookup.

They live in `.claude/agent-skills/` (not `.claude/skills/`, which Claude Code
auto-discovers as slash-commands) on purpose. Activation is **structural, not
explicit**: an agent's position in the tier chain is a lifecycle phase, and each phase
carries its skills. Nobody "calls" a skill — being the developer in the BUILD phase
*means* operating under TDD and incremental-implementation. The tier scales how many
phases run, and therefore how much doctrine applies.

## Provenance

- **Source:** [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)
- **Upstream commit:** `d187883b7d761265309cdcc0f202cc76b4b3fb06` (2026-06-11)
- **License:** MIT © 2025 Addy Osmani — see [`LICENSE.upstream`](LICENSE.upstream)
- **Vendored:** 23 of 24 skills (all except the `using-agent-skills` meta-skill, whose
  discovery logic and Core Operating Behaviors are distilled into the team `CLAUDE.md`),
  plus all 5 upstream `references/` checklists (security, performance, accessibility,
  testing, orchestration) so every "See Also → `references/…`" link resolves.

How these skills bind to our framework — gates, canon, stack, and per-skill notes — is in
[`INTEGRATION.md`](INTEGRATION.md). To refresh, re-fetch the same paths at a newer commit
and bump the hash above. CI checks that `references/` links resolve and that every skill
named in an agent exists on disk; a deeper diff against upstream is a manual step.

## Lifecycle ↔ chain ↔ skills

Our tier chain *is* the engineering lifecycle. Each phase maps to the agent that runs
it and the skills that agent operates under:

| Phase | Agent(s) | Skills |
|-------|----------|--------|
| **DEFINE** | orchestrator (pre-chain) | `interview-me`, `idea-refine`, `context-engineering` |
| **PLAN** | architect | `planning-and-task-breakdown`, `api-and-interface-design`, `spec-driven-development` |
| **BUILD** | developer, ui-designer | `incremental-implementation`, `test-driven-development`, `source-driven-development`, `frontend-ui-engineering` |
| **VERIFY** | developer, ui-designer | `debugging-and-error-recovery`, `browser-testing-with-devtools` |
| **REVIEW** | quality-gate, hunter, defender | `code-review-and-quality`, `code-simplification`, `performance-optimization`, `security-and-hardening`, `observability-and-instrumentation` |
| **SHIP** | docs, orchestrator | `documentation-and-adrs`, `git-workflow-and-versioning`, `ci-cd-and-automation`, `shipping-and-launch`, `deprecation-and-migration` |

## Agent → skills (mandatory core + conditional)

Each agent operates under its **core** skills whenever it runs on non-trivial work.
**Conditional** skills apply when the named situation arises (the skill's own "Use when"
fires); they are still mandatory *when* they apply, not optional.

| Agent | Core | Conditional |
|-------|------|-------------|
| `architect` | `planning-and-task-breakdown`, `api-and-interface-design`, `spec-driven-development` | `deprecation-and-migration` (sunset/migration decisions) |
| `ui-designer` | `frontend-ui-engineering`, `browser-testing-with-devtools` | `api-and-interface-design` (consuming/defining an API) |
| `developer` | `incremental-implementation`, `test-driven-development` | `debugging-and-error-recovery` (something broke), `source-driven-development` (framework/library work), `deprecation-and-migration` (migration) |
| `quality-gate` | `code-review-and-quality`, `code-simplification` | `performance-optimization` (perf-sensitive change) |
| `hunter` | `security-and-hardening` (offensive lens) | — |
| `defender` | `security-and-hardening` (defensive lens) | `observability-and-instrumentation` (detection/audit coverage) |
| `docs` | `documentation-and-adrs` | — |

Orchestrator-level (not an agent), **actively triggered — not just "available":**
`interview-me` and `idea-refine` — the orchestrator **reads and follows** these on an
underspecified or vague ask, *before* classifying the tier (see CLAUDE.md → "Orchestrator
DEFINE-phase trigger"); `context-engineering` (session/context setup, or when output quality
degrades); `doubt-driven-development` (fresh-context adversarial review — the chain's
PASS/FAIL gates realize it structurally); and the SHIP automation skills
`git-workflow-and-versioning`, `ci-cd-and-automation`, `shipping-and-launch` — these inform
the `/commit`, `/push`, and release workflows. See [`INTEGRATION.md`](INTEGRATION.md) for why.

## Per-project activation (set during bootstrap)

The mapping above is the full catalog. Not every project needs every skill. During
bootstrap the orchestrator infers the **active set** from the project profile and
records it in `CLAUDE.md` + `.claude/docs/project-context.md`:

- **UI present** → `frontend-ui-engineering`, `browser-testing-with-devtools`, `ui-designer` active
- **HTTP/API or service** → `api-and-interface-design`
- **Runs in production / web** → `performance-optimization`, `observability-and-instrumentation`, `shipping-and-launch`
- **CLI tool or library** → frontend/browser skills inactive
- **Always active** → `planning-and-task-breakdown`, `spec-driven-development`, `incremental-implementation`, `test-driven-development`, `debugging-and-error-recovery`, `code-review-and-quality`, `code-simplification`, `security-and-hardening`, `documentation-and-adrs`, `git-workflow-and-versioning`

Inactive skills stay vendored on disk but are dropped from the agents' active mapping,
so an agent never reads doctrine that doesn't apply to the project.

## Knowledge hierarchy

Skills are **level-3 reference** — subordinate to everything above:

```
1. CLAUDE.md + agent .md instructions   ← authoritative
2. docs/project-rules.md                ← project conventions (set during bootstrap)
3. these engineering skills             ← lifecycle doctrine
4. .agentNotes/<agent>/notes.md         ← working memory
```

Skills illustrate principles with a specific stack (often TypeScript/npm/Jest). The
*principle* transfers; the project's actual stack is whatever `docs/project-rules.md`
defines. If a skill's example contradicts the project, follow the project — never
reshape the project to match a skill's example.
