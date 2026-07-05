---
name: abandon
description: Cleanly abandon the in-flight review chain — records it in the chain log with a reason instead of deleting state silently. User-invoked only.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Abandon Chain

1. If the user gave no reason, ask for a one-line reason — abandoned chains
   are evidence, and the reason is what makes the log entry useful to
   `/consolidate` later.
2. Run `bash .claude/scripts/chain.sh abandon "<reason>"`.
3. Confirm to the user: chain archived to `.agentNotes/chain-log.jsonl`,
   manifest removed, statusline cleared. Work already done by the chain stays
   as it is — abandoning stops the process, it does not revert files.
