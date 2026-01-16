---
description: Interactive commit builder with conventional commits and safety checks.
agent: build
model: google/antigravity-gemini-3-flash
---
# Commit Command

You will help the user create a perfect commit.

## 1. Context & Safety
First, run these commands (silently analyze, don't output unless error):
1. `git_safe(action: "diff", target: "--cached --stat")` (See what's staged)
2. `git_safe(action: "diff", target: "--cached --name-only")` (Check for secrets/keys)

**SAFETY CHECK**:
If you see `.env`, `*.key`, or typical API key patterns in the diff, **STOP**. Warn the user immediately.

## 2. Analysis
Analyze the staged changes.
- Identify the Type: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `perf`.
- Identify the Scope: Which component/module?
- Identify the "Why": What problem does this solve?

## 3. Proposal
Propose 3 commit messages in this format:

### Option 1 (Standard)
`<type>(<scope>): <description>`

`<body>`

### Option 2 (Concise)
`<type>(<scope>): <description>`

### Option 3 (Detailed)
`<type>(<scope>): <description>`

- bullet 1
- bullet 2

## 4. Execution
Ask the user to pick one (1, 2, or 3) or provide their own.
THEN run: `git_safe(action: "commit", message: "...")`
