# planning-and-task-breakdown — operating card

> Distilled from [`../planning-and-task-breakdown/SKILL.md`](../planning-and-task-breakdown/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Before implementing, decompose the spec into small, dependency-ordered, verifiable tasks with explicit acceptance criteria, saved as a written plan.

**Binding rules:**
- Plan in read-only mode: no code until the plan and task list are written to tasks/plan.md and tasks/todo.md.
- Slice vertically — one complete feature path (schema+API+UI) per task, not one layer at a time; each slice must work and be testable.
- Every task gets acceptance criteria, a verification step (test/build/manual), dependencies, likely files, and a size estimate.
- Order tasks bottom-up along the dependency graph, put high-risk tasks early, and insert a checkpoint after every 2-3 tasks.
- Break down any task over ~5 files, 2+ hours, 4+ acceptance bullets, two independent subsystems, or an 'and' in its title.
- Get human review and approval of the plan before starting implementation.

**Do NOT apply when:**
- Single-file changes with obvious scope.
- The spec already contains well-defined tasks.

**Go deep — read the full SKILL.md — when:**
- Writing an actual plan/task list — the task and plan-document templates and the verification checklist must be followed verbatim.
- Sizing borderline tasks or splitting work across parallel agents — the sizing table and parallelization rules decide.
