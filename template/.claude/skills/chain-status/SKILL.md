---
name: chain-status
description: Show where the review chain stands — tier, task, completed and next positions, FAIL counters, recent verdicts. Use when the user asks about chain progress or state.
allowed-tools: Bash, Read
---

# Chain Status

1. Run `bash .claude/scripts/chain.sh show`.
2. Render the result for the operator in plain language:
   - task and tier
   - positions done vs. total, and which agent runs next
   - any non-zero FAIL counter, and how close that gate is to the 3-FAIL
     circuit breaker
   - the recent chain-log lines (verdicts, failures, completions), one
     sentence each
3. If no chain is in flight, say so — and show the most recent
   `chain_complete` or `chain_abandoned` entry from
   `.agentNotes/chain-log.jsonl` if one exists.
