---
name: tanstack-solid
description: Specialist in the TanStack ecosystem for SolidJS, including TanStack Start, Query, Router, Table, and Form. Focuses on Solid-specific reactivity patterns.
---
<skill_doc>
<trigger_keywords>
## Trigger Keywords

Activate this skill when the user mentions any of:

**Meta-Framework**: TanStack Start, TanStack Start Solid, Server Functions, createServerFn

**Libraries**: @tanstack/solid-query, @tanstack/solid-router, @tanstack/solid-table, @tanstack/solid-form

**Concepts**: createQuery, createMutation, createRouter, createSolidTable, createForm
</trigger_keywords>

## ⛔ Forbidden Patterns

1.  **NO Destructuring Query Results**: `const { data } = createQuery(...)` breaks reactivity. Always use `query.data`.
2.  **NO Static Options Objects**: Passing a static object to `createQuery` prevents updates when dependencies change. Pass a function: `createQuery(() => ({ ... }))`.
3.  **NO React Patterns**: Do not use `useQuery` or `useEffect`. Use `createQuery` and `createEffect`.
4.  **NO Direct Prop Access in Options**: If using props in options, access them inside the getter function: `() => props.id`.
5.  **NO Manual Refetching Loop**: Do not use `setInterval` to refetch. Use `refetchInterval` in Query options.

## 🤖 Agent Tool Strategy

1.  **Reactivity Check**: Verify that all options objects passed to TanStack creators are wrapped in functions (e.g., `() => ({ ... })`) if they depend on signals/props.
2.  **Server Functions**: For TanStack Start, use `createServerFn` for backend logic instead of API routes where possible.
3.  **Type Safety**: Prioritize the type-safe routing features of TanStack Router (file-based routing, `createFileRoute`).

## Quick Reference (30 seconds)

TanStack Solid Specialist - Type-safe, Headless, Reactive.

**Core Philosophy**:
- **Solid Adapter**: All libraries use Solid's fine-grained reactivity.
- **Getters are King**: Options must be getters to track dependencies.
- **Type Safety**: End-to-end type safety from router to server functions.

**Key Libraries**:
- **Start**: Full-stack meta-framework.
- **Query**: Async state management (`createResource` alternative).
- **Router**: Type-safe routing.
- **Table**: Headless data tables.
- **Form**: Headless form state management.

---

## Resources

- **Examples**: See `examples/examples.md` for detailed code patterns.
- **References**: See `references/reference.md` for official documentation links.
</skill_doc>
