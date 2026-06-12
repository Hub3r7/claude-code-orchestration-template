# Engineering Skills — How They Bind to This Framework

The vendored `SKILL.md` files and `references/` are **verbatim upstream snapshots**. They
describe engineering doctrine in the abstract — written for a generic agent, not for this
framework. This file is the **bridge**: it says how that doctrine binds to our chain,
gates, canon, and vocabulary. Read it alongside any skill you operate under.

It exists so we get both things at once: upstream stays faithful (refresh is a re-fetch),
and the skills still behave as a coherent part of *our* system rather than a library
bolted on beside it.

## Universal bridges (apply to every skill)

1. **A skill's "Verification" feeds our gate — it is not the finish line.** Every skill
   ends with a verification checklist. Here that checklist is an *input* to a PASS/FAIL
   verdict, not a self-contained goal. A developer's TDD verification is evidence the
   `quality-gate` weighs in Mode B; the **gate** issues PASS/FAIL, not the skill.

2. **No subagent spawning from inside an agent.** Some skills say "spawn a subagent to do
   X in a fresh context." Our agents *are* subagents — they cannot nest. The **orchestrator**
   owns that pattern: when a skill calls for fresh-context work, the agent surfaces it
   (HANDOFF, or a BLOCKED if it's a hard stop) and the orchestrator spawns the next agent.
   Ignore any literal "spawn a subagent" instruction when you are an agent.

3. **Stack examples are illustrative.** Skills illustrate with TypeScript/npm/Jest. The
   project's real stack lives in `docs/project-rules.md`. Follow the *principle*, translate
   the example. Never adopt a skill's stack just because the skill used it.

4. **Our canon wins over skill overlap.** Where a skill restates something `CLAUDE.md`
   already governs (Operating Behaviors, Core Principles), the framework is the canon and
   the skill is the *depth behind it*, not a competing rule. Specific overlaps are listed
   below.

5. **`references/` are deep-dives.** The five `references/*.md` checklists (security,
   performance, accessibility, testing, orchestration) are exhaustive supplements. Consult
   them when a skill points there and the work warrants the depth — they are not required
   reading for every task.

## Per-skill bridges (only where there is a specific binding)

| Skill | How it binds here |
|-------|-------------------|
| `doubt-driven-development` | **Orchestrator-level, not an agent's skill.** It needs genuine fresh-context review, which only the main session can spawn — an agent cannot nest one. Our chain already *is* doubt-driven: `quality-gate`, `hunter`, and `defender` are the fresh-context reviewers, and PASS/FAIL is the adversarial check. The orchestrator applies this skill by upgrading the tier or adding a review agent, never by an agent self-questioning in place. (For this reason it is **not** in any agent's mapped set.) |
| `test-driven-development` | The developer writes the failing test **inline**. Its "spawn a subagent to write the reproduction test" is an orchestrator option (a HANDOFF), not something the developer does itself. The RED→GREEN→REFACTOR loop and its verification feed `quality-gate`. |
| `code-simplification` | The depth behind Operating Behavior #4 (enforce simplicity) and Core Principle 6 (no premature abstraction). `quality-gate` applies it in Mode B. The canon is ours; the technique is the skill's. |
| `context-engineering` | Orchestrator-level: it governs how the orchestrator forms agent prompts — task context only, never injected project rules (see `CLAUDE.md` → "Forming agent prompts"). Reinforces our existing context-boundary discipline. |
| `interview-me`, `idea-refine` | Orchestrator-level DEFINE helpers for underspecified or vague asks. They realize Operating Behavior #1 (surface assumptions) *before* the chain starts. Not agent skills. |
| `security-and-hardening` | One skill, two lenses: `hunter` reads it **offensively** (where do these controls fail or get bypassed?), `defender` **defensively** (are they present, complete, observable?). `references/security-checklist.md` is the shared deep-dive. |
| `git-workflow-and-versioning`, `ci-cd-and-automation`, `shipping-and-launch` | SHIP-phase, orchestrator-level — they inform `/commit`, `/push`, and release decisions, not an in-chain agent. |
| `browser-testing-with-devtools` | Requires the chrome-devtools MCP server. If it isn't configured, `ui-designer`/developer fall back to the rest of the VERIFY doctrine and say so — they do not block on it. |

## What we deliberately did NOT change

- `SKILL.md` and `references/` are verbatim upstream — **never edited** — so a refresh is
  just a re-fetch at a newer commit. All adaptation lives in this file, the README mapping,
  and each agent's `## Before any task`.
- We did **not** trim stack examples or compress skills. This framework is quality-over-cost;
  the doctrine's depth is the point, not a token cost to minimize.
