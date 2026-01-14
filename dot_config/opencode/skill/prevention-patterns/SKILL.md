---
id: prevention-patterns
name: PreventionPatterns
description: Known bug patterns and their fixes to prevent regression.
category: skill
type: skill
version: 1.0.0
author: opencode
---

<skill_doc>
# Prevention Patterns

When reviewing code or debugging, check against these known issues.

## 🛡️ React/Frontend Patterns
- **Missing Dependency**: `useEffect` dependency array incomplete?
- **Stale Closures**: Using state in callbacks without refs or functional updates?
- **Key Props**: Using `index` as key in list rendering? (Bad for re-ordering).
- **Zod Schema mismatch**: Frontend types not aligned with Backend API responses?

## 🛡️ Node/Backend Patterns
- **Unhandled Promise**: Missing `.catch()` or `try/catch` in async handlers?
- **SQL Injection**: String concatenation in queries instead of parameters?
- **Env Vars**: Hardcoded secrets instead of `process.env`?
- **Race Conditions**: Parallel DB updates to the same record?

## 🛡️ General Code Health
- **Slop Variables**: `data`, `info`, `temp`, `obj`. Rename them.
- **Deep Nesting**: More than 3 levels of indentation? Refactor/Extract.
- **Dead Code**: Imports unused? Functions never called?

## 🧪 Post-Mortem Protocol
When a bug is fixed, ask:
1. "Could this have been caught by a type?"
2. "Could this have been caught by a test?"
3. "Could this have been caught by a lint rule?"
Add the answer here.
</skill_doc>
