---
id: code-style
name: CodeStyle
description: Discovery, typing, and execution standards.
category: skill
type: skill
version: 1.0.0
author: opencode
---

<skill_doc>
# Code Style & Discovery

## 🔍 Discovery Phase (Mandatory)
Before writing any code:
1.  **Grep**: Search for existing patterns (`grep -r "pattern" src`).
2.  **Read**: Read similar files to match style.
3.  **Types**: Find the TypeScript interfaces/types defined in the project.

## 🛡️ Coding Standards
- **Strict TypeScript**: No `any`. Define interfaces.
- **Error Handling**: Use `try/catch` with specific error logging. No silent failures.
- **Comments**: Comment *why*, not *what*.
- **Imports**: Use absolute imports if project configured (check `tsconfig`).

## 🧪 Verification
- **Test-Driven**: Create/Update tests for every logic change.
- **Lint**: Run linting before reporting success.

## 🛠️ Tooling
- Use `bun tools/hotspots.ts` to find frequently changed files.
- Use `ls` or `dir` to explore the directory structure.
</skill_doc>
