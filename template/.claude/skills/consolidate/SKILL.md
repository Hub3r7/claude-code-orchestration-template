---
name: consolidate
description: Periodic maintenance — evidence report from the chain log plus promotion of recurring agent-notes findings into project rules and the tier casebook. Run weekly or after a heavy chain. Proposes changes only; never applies without approval.
allowed-tools: Read, Grep, Glob
---

# Consolidate

Close the evidence loop: turn what the chains learned into durable project knowledge,
and report whether the tiers are earning their cost. **Propose, don't apply** — every
change is presented for user approval first.

## Steps

1. **Evidence report.** Read `.agentNotes/chain-log.jsonl`. Report:
   - PASS/FAIL counts per gate, and any FAIL streaks
   - which FAILs led to real fixes (cross-check recent git log) vs. re-review noise
   - any gate that never caught anything — a signal to recalibrate the tier upgrade
     rules or slim that chain position
2. **Knowledge promotion.** Read every `.agentNotes/*/notes.md`:
   - a finding recurring 3+ times → propose a rule for `docs/project-rules.md`
     (prevention beats repeated catching)
   - a tier misjudgment the user corrected → propose a row for
     `.claude/docs/tier-casebook.md` plus its matching `tier-casebook.jsonl`
     record (schema: `casebook-format.md`)
   - notes duplicating what project docs already record → propose deletion
3. **Notes hygiene.** Flag any notes file over its 200-line limit or carrying
   resolved items.
4. Present everything as one review: the evidence report plus proposed diffs.
   Apply only what the user approves. Rules and casebook entries are
   meta-configuration — the orchestrator writes them directly after approval.

## Cadence

Weekly, or after any Tier 3-4 chain with FAIL iterations. To automate the reminder,
run `/loop 7d /consolidate` locally or create a scheduled routine.
