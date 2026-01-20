# TypeScript Development Reference

## TypeScript 5.9 Complete Reference

### New Features Overview

| Feature | Description | Use Case |
|---------|-------------|----------|
| Deferred Module Evaluation | Lazy-load modules on first access | Performance optimization |
| Decorators (Stage 3) | Native decorator support | Logging, validation, DI |
| Satisfies Operator | Type check without widening | Precise type inference |
| Const Type Parameters | Infer literal types in generics | Configuration objects |
| NoInfer Utility Type | Control inference in generic positions | API design |

### Advanced Type Patterns

#### Conditional Types

```typescript
// Extract return type from async function
type Awaited<T> = T extends Promise<infer U> ? U : T;

// Create type based on condition
type NonNullable<T> = T extends null | undefined ? never : T;

// Distributive conditional types
type ToArray<T> = T extends any ? T[] : never;
type Result = ToArray<string | number>; // string[] | number[]
```

#### Mapped Types

```typescript
// Make all properties optional
type Partial<T> = { [P in keyof T]?: T[P] };

// Make all properties readonly
type Readonly<T> = { readonly [P in keyof T]: T[P] };

// Pick specific properties
type Pick<T, K extends keyof T> = { [P in K]: T[P] };

// Custom mapped type with key transformation
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface User {
  name: string;
  age: number;
}

type UserGetters = Getters<User>;
// { getName: () => string; getAge: () => number; }
```

#### Template Literal Types

```typescript
// Event handler types
type EventName = "click" | "focus" | "blur";
type EventHandler = `on${Capitalize<EventName>}`;
// "onClick" | "onFocus" | "onBlur"

// API route types
type HTTPMethod = "GET" | "POST" | "PUT" | "DELETE";
type APIRoute<M extends HTTPMethod, P extends string> = `${M} ${P}`;
type UserRoutes = APIRoute<"GET" | "POST", "/users">;

// CSS utility types
type CSSProperty = "margin" | "padding";
type CSSDirection = "top" | "right" | "bottom" | "left";
type CSSUtility = `${CSSProperty}-${CSSDirection}`;
```

#### Variadic Tuple Types

```typescript
// Concat tuple types
type Concat<T extends unknown[], U extends unknown[]> = [...T, ...U];

// First and rest
type First<T extends unknown[]> = T extends [infer F, ...unknown[]] ? F : never;
type Rest<T extends unknown[]> = T extends [unknown, ...infer R] ? R : never;

// Typed pipe function
type PipeFunction<I, O> = (input: I) => O;

declare function pipe<A, B>(fn1: PipeFunction<A, B>): PipeFunction<A, B>;
declare function pipe<A, B, C>(
  fn1: PipeFunction<A, B>,
  fn2: PipeFunction<B, C>
): PipeFunction<A, C>;
declare function pipe<A, B, C, D>(
  fn1: PipeFunction<A, B>,
  fn2: PipeFunction<B, C>,
  fn3: PipeFunction<C, D>
): PipeFunction<A, D>;
```

### Utility Types Deep Dive

```typescript
// Record - Create object type with specific keys and values
type PageInfo = { title: string };
type PageRecord = Record<"home" | "about" | "contact", PageInfo>;

// Exclude/Extract - Filter union types
type T1 = Exclude<"a" | "b" | "c", "a">; // "b" | "c"
type T2 = Extract<"a" | "b" | "c", "a" | "f">; // "a"

// Parameters/ReturnType - Function type utilities
function greet(name: string, age: number): string {
  return `Hello ${name}, you are ${age}`;
}
type Params = Parameters<typeof greet>; // [string, number]
type Return = ReturnType<typeof greet>; // string

// Awaited - Unwrap Promise types
type A = Awaited<Promise<string>>; // string
type B = Awaited<Promise<Promise<number>>>; // number

// NoInfer - Prevent type inference
function createState<T>(initial: NoInfer<T>): [T, (value: T) => void] {
  // Implementation
}
```

---

## SolidJS Complete Reference

