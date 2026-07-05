# security-and-hardening — operating card

> Distilled from [`../security-and-hardening/SKILL.md`](../security-and-hardening/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Build with attacker eyes: threat-model first, treat every external input (LLM output included) as hostile, and harden every boundary as you code.

**Binding rules:**
- Threat-model first: map trust boundaries (requests, uploads, webhooks, LLM output) and run STRIDE over them before writing controls.
- Validate every external input at the system boundary; parameterize all queries; encode output — never build SQL/shell/HTML from user data.
- Check authorization on every endpoint, not just authentication — users may touch only resources they own.
- Treat LLM output as untrusted input: never pass it to eval, SQL, a shell, innerHTML, or a file path; the system prompt is not a boundary.
- Never commit or log secrets; a secret that reaches a remote is compromised — rotate it, deleting the line or history is not enough.
- Ask a human before new auth flows, CORS changes, file-upload handlers, new PII/payment storage, or rate-limit modifications.

**Do NOT apply when:**
- The change touches no trust boundary: no user input, no auth/sessions, no sensitive data, no external services (docs, pure internal logic).
- 'Internal tool' or 'just a prototype' is NOT an exemption — the skill explicitly rejects those rationalizations.

**Go deep — read the full SKILL.md — when:**
- Task centrally involves auth, file uploads, user-influenced URL fetches (SSRF risk), or AI/LLM features — use the full code patterns.
- Running a security review or pre-release pass — apply the full review checklist, verification list, and npm audit triage tree.
