---
name: lang-typescript
description: This skill should be used when the user asks to "write TypeScript", "debug TypeScript", "create a SolidJS component", "configure TanStack Start", "validate data with Valibot", or mentions .ts/.tsx files. Covers TypeScript 5.9+, SolidJS, and TanStack patterns.
credit: modu-ai/moai-adk
---
<skill_doc>
<trigger_keywords>
## Trigger Keywords

Activate this skill when the user mentions any of:

**File Extensions**: `.ts`, `.tsx`, `.mts`, `.cts`

**TypeScript Core**: TypeScript, tsc, tsconfig, type inference, generics, satisfies, decorators, type guard, discriminated union, conditional types, mapped types, template literal types, infer keyword

**SolidJS**: SolidJS, Solid.js, createSignal, createStore, createMemo, createEffect, createResource, `<For>`, `<Show>`, `<Switch>`, `<Match>`, `<Index>`, onMount, onCleanup, fine-grained reactivity

**TanStack**: TanStack Start, TanStack Router, createFileRoute, createServerFn, useLoaderData, file-based routing, server functions, Vinxi

**Validation**: Valibot, v.object, v.string, v.pipe, v.safeParse, schema validation, type-safe validation

**Testing**: Vitest, Solid Testing Library, Playwright, @testing-library/solid, renderToString
</trigger_keywords>

## ⛔ Forbidden Patterns

1.  **NO `any`**: Strictly forbidden. Use `unknown` if type is truly not known yet, or define a proper type/interface.
2.  **NO `@ts-ignore`**: Do not suppress errors. Fix them. Use `@ts-expect-error` ONLY if testing error cases explicitly.
3.  **NO `!` (Non-null Assertion)**: Avoid `val!`. Use optional chaining `?.` or nullish coalescing `??`.
4.  **NO `enum`**: Prefer union types (`type Status = 'active' | 'inactive'`) or const objects. Enums add runtime overhead and behave unexpectedly.
5.  **NO Default Exports**: Prefer named exports to ensure consistent naming across the project and better tree-shaking.

## 🤖 Agent Tool Strategy

1.  **Discovery**: Check for `justfile` first. If it exists, use `just -l` to list recipes and prefer `just` commands over language-specific CLIs (npm, cargo, poetry, etc.). Then, read `tsconfig.json` to understand compiler options (strictness, paths, target).
2.  **Linting**: Check `eslint.config.js` or `.eslintrc` to align with project style.
3.  **Type Checking**: Use `tsc --noEmit` to verify type safety after changes if a build script isn't available.
4.  **Testing**: Run tests via `bun test` or `vitest` to ensure no regressions.
5.  **File Operations**: When creating files, ensure the extension matches the content (`.tsx` for JSX, `.ts` for logic).

## Quick Reference (30 seconds)

TypeScript 5.9+ Development Specialist - Modern TypeScript with SolidJS, TanStack Start, and type-safe API patterns.

Auto-Triggers: `.ts`, `.tsx`, `.mts`, `.cts` files, TypeScript configurations, SolidJS/TanStack Start projects

Core Stack:
- TypeScript 5.9: Deferred module evaluation, decorators, satisfies operator
- SolidJS: Fine-grained reactivity, signals, stores
- TanStack Start: Full-stack framework with file-based routing, server functions
- Valibot: Tree-shakable schema validation
- Testing: Vitest, Solid Testing Library, Playwright


---

## Implementation Guide (5 minutes)

See [patterns.md](references/patterns.md) for detailed implementation patterns covering:
- TypeScript 5.9 Key Features (Satisfies, Deferred Modules, Decorators)
- SolidJS Patterns (Signals, Stores, Memos, Resources)
- TanStack Start Patterns (Routes, Server Functions)
- Valibot Schema Patterns
- Advanced State Management

### Quick Troubleshooting

TypeScript Errors:
```bash
bun run typecheck                    # Type check only
bunx tsc --generateTrace ./trace     # Performance trace
```

SolidJS/TanStack Start Issues:
```bash
bun run dev                         # Development mode
bun run build                       # Check for build errors
rm -rf .vinxi .output && bun run dev  # Clear cache
```

Type Safety:
```typescript
// Exhaustive check
function assertNever(x: never): never { throw new Error(`Unexpected: ${x}`); }

// Type guard
function isUser(v: unknown): v is User {
  return typeof v === "object" && v !== null && "id" in v;
}
```

- [patterns.md](references/patterns.md) - Implementation patterns (SolidJS, TanStack, Valibot)
- [reference.md](references/reference.md) - Complete API reference, Context7 library mappings, advanced type patterns
- [examples.md](examples/examples.md) - Production-ready code examples, full-stack patterns, testing templates

### Context7 Integration

```typescript
// TypeScript - mcp__context7__get_library_docs("/microsoft/TypeScript", "decorators satisfies", 1)
// SolidJS - mcp__context7__get_library_docs("/solidjs/solid", "createSignal createStore", 1)
// TanStack Start - mcp__context7__get_library_docs("/tanstack/start", "server-functions routing", 1)
// TanStack Router - mcp__context7__get_library_docs("/tanstack/router", "file-based-routing loaders", 1)
// Valibot - mcp__context7__get_library_docs("/fabian-hiller/valibot", "schema validation pipe", 1)
```

---

## Works Well With

- `moai-domain-frontend` - UI components, styling patterns
- `moai-domain-backend` - API design, database integration
- `moai-workflow-testing` - Testing strategies and patterns
- `moai-foundation-quality` - Code quality standards
- `moai-essentials-debug` - Debugging TypeScript applications

---

## Quick Troubleshooting

TypeScript Errors:
```bash
bun run typecheck                    # Type check only
bunx tsc --generateTrace ./trace     # Performance trace
```

SolidJS/TanStack Start Issues:
```bash
bun run dev                         # Development mode
bun run build                       # Check for build errors
rm -rf .vinxi .output && bun run dev  # Clear cache
```

Type Safety:
```typescript
// Exhaustive check
function assertNever(x: never): never { throw new Error(`Unexpected: ${x}`); }

// Type guard
function isUser(v: unknown): v is User {
  return typeof v === "object" && v !== null && "id" in v;
}
```
</skill_doc>