### Reactivity Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  SolidJS Reactivity                      │
├─────────────────────────────────────────────────────────┤
│  Signals (Reactive Primitives)                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │  const [count, setCount] = createSignal(0)         │ │
│  │                     │                               │ │
│  │                     ▼ Fine-grained updates          │ │
│  └────────────────────────────────────────────────────┘ │
│                        │                                 │
│                        ▼                                 │
│  Effects (Side Effects)                                  │
│  ┌────────────────────────────────────────────────────┐ │
│  │  createEffect(() => console.log(count()))          │ │
│  │    - Auto-tracks dependencies                      │ │
│  │    - Re-runs when signals change                   │ │
│  └────────────────────────────────────────────────────┘ │
│                        │                                 │
│                        ▼                                 │
│  Memos (Derived State)                                   │
│  ┌────────────────────────────────────────────────────┐ │
│  │  const double = createMemo(() => count() * 2)      │ │
│  │    - Cached computation                            │ │
│  │    - Only recalculates when deps change            │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Primitives Reference

| Primitive | Purpose | Example |
|-----------|---------|---------|
| createSignal | Simple reactive state | `const [val, setVal] = createSignal(0)` |
| createStore | Complex/nested state | `const [store, setStore] = createStore({})` |
| createMemo | Cached computation | `const derived = createMemo(() => val() * 2)` |
| createEffect | Side effects | `createEffect(() => console.log(val()))` |
| createResource | Async data fetching | `const [data] = createResource(fetcher)` |
| createContext | Dependency injection | `const Ctx = createContext<T>()` |

### Component Patterns

#### Props and Children

```typescript
import { Component, ParentComponent, JSX } from "solid-js";

// Simple component
interface ButtonProps {
  variant?: "primary" | "secondary";
  onClick?: () => void;
}

const Button: ParentComponent<ButtonProps> = (props) => {
  return (
    <button
      class={props.variant === "primary" ? "btn-primary" : "btn-secondary"}
      onClick={props.onClick}
    >
      {props.children}
    </button>
  );
};

// Component with render props
interface ListProps<T> {
  items: T[];
  children: (item: T, index: () => number) => JSX.Element;
}

function List<T>(props: ListProps<T>) {
  return (
    <For each={props.items}>
      {(item, index) => props.children(item, index)}
    </For>
  );
}
```

#### Control Flow Components

```typescript
import { Show, For, Switch, Match, Index, ErrorBoundary } from "solid-js";

// Conditional rendering
<Show when={user()} fallback={<Login />}>
  {(u) => <Dashboard user={u()} />}
</Show>

// List rendering (keyed by reference)
<For each={items()}>
  {(item) => <ItemCard item={item} />}
</For>

// List rendering (keyed by index)
<Index each={items()}>
  {(item, index) => <div>{index}: {item().name}</div>}
</Index>

// Switch/Match pattern
<Switch fallback={<NotFound />}>
  <Match when={status() === "loading"}>
    <Spinner />
  </Match>
  <Match when={status() === "error"}>
    <Error />
  </Match>
  <Match when={status() === "success"}>
    <Content />
  </Match>
</Switch>

// Error handling
<ErrorBoundary fallback={(err, reset) => (
  <div>
    <p>Error: {err.message}</p>
    <button onClick={reset}>Retry</button>
  </div>
)}>
  <RiskyComponent />
</ErrorBoundary>
```

#### Resource Pattern (Data Fetching)

```typescript
import { createResource, Suspense } from "solid-js";

// Basic resource
const [user] = createResource(() => fetch("/api/user").then(r => r.json()));

// Resource with source signal
const [userId, setUserId] = createSignal("1");
const [user] = createResource(userId, async (id) => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
});

// With refetch and mutate
const [posts, { refetch, mutate }] = createResource(fetchPosts);

// Optimistic update
const addPost = async (newPost: Post) => {
  mutate((prev) => [...prev, newPost]); // Optimistic
  await createPost(newPost);
  refetch(); // Sync with server
};

// Usage with Suspense
<Suspense fallback={<Loading />}>
  <UserProfile user={user()} />
</Suspense>
```

### Stores Deep Dive

```typescript
import { createStore, produce, reconcile } from "solid-js/store";

interface AppState {
  users: User[];
  settings: {
    theme: "light" | "dark";
    notifications: boolean;
  };
}

const [state, setState] = createStore<AppState>({
  users: [],
  settings: { theme: "light", notifications: true },
});

// Path-based updates
setState("settings", "theme", "dark");
setState("users", 0, "name", "Updated Name");

// Array operations
setState("users", (users) => [...users, newUser]);
setState("users", (u) => u.filter((user) => user.id !== id));

// Immer-like mutations with produce
setState(produce((s) => {
  s.users.push(newUser);
  s.settings.theme = "dark";
}));

// Replace entire slice (useful for API responses)
setState("users", reconcile(apiResponse.users));
```

