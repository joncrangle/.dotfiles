---
name: code-style
description: Discovery, typing, and execution standards.
---

<skill_doc>

# Code Style & Discovery

## 🔍 Discovery Phase (Mandatory)

Before writing any code:

1.  **Search**: Search for existing patterns using the `grep` tool.
2.  **Read**: Read similar files to match style.
3.  **Types**: Find the TypeScript interfaces/types defined in the project.

## 🛡️ Coding Standards

- **Strict TypeScript**: No `any`. Define interfaces.
- **Error Handling**: Use `try/catch` with specific error logging. No silent failures.
- **Comments**: Comment _why_, not _what_.
- **Imports**: Use absolute imports if project configured (check `tsconfig`).

## 🧪 Verification

- **Test-Driven**: Create/Update tests for every logic change.
- **Lint**: Run linting before reporting success.
  </skill_doc>
