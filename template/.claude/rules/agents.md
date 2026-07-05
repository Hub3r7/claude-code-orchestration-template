---
globs: .claude/agents/*.md
---

# Agent file rules

When editing agent definitions:
- Never remove the `## Before any task` section — agents depend on it for self-loading context.
- Never remove the `## Collaboration protocol` section — it defines RESULT/BLOCKED/HANDOFF format.
- Keep `disallowedTools` consistent with the agent's role (read-only agents must have `disallowedTools: [Edit, Write, Bash]`).
- Model changes require user approval — present cost implications before changing.