---

## TanStack Start Complete Reference

### Architecture Overview

TanStack Start is built on Vinxi (Vite + Nitro) and provides a full-stack framework with type-safe routing.

### Rendering Strategies

| Strategy | Description | Use Case |
|----------|-------------|----------|
| SSR | Server-Side Rendering (default) | Dynamic, personalized content |
| SPA | Client-side only | Interactive dashboards |
| data-only | Fetch on server, render on client | Heavy client components |

### Route Configuration

```typescript
// app/routes/dashboard.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/dashboard')({
  // SSR mode (default)
  ssr: true,
  
  // Client-side only (SPA mode)
  // ssr: false,
  
  // Fetch data on server, render component on client
  // ssr: 'data-only',
  
  loader: async () => {
    return fetchDashboardData()
  },
  
  component: DashboardPage,
})
```

### Server Functions

```typescript
import { createServerFn } from '@tanstack/start'
import { valibotValidator } from '@tanstack/valibot-adapter'
import * as v from 'valibot'

// GET request (no body)
export const getUsers = createServerFn({ method: 'GET' })
  .handler(async () => {
    return db.users.findMany()
  })

// POST request with validation
const CreateUserSchema = v.object({
  name: v.pipe(v.string(), v.minLength(2)),
  email: v.pipe(v.string(), v.email()),
})

export const createUser = createServerFn({ method: 'POST' })
  .validator(valibotValidator(CreateUserSchema))
  .handler(async ({ data }) => {
    return db.users.create({ data })
  })

// With context from middleware
export const getProfile = createServerFn({ method: 'GET' })
  .middleware([authMiddleware])
  .handler(async ({ context }) => {
    return db.users.findUnique({ where: { id: context.userId } })
  })
```

### Data Fetching Patterns

```typescript
// Parallel data fetching
export const Route = createFileRoute('/dashboard')({
  loader: async () => {
    const [users, posts, comments] = await Promise.all([
      getUsers(),
      getPosts(),
      getComments(),
    ])
    return { users, posts, comments }
  },
  component: () => {
    const { users, posts, comments } = Route.useLoaderData()
    return <DashboardView users={users} posts={posts} comments={comments} />
  },
})

// Sequential data fetching (when dependent)
export const Route = createFileRoute('/users/$id/posts')({
  loader: async ({ params }) => {
    const user = await getUser({ data: { id: params.id } })
    const posts = await getUserPosts({ data: { userId: user.id } })
    return { user, posts }
  },
})
```

### Middleware Patterns

```typescript
import { createMiddleware } from '@tanstack/start'

// Logging middleware
const loggingMiddleware = createMiddleware()
  .server(async ({ next }) => {
    const start = Date.now()
    const result = await next()
    console.log(`Request took ${Date.now() - start}ms`)
    return result
  })

// Auth middleware
const authMiddleware = createMiddleware()
  .middleware([loggingMiddleware]) // Chain middlewares
  .server(async ({ next }) => {
    const session = await getSession()
    if (!session?.user) {
      throw new Error('Unauthorized')
    }
    return next({
      context: {
        userId: session.user.id,
        role: session.user.role,
      },
    })
  })

// Admin middleware (builds on auth)
const adminMiddleware = createMiddleware()
  .middleware([authMiddleware])
  .server(async ({ next, context }) => {
    if (context.role !== 'admin') {
      throw new Error('Forbidden')
    }
    return next()
  })
```

### Router Configuration

```typescript
// app/router.tsx
import { createRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

export function createAppRouter() {
  return createRouter({
    routeTree,
    defaultPreload: 'intent', // Preload on hover/focus
    defaultSsr: true,
    context: {
      // Initial context available to all routes
    },
  })
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof createAppRouter>
  }
}
```

### App Configuration

