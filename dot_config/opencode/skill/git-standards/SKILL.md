---
id: git-standards
name: GitStandards
description: Git rules, Conventional Commits, and Safety Checks.
category: skill
type: skill
version: 1.0.0
author: opencode
---

<skill_doc>
# Git Standards & Protocols

## 🛑 SAFETY CHECKS (Critical)
**Tool Enforcement**:
Use the `bun tools/git-safe.ts` wrapper for all commit/push operations if possible.

**Manual Agent Checks**:
Before ANY commit, you must scan staged files (`git diff --cached`) for:
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
