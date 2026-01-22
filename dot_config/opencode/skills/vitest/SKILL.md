---
name: vitest
description: Specialist in Vitest, a blazing fast unit test framework powered by Vite. Focuses on Jest compatibility, in-source testing, and native ESM support.
---
<skill_doc>
<trigger_keywords>
## Trigger Keywords

Activate this skill when the user mentions any of:

**Core**: Vitest, Vite Test, vi.mock, vi.fn, describe, it, test, expect

**Configuration**: vitest.config.ts, in-source testing, coverage

**Comparison**: Jest replacement, faster than Jest
</trigger_keywords>

## ⛔ Forbidden Patterns

1.  **NO `jest` Global**: Do not use `jest.fn()` or `jest.mock()`. Use `vi.fn()` and `vi.mock()`.
2.  **NO CommonJS require**: Vitest is ESM-first. Use `import` statements.
3.  **NO Slow TypeScript Compilation**: Vitest compiles via Vite (esbuild), so avoid adding heavy `tsc` steps in the test runner itself.
4.  **NO `module.exports`**: Use `export default` or named exports in your test files or mocks.

## 🤖 Agent Tool Strategy

1.  **Config Check**: Look for `vitest.config.ts` or `vite.config.ts` to understand the environment (globals enabled? environment: jsdom?).
2.  **Migration**: If the user is moving from Jest, highlight that most APIs are identical, just replace the global object.
3.  **Mocking**: Use `vi.spyOn` and `vi.mock` for isolating dependencies.
4.  **UI**: Mention `vitest ui` for a visual test runner experience.

## Quick Reference (30 seconds)

Vitest Specialist - "Vite Native Unit Testing".

**Philosophy**:
- **Shared Config**: Uses your existing `vite.config.ts`.
- **Fast**: Powered by esbuild.
- **Compatible**: API is 95% compatible with Jest.

**Workflow**:
1.  Write tests in `*.test.ts`.
2.  Run `vitest` for watch mode.
3.  Run `vitest run` for CI.

---

## Resources

- **Examples**: See `examples/examples.md` for detailed code patterns.
- **References**: See `references/reference.md` for official documentation links.
</skill_doc>
