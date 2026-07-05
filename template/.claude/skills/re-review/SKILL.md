---
name: re-review
description: Re-run the review chain on existing code without implementing anything. Use when the user wants a fresh security or architecture review of code that is already written.
allowed-tools: Read, Grep, Glob, Agent
---

# Re-Review

Run the review chain on existing code. No implementation — review only.

## Steps

1. Ask the user what to review (specific files, component, or recent changes).
2. If not specified, use `git diff main...HEAD` or `git diff --name-only` to identify changed files.
3. Determine the appropriate tier using the tier criteria from `CLAUDE.md` → Dev Cycle.
4. Run the review chain for that tier, skipping architect and developer:
   - **Tier 1-2**: quality-gate only
   - **Tier 3**: quality-gate → hunter OR defender
   - **Tier 4**: quality-gate → hunter → defender
5. Each reviewer gets the file list and context. Standard PASS/FAIL verdicts apply.
6. Summarize all findings at the end.

## Key rule

This is review-only. No agent modifies any file. If findings require fixes, present them to the user — do not auto-fix.
