---
description: Automated PR creation with context-aware descriptions.
agent: build
model: google/antigravity-gemini-3-flash
---
# PR Create Command

You will generate a Pull Request using `gh pr create`.

## 1. Pre-flight
- Check branch: `git branch --show-current`. If `main` or `master`, **ABORT**.
- Check sync: `git status -sb`. If ahead/behind, warn user.

## 2. Gather Context
- Read commits: `git log main..HEAD --oneline`
- Read diff stats: `git diff main..HEAD --stat`

## 3. Draft Description
Draft a PR description using this template:
```markdown
## Why
[Problem being solved]

## What
- [Key change 1]
- [Key change 2]

## Verification
- [ ] Tests passed
- [ ] Manual check
```

## 4. Create
Run:
```bash
gh pr create --title "<type>(<scope>): <desc>" --body "<the body>" --web
```
**Ask for confirmation** before running the final command.