```typescript
// app.config.ts
import { defineConfig } from '@tanstack/start/config'

export default defineConfig({
  server: {
    preset: 'bun', // or 'node-server', 'vercel', 'netlify', 'cloudflare-pages'
  },
  vite: {
    // Vite config overrides
  },
})

---

## Valibot Complete Reference

### Schema Types

| Type | Example | Description |
|------|---------|-------------|
| string | `v.string()` | String validation |
| number | `v.number()` | Number validation |
| boolean | `v.boolean()` | Boolean validation |
| date | `v.date()` | Date object validation |
| picklist | `v.picklist(["a", "b"])` | Literal union (like enum) |
| enum | `v.enum(MyEnum)` | TS enum validation |
| array | `v.array(v.string())` | Array validation |
| object | `v.object({...})` | Object validation |
| union | `v.union([...])` | Type union |
| variant | `v.variant("type", [...])` | Discriminated union |
| tuple | `v.tuple([...])` | Fixed-length array |
| record | `v.record(v.string(), v.number())` | Record type |
| literal | `v.literal("hello")` | Exact value |
| null | `v.null()` | Null type |
| undefined | `v.undefined()` | Undefined type |
| optional | `v.optional(v.string())` | Optional wrapper |
| nullable | `v.nullable(v.string())` | Nullable wrapper |
| any | `v.any()` | Any type |
| unknown | `v.unknown()` | Unknown type |
| never | `v.never()` | Never type |

### The Pipeline Pattern

Valibot uses `v.pipe()` for chaining validations (enables tree-shaking):

```typescript
import * as v from "valibot";

// Basic string with validations
const EmailSchema = v.pipe(
  v.string(),
  v.email("Invalid email address"),
  v.maxLength(255)
);

// Number with constraints
const AgeSchema = v.pipe(
  v.number(),
  v.minValue(0),
  v.maxValue(120)
);

// String with transformation
const SlugSchema = v.pipe(
  v.string(),
  v.transform((s) => s.toLowerCase().replace(/\s+/g, "-"))
);
```

### Advanced Patterns

```typescript
// Discriminated unions with v.variant
const EventSchema = v.variant("type", [
  v.object({ type: v.literal("click"), x: v.number(), y: v.number() }),
  v.object({ type: v.literal("keypress"), key: v.string() }),
  v.object({ type: v.literal("scroll"), delta: v.number() }),
]);

// Recursive types
type Category = {
  name: string;
  subcategories: Category[];
};

const CategorySchema: v.GenericSchema<Category> = v.object({
  name: v.string(),
  subcategories: v.array(v.lazy(() => CategorySchema)),
});

// Branded types for type safety
const UserId = v.pipe(v.string(), v.uuid(), v.brand("UserId"));
type UserId = v.InferOutput<typeof UserId>;

// Error customization
const EmailSchema = v.pipe(
  v.string(),
  v.email("Please enter a valid email address"),
  v.check(
    (email) => !email.includes("+"),
    "Email aliases are not allowed"
  )
);

// Coercion / Transformation
const DateSchema = v.pipe(
  v.string(),
  v.isoTimestamp(),
  v.transform((s) => new Date(s))
);

const NumberFromString = v.pipe(
  v.unknown(),
  v.transform(Number),
  v.number()
);
```

### Type Inference

```typescript
// Output type (after transformations)
type User = v.InferOutput<typeof UserSchema>;

// Input type (before transformations)
type UserInput = v.InferInput<typeof UserSchema>;

// Example with transformation
const DateSchema = v.pipe(
  v.string(),
  v.transform((s) => new Date(s))
);

type DateIn = v.InferInput<typeof DateSchema>;   // string
type DateOut = v.InferOutput<typeof DateSchema>; // Date
```

### Parsing

```typescript
// Throws on error
const user = v.parse(UserSchema, data);

// Returns result object
const result = v.safeParse(UserSchema, data);
if (result.success) {
  console.log(result.output);
} else {
  console.log(result.issues);
}

