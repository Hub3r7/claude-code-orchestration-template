---
name: push
description: Push current branch to remote. Checks branch state and remote tracking before pushing. Use when the user says "push", "pushni", or asks to push changes.
disable-model-invocation: true
allowed-tools: Bash
---

# Push

Push the current branch to the remote repository.

## Steps

1. Run `git status` to verify working tree is clean (warn if uncommitted changes).
2. Check if the current branch tracks a remote branch (`git rev-parse --abbrev-ref --symbolic-full-name @{u}`).
3. If no upstream: push with `-u origin <branch>`.
4. If upstream exists: run `git push`.
5. Report the result (branch, remote, commit range pushed).

## Safety

- Never force-push without explicit user request.
- Warn before pushing to main/master.
- If there are unpushed commits, show them before pushing.
