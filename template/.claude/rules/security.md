---
globs: "**/*.{env,key,pem,secret,credentials}*"
---

# Sensitive file rules

- Never commit these files to git.
- Never include file contents in agent output or logs.
- If an agent encounters sensitive data during analysis, report the location but not the content.