// Async validation
const asyncResult = await v.safeParseAsync(AsyncSchema, data);
```

### Comparison: Zod vs Valibot

| Feature | Zod | Valibot |
|---------|-----|---------|
| Method chaining | `z.string().email()` | `v.pipe(v.string(), v.email())` |
| Parsing | `schema.parse(data)` | `v.parse(schema, data)` |
| Safe parse | `schema.safeParse(data)` | `v.safeParse(schema, data)` |
| Type inference | `z.infer<typeof S>` | `v.InferOutput<typeof S>` |
| Optional | `z.string().optional()` | `v.optional(v.string())` |
| Nullable | `z.string().nullable()` | `v.nullable(v.string())` |
| Discriminated union | `z.discriminatedUnion()` | `v.variant()` |
| Bundle size | ~14kB (all included) | <1kB (tree-shakable) |

---

## Context7 Library Mappings

### Primary Libraries

```
/microsoft/TypeScript       - TypeScript language and compiler
/solidjs/solid              - SolidJS reactive UI library
/tanstack/start             - TanStack Start full-stack framework
/tanstack/router            - TanStack Router (file-based routing)
/fabian-hiller/valibot      - Valibot schema validation
```

### UI Libraries

```
/kobalte-ui/kobalte         - Kobalte (SolidJS accessible components)
/tailwindlabs/tailwindcss   - Tailwind CSS
```

### Testing

```
/vitest-dev/vitest          - Vitest testing framework
/solidjs/solid-testing-library - Solid Testing Library
/microsoft/playwright       - Playwright E2E testing
```

### Build Tools

```
/vercel/turbo               - Turborepo monorepo
/evanw/esbuild              - esbuild bundler
/biomejs/biome              - Biome linter/formatter
```

---

## Performance Optimization

### Bundle Optimization

```typescript
// Dynamic imports for code splitting
const HeavyComponent = lazy(() => import("./HeavyComponent"));

// Usage with Suspense
<Suspense fallback={<Skeleton />}>
  <HeavyComponent />
</Suspense>

// Tree-shaking friendly exports
// utils/index.ts - BAD
export * from "./math";
export * from "./string";

// utils/index.ts - GOOD
export { add, subtract } from "./math";
export { capitalize } from "./string";
```

### SolidJS Optimization

SolidJS is already highly optimized due to fine-grained reactivity. Key patterns:

```typescript
// Use createMemo for expensive computations
const sortedItems = createMemo(() =>
  items().sort((a, b) => a.name.localeCompare(b.name))
);

// Batch multiple state updates
import { batch } from "solid-js";

batch(() => {
  setName("John");
  setAge(30);
  setEmail("john@example.com");
});

// Use untrack to prevent dependency tracking
import { untrack } from "solid-js";

createEffect(() => {
  const current = count();
  const previous = untrack(() => previousCount()); // Won't trigger on previousCount changes
  console.log(`Changed from ${previous} to ${current}`);
});

// Use <For> instead of .map() for list rendering
// <For> only updates changed items, not entire list
<For each={items()}>
  {(item) => <ItemCard item={item} />}
</For>
```

### TypeScript Compilation

```json
// tsconfig.json optimizations
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "isolatedModules": true
  }
}
```

---

## Security Best Practices

### Input Validation

```typescript
import { createServerFn } from "@tanstack/start";
import { valibotValidator } from "@tanstack/valibot-adapter";
import * as v from "valibot";

const CreateUserSchema = v.object({
  name: v.pipe(v.string(), v.minLength(2), v.maxLength(100)),
  email: v.pipe(v.string(), v.email()),
});

// Always validate on server with server functions
export const createUser = createServerFn({ method: "POST" })
  .validator(valibotValidator(CreateUserSchema))
  .handler(async ({ data }) => {
    // data is validated and typed
    return db.user.create({ data });
  });
```

### Environment Variables

```typescript
// env.ts
import * as v from "valibot";

const envSchema = v.object({
  DATABASE_URL: v.pipe(v.string(), v.url()),
  AUTH_SECRET: v.pipe(v.string(), v.minLength(32)),
  NODE_ENV: v.picklist(["development", "production", "test"]),
});

const result = v.safeParse(envSchema, process.env);

if (!result.success) {
  console.error("Invalid environment variables:", result.issues);
  throw new Error("Invalid environment variables");
}

export const env = result.output;
```

### Authentication with Middleware

```typescript
import { createMiddleware, createServerFn } from "@tanstack/start";

const authMiddleware = createMiddleware()
  .server(async ({ next }) => {
    const session = await getSession();
    if (!session?.user) {
      throw new Error("Unauthorized");
    }
    return next({
      context: {
        userId: session.user.id,
        role: session.user.role,
      },
    });
  });

// Protected server function
export const getProfile = createServerFn({ method: "GET" })
  .middleware([authMiddleware])
  .handler(async ({ context }) => {
    return db.user.findUnique({
      where: { id: context.userId },
    });
  });
```

---

Version: 1.1.0
Last Updated: 2025-12-30
