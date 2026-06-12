# Claude Code Orchestration Template

A drop-in orchestration template for Claude Code. Copy a team into your project and get structured review chains, tiered escalation, and quality gates for your workflow domain — without writing any code. Everything lives in `CLAUDE.md` and `.claude/` files.

> **Requires Claude Code.** This framework uses Claude Code's sub-agent system
> (`.claude/agents/*.md` and `CLAUDE.md`). It does not work with other AI tools or IDEs.

> **Cost warning.** This framework uses multi-agent chains where each agent is a separate Claude API call. Depending on your model assignment (Opus/Sonnet/Haiku per agent) and task tier, a single workflow can consume significant tokens. The framework was designed with **quality over cost** in mind — every tier adds review depth, not shortcuts. During bootstrap, the orchestrator will discuss model assignment with you to help optimize costs for your use case.

> **Team maturity.** The `software-development` team has received the most attention and refinement so far. All other teams share the same core architecture and protocols but have not been tested in practice yet. They are structurally complete and ready to use, but expect to iterate on agent instructions as you work with them.

## Teams

| Team | Domain | Agents | Use case |
|------|--------|--------|----------|
| [software-development](teams/software-development/) | Software engineering | architect, ui-designer, developer, quality-gate, hunter, defender, docs | Building and maintaining software projects |
| [devops-sre](teams/devops-sre/) | Infrastructure & operations | architect, builder, reviewer, monitor, incident, security, docs | IaC, deployment, monitoring, incident response |
| [data-engineering](teams/data-engineering/) | Data pipelines & analytics | architect, builder, quality, analyst, security, optimizer, docs | ETL/ELT, data quality, pipeline development |
| [research-analysis](teams/research-analysis/) | Research & synthesis | planner, researcher, analyst, critic, visualizer, docs | Literature review, data analysis, reports |

## Quick start

1. **Pick a team** that matches your workflow domain.

2. **Copy the team files** into your project root:

   ```bash
   # Clone the framework
   git clone https://github.com/Hub3r7/claude-code-orchestration-template.git

   # Copy team files to your project (replace TEAM with your choice)
   TEAM=software-development
   cp claude-code-orchestration-template/teams/$TEAM/CLAUDE.md /path/to/your/project/
   cp -r claude-code-orchestration-template/teams/$TEAM/.claude /path/to/your/project/
   ```

   You need these in your project root:
   - `CLAUDE.md` — orchestrator rules and project config
   - `.claude/agents/` — agent definitions
   - `.claude/docs/` — bootstrap protocol and project context template
   - `.claude/skills/` — slash-command skills for the orchestrator
   - `.claude/hooks/` — lifecycle hook scripts
   - `.claude/rules/` — path-conditional rules

   Optionally, copy `settings.template.json` to `.claude/settings.json` to enable hooks.

3. **Open Claude Code** in your project and run:
   ```
   /bootstrap
   ```

4. **Answer the orchestrator's questions.** It will:
   - Ask your preferred communication language (all file content is always written in English)
   - Learn about your project/organization/context
   - Discuss model assignment (Opus/Sonnet/Haiku) for each agent to optimize costs
   - Fill all `[PROJECT-SPECIFIC]` sections in `CLAUDE.md` and all agent files
   - Generate `.claude/docs/project-context.md` for fast session orientation

5. **Start working.** The orchestrator automatically classifies tasks by tier, routes to the correct agent chain, and enforces quality gates.

## How it works

Every team follows the same core architecture:

**Tiered escalation** — Each task is classified by complexity (Tier 0-4). Simple changes get minimal review. Complex changes get the full agent chain. The depth of review matches the blast radius of the change.

**Quality gates with loop-back** — Review agents issue explicit PASS or FAIL verdicts. FAIL pauses the chain and returns work for fixes. The chain does not advance until PASS is issued. A circuit breaker escalates to the user after 3 FAIL iterations on the same gate, so a stuck loop never runs up cost indefinitely.

