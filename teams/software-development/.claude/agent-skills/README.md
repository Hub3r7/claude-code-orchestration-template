# Engineering Skills (vendored reference knowledge)

These are **reference documents**, not orchestrator slash-commands. They encode
*how to do engineering work well* (the doctrine: TDD, incremental delivery, secure
design, code review, API design, etc.). Agents read the skill mapped to their role
when a task falls into that skill's domain — see the mapping below.

They are deliberately **not** placed under `.claude/skills/` (which Claude Code
auto-discovers as invokable slash-commands). Auto-activating skills would conflict
with the orchestrator's command namespace and violate the framework's core
principle *"explicit over magical"*. Here, the activation mechanism is an agent
explicitly reading the file at task start — deterministic and tier-aware.

## Provenance

- **Source:** [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)
- **Upstream commit:** `d187883b7d761265309cdcc0f202cc76b4b3fb06` (2026-06-11)
- **License:** MIT © 2025 Addy Osmani — see [`LICENSE.upstream`](LICENSE.upstream)
- **Vendored:** 8 of 24 upstream skills, as unmodified `SKILL.md` files.

Only the `SKILL.md` files were vendored. The upstream repo-level `references/`
directory was **not** copied, so any "See Also → `references/…`" pointers inside a
skill are dangling here; treat them as optional deep-dives available upstream.

To refresh against upstream, re-fetch the same paths at a newer commit and update
the commit hash above. CI does not pin these files, so a diff against upstream is a
manual step.

## Agent → skill mapping

| Agent | Consults | When |
|-------|----------|------|
| `architect` | `planning-and-task-breakdown`, `api-and-interface-design` | Decomposing work; designing component/API contracts |
| `ui-designer` | `frontend-ui-engineering` | UI/UX design and component work |
| `developer` | `test-driven-development`, `incremental-implementation` | Implementing logic, fixing bugs, shipping in slices |
| `quality-gate` | `code-review-and-quality` | Reviewing implemented code (Mode B) |
| `hunter` | `security-and-hardening` | Attack-surface analysis (offensive lens) |
| `defender` | `security-and-hardening` | Hardening assessment (defensive lens) |
| `docs` | `documentation-and-adrs` | Writing docs and architecture decision records |

## Knowledge hierarchy

These skills are **reference knowledge** (level 2), subordinate to everything above
them. When a skill conflicts with project authority, the higher level wins — always:

```
1. CLAUDE.md + agent .md instructions   ← authoritative
2. docs/project-rules.md                ← project conventions (set during bootstrap)
3. these engineering skills             ← general best-practice reference
4. .agentNotes/<agent>/notes.md         ← working memory
```

Skills illustrate principles with a specific stack (often TypeScript/npm/Jest). The
**principle** transfers; the concrete stack for this project is whatever
`docs/project-rules.md` defines. If a skill's example contradicts the project's
stack or conventions, follow the project — never reshape the project to match a
skill's example.
