---
name: framework-solidjs
description: Specialist in SolidJS 1.8+ and SolidStart development, focusing on fine-grained reactivity, efficient DOM rendering, and modern data-fetching patterns (Solid Router/Actions).
---
<skill_doc>
<trigger_keywords>
## Trigger Keywords

Activate this skill when the user mentions any of:

**Core**: SolidJS, Solid.js, createSignal, createStore, createMemo, createEffect, createResource, createAsync

**Components**: `<Show>`, `<For>`, `<Index>`, `<Switch>`, `<Match>`, `<Dynamic>`, `<Portal>`, `<ErrorBoundary>`

**Lifecycles**: onMount, onCleanup, batch, untrack

**Ecosystem**: SolidStart, Solid Router, Solid Primitives, Vinxi, Server Functions, "use server", createServerFn

**Tooling**: justfile, just, bun, bun run, biome
</trigger_keywords>

## ⛔ Forbidden Patterns

1.  **NO Virtual DOM Mentions**: SolidJS does NOT use a VDOM. Never imply it does.
2.  **NO React Hooks**: `useState`, `useEffect`, `useMemo` are forbidden. Use `createSignal`, `createEffect`, `createMemo`.
3.  **NO Prop Destructuring**: `const { name } = props;` breaks reactivity. Always access via `props.name` or use `splitProps`/`mergeProps`.
4.  **NO Early Returns in Components**: Reactivity setup runs once. Early returns stop effects from being created.
5.  **NO `array.map` for JSX**: Use `<For>` or `<Index>` for reactive lists.
6.  **NO `any`**: Strictly forbidden. Use `unknown` or proper types.
7.  **NO `@ts-ignore`**: Fix errors instead.

## 🤖 Agent Tool Strategy

1.  **Discovery**: Check for `justfile` first. Prefer `just` recipes (e.g., `just dev`, `just build`) over raw `bun` or `npm` commands.
2.  **Runtime**: **Prefer `bun`** over `npm` or `yarn` for script execution and package management.
3.  **Build**: Use `bun run dev` or `bun run build` if no `justfile` exists.
4.  **Routing**: Identify if `solid-router` or file-based routing (SolidStart) is used.
5.  **Type Checking**: Use `bun run tsc --noEmit` or `just typecheck` to verify safety.

## Quick Reference (30 seconds)

SolidJS Specialist - Fine-grained reactivity without a Virtual DOM.

**Philosophy**:
- **Run Once**: Components are setup functions that run once.
- **Fine-Grained**: Updates are surgical; only changed nodes update.
- **Direct DOM**: JSX compiles to real DOM nodes.

**Core Primitives**:
- `createSignal(v)`: Returns `[get, set]`. `get()` tracks, `set(v)` updates.
- `createEffect(fn)`: Re-runs `fn` when tracked signals change.
- `createMemo(fn)`: Computed value, caches result.
- `createStore(obj)`: Proxy for deep nested reactivity.
- `createResource`: Async data loading.

**Tooling Preferences**:
- **Task Runner**: Just (`justfile`)
- **Runtime**: Bun (`bun run`)
- **Linter**: Biome (recommended)

---

### Gotchas & Best Practices

- **Destructuring Props**:
  ❌ `const MyComp = ({ title }) => <div>{title}</div>` (Loses reactivity)
  ✅ `const MyComp = (props) => <div>{props.title}</div>`

- **Tracking Scopes**:
  Reactivity is only tracked synchronously within a tracking scope (Effect, Memo, Render). Async callbacks lose the tracking context unless `runWithOwner` is used, but usually you just read signals where you need them.

- **Batching**:
  Solid batches updates automatically in effects/event handlers. Use `batch(() => ...)` for manual grouping outside those contexts.

## Resources

- **Examples**: See `examples/examples.md` for detailed code patterns.
- **References**: See `references/reference.md` for official documentation links.
</skill_doc>
