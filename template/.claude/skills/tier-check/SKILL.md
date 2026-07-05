---
name: tier-check
description: Analyze a task and recommend the appropriate tier (0-4) with the full agent chain. Use when the user wants to know which tier a task falls into before starting work.
allowed-tools: Read, Grep, Glob
---

# Tier Check

Analyze the task provided by the user and recommend the correct tier.

## Steps

1. Read the tier definitions and upgrade criteria from `CLAUDE.md` → Dev Cycle section.
2. Evaluate the task against upgrade criteria:
   - Does it add new files? → at least Tier 2
   - Does it involve external network requests? → at least Tier 3
   - Does it write persistent artifacts? → at least Tier 3
   - Does it touch shared/core code? → at least Tier 3
   - Is it security-sensitive (auth, crypto, input validation)? → Tier 4
   - Is it a new major component? → Tier 4
3. Present the recommendation:

```
TIER ASSESSMENT
===============
Task:       <one-line summary>
Tier:       <0-4> — <tier name>
Chain:      <full agent chain for this tier>
Rationale:  <why this tier, which criteria matched>
```

4. If Tier 3, specify whether hunter or defender applies and why.
5. Ask the user to confirm before proceeding.
