---
name: commit
description: Create a conventional commit. Analyzes staged/unstaged changes, drafts a commit message, and commits. Use when the user says "commit", "commitni", or asks to save changes.
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
---

# Commit

Create a well-structured commit from current changes.

## Steps

1. Run `git status` and `git diff` (staged + unstaged) to understand all changes.
2. Run `git log --oneline -5` to match the repository's commit message style.
3. Analyze the changes:
   - Classify: new feature, enhancement, bug fix, refactor, docs, config, etc.
   - Identify which files are relevant to stage (skip secrets, .env, credentials).
4. Draft a concise commit message (1-2 sentences) focused on **why**, not **what**.
5. Present the message to the user for confirmation.
6. Stage relevant files (prefer specific file names over `git add -A`).
7. Commit. Never amend unless explicitly asked.

## Commit message format

```
<type>: <short description>

<optional body — only if the change is non-obvious>
```

Types: `feat`, `fix`, `refactor`, `docs`, `config`, `test`, `chore`.
