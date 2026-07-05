# frontend-ui-engineering — operating card

> Distilled from [`../frontend-ui-engineering/SKILL.md`](../frontend-ui-engineering/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Build user-facing UI to production quality: design-system-adherent, WCAG 2.1 AA accessible, responsive, with all states handled — never the generic AI look.

**Binding rules:**
- Kill the AI aesthetic: no purple/indigo defaults, gradients, rounded-everything, oversized padding — use the project's actual design system.
- Make every interactive element keyboard accessible; add ARIA labels, manage focus on content changes, keep 4.5:1 text contrast.
- Handle loading, error, AND empty states — never blank screens; skeletons (not spinners) for content, meaningful empty-state copy.
- Use semantic color tokens and the spacing scale — no raw hex, no inline styles, no arbitrary pixel values off the scale.
- Build mobile-first; verify layouts at 320, 768, 1024, and 1440px before calling it done.
- Compose small focused components (<200 lines); separate data-fetching containers from presentation; pick the simplest state tool that works.

**Do NOT apply when:**
- The task touches no user-facing interface — backend, CLI, data, or infra work is out of scope.
- A rule's stack-specific example (React/Tailwind/React Query) conflicts with the project's actual stack or design system — the project wins.

**Go deep — read the full SKILL.md — when:**
- The task is centrally UI — new components/pages, layout, or state architecture needing the full pattern catalog and checklist.
- Accessibility is in scope (focus traps, keyboard handlers, screen-reader structure) — read the full skill and its a11y checklist.
