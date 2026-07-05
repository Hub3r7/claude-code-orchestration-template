---
name: deep-analysis
description: Deep analysis of project structure, logic, patterns, and dependencies. Use when the user wants a thorough understanding of how the project works, its architecture, or specific subsystems.
allowed-tools: Read, Grep, Glob, Agent
---

# Deep Analysis

Perform a thorough analysis of the project or a specific subsystem.

## Steps

1. Ask the user what to analyze (whole project, specific component, specific concern).
2. Read the project structure and key entry points.
3. Trace the logic flow through the codebase:
   - Entry points → core logic → outputs/side effects
   - Data flow and state management
   - Dependency graph (internal and external)
   - Error handling paths
4. Identify:
   - **Patterns** — recurring design choices, conventions
   - **Coupling** — where components depend on each other
   - **Complexity hotspots** — files/functions with high cyclomatic complexity or many dependencies
   - **Gaps** — missing error handling, untested paths, undocumented behavior
5. Present findings in a structured report:

```
DEEP ANALYSIS
=============
Scope:        <what was analyzed>
Entry points: <main entry points found>
Key flows:    <critical logic paths>
Patterns:     <design patterns observed>
Hotspots:     <complexity or risk areas>
Gaps:         <missing coverage, docs, tests>
```

6. Offer to dive deeper into any specific area the user wants.

## Key rule

This is read-only analysis. Do not modify any files.