**HANDOFF protocol** — Every agent writes a structured handoff with context for the next agent. The orchestrator follows the tier chain by default but may override routing when needed.

**Bootstrap customization** — Generic `[PROJECT-SPECIFIC]` placeholders are replaced through a structured conversation, not a config file. Agents become specialists in your specific context.

**Agent notes** — Agents accumulate knowledge across sessions through `.agentNotes/<agent>/notes.md`. Notes are subordinate to `CLAUDE.md` (never override rules) but provide working memory that makes agents more effective over time. Read-only agents cannot write files directly — they include a `## NOTES UPDATE` section in their output and the orchestrator persists it on their behalf.

**Skills** — Every team includes slash-command skills (`/bootstrap`, `/tier-check`, `/chain-metrics`, `/commit`, `/push`, `/re-review`, `/deep-analysis`) that automate common orchestrator workflows.

**Engineering skills (software-development)** — Agents in the `software-development` team consult vendored best-practice doctrine (TDD, incremental delivery, secure design, code review, API design, ADRs) from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills). These are reference documents under `.claude/agent-skills/`, mapped one or two per agent and read only when a task enters that skill's domain — the *process* layer (who/when/with what control) gains a *knowledge* layer (how to do it well), without auto-activation. See `teams/software-development/.claude/agent-skills/README.md`.

**Role separation** — Agents have non-overlapping responsibilities. In `software-development` for example: `quality-gate` checks correctness and conventions, `hunter` does adversarial attack analysis, `defender` assesses system hardening. Each agent has an explicit "not in scope" boundary.

**Safety hooks** — Optional PreToolUse hooks block destructive git operations (force-push, reset --hard, etc.) before they execute.

**Read-only enforcement** — Review agents (those without Write/Edit in their tool list) also have `disallowedTools: [Edit, Write, Bash]` to prevent file modification through any means, including shell redirection.

## Team structure

Every team directory contains:

```
teams/<team-name>/
  CLAUDE.md                          → Project rules + orchestrator instructions
  .claude/
    agents/
      <agent-1>.md                   → Agent definition with role, constraints, protocols
      <agent-2>.md
      ...
    docs/
      bootstrap-protocol.md          → Bootstrap conversation protocol
      project-context.md             → Session orientation template
    skills/
      <skill-name>/SKILL.md          → Slash-command skills for the orchestrator
    hooks/
      <hook-script>.sh               → Lifecycle hook scripts (PreToolUse, etc.)
    rules/
      <rule>.md                      → Path-conditional rules (lazy-loaded)
    settings.template.json           → Recommended hooks/settings configuration
```

## Choosing a team

Pick the team closest to your primary workflow:

- **Building software?** → `software-development`
- **Managing infrastructure?** → `devops-sre`
- **Building data pipelines?** → `data-engineering`
- **Doing research?** → `research-analysis`

Each team is **completely standalone**. You only need the files from one team — no shared dependencies, no cross-team imports.

## Re-bootstrap

If your project evolves significantly, run `/bootstrap` again and the orchestrator will update the project-specific sections while preserving what still applies.

## Building your own team

Want a team for a domain not listed here? Use any existing team as a template:

1. Copy a team directory
2. Rename agents and adjust roles
3. Adapt the tier system for your workflow
4. Update the bootstrap protocol with relevant discovery questions
5. Keep the core protocols: HANDOFF, PASS/FAIL, knowledge hierarchy, agent notes

The framework is domain-agnostic — the protocols work for any structured workflow where multiple perspectives add value.

## Origin

This started as a personal setup for a project. The agent roles, tier boundaries, and loop-back rules were shaped by what actually went wrong during development — not planned upfront. It worked well enough that I extracted it into a standalone framework, then generalized it to non-software domains.

## License

MIT — see [LICENSE](LICENSE).

## Contact

Questions, feedback, or want to contribute? Reach out at **hub3r7@pm.me**.
