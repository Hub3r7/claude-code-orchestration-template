---
name: bootstrap
description: Run the bootstrap protocol to customize all [PROJECT-SPECIFIC] sections for a new project. Use when setting up the framework for the first time or when the user says "bootstrap".
allowed-tools: Read, Write, Edit, Glob, Grep, Agent
---

# Bootstrap Protocol

Read `.claude/docs/bootstrap-protocol.md` and execute every phase in strict sequence.

Do not skip phases, do not reorder. Start with Phase 0 (language negotiation), then ask the user about the project, confirm the profile, discuss model assignment, and fill all `[PROJECT-SPECIFIC]` sections.

**File language rule:** All file content is always written in English, regardless of the user's communication language preference.
