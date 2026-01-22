---
name: git-standards
description: This skill should be used when the user asks to "commit changes", "create a PR", "push code", "check git status", or "review git history". Enforces safety checks and conventional commits.
---

<skill_doc>
# Git Standards & Protocols

## 🛑 SAFETY CHECKS (Critical)
**Tool Enforcement**:
Use the `git_safe` tool for all git operations (status, diff, log, add, commit, push).

**Manual Agent Checks**:
Before ANY commit, scan staged files using `git_safe(action: "diff", target: "--cached")` for:
- **Secrets**: `.env`, `*_KEY`, `*_SECRET`, `password`, `token`.
- **Large Files**: Anything >10MB or binary files.
- **Build Artifacts**: `dist/`, `node_modules/`, `.DS_Store`.
**Action**: If found, UNSTAGE immediately and warn user.

## 📝 Commit Protocol (Conventional)
Format: `<type>(<scope>): <description>`

| Type | Meaning |
| :--- | :--- |
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change (no feature/fix) |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `chore` | Build/auxiliary tools |

**Examples**:
- `feat(auth): add google oauth provider`
- `fix(login): handle null session token`

## 🚀 PR Protocol
**Title**: Matches commit format.
**Body**:
```markdown
## Why
(Context/Problem)

## What
(Summary of changes)

## Verification
- [ ] Tests
- [ ] Manual Check
```
</skill_doc>
