# performance-optimization — operating card

> Distilled from [`../performance-optimization/SKILL.md`](../performance-optimization/SKILL.md) at upstream `8c65303`. The full skill is canonical — on any conflict it wins. Regenerate on every vendored refresh.

**Purpose:** Optimize only what measurements prove matters: profile, fix the actual bottleneck, re-measure, and guard against regression.

**Binding rules:**
- Measure before optimizing: establish a baseline with real data; optimization without profiling evidence is guessing.
- Follow the loop: measure, identify the actual bottleneck, fix it, verify with before/after numbers, then add a regression guard.
- Use both synthetic (Lighthouse/DevTools, CI) and RUM data; only real-user measurements prove a fix improved user experience.
- Hunt named anti-patterns first: N+1 queries, unpaginated list endpoints, images without dimensions/lazy loading, oversized bundles.
- Hold Core Web Vitals to Good: LCP <= 2.5s, INP <= 200ms, CLS <= 0.1; enforce performance budgets in CI.
- Do not blanket-apply React.memo/useMemo; overusing memoization is as bad as underusing it.

**Do NOT apply when:**
- No evidence of a performance problem exists; premature optimization adds complexity that costs more than it gains.
- No perf requirement, slow-behavior report, regression suspicion, or large-dataset/high-traffic feature is in play.

**Go deep — read the full SKILL.md — when:**
- Performance IS the task: you need the symptom decision tree, bottleneck tables, or the concrete anti-pattern fix code.
- Setting budgets/CI enforcement or doing image/bundle/caching work that needs the exact targets, markup, and commands.
