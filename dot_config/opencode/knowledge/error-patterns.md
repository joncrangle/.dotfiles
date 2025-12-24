# Error Patterns Knowledge Base

Common error patterns with known fixes. Searchable by error message fragments.

## How to Use This File

1. **During debugging**: Search for error message fragments to find known patterns
2. **After fixing novel errors**: Add new patterns to appropriate section
3. **In /iterate**: Inject relevant patterns into evaluator context
4. **In /debug**: Check here FIRST before investigating

---

## TypeScript Errors

### TS2322: Type 'X' is not assignable to type 'Y'

**Pattern:** `Type '.*' is not assignable to type`

**Common Causes:**

- Literal types vs wider types (`"foo"` vs `string`)
- Missing discriminant in union
- Optional vs required properties
- `null`/`undefined` not handled

**Fixes:**

```typescript
// Widen with `as const` satisfaction
const config = { type: "foo" } as const satisfies Config;

// Narrow with type guard
if (isSpecificType(value)) {
  /* now narrowed */
}

// Add missing discriminant
type Action = { type: "add"; value: number } | { type: "remove"; id: string };
```

**Prevention:** Use `satisfies` over type annotations when you want inference + checking.

---

### TS2345: Argument of type 'X' is not assignable to parameter of type 'Y'

**Pattern:** `Argument of type '.*' is not assignable to parameter`

**Common Causes:**

- Passing wrong shape to function
- Missing required properties
- Extra properties in strict mode

**Fixes:**

```typescript
// Check function signature
// Ensure all required props present
// Remove extra props or widen parameter type
```

**Prevention:** Hover over function params, read the types.

---

### TS2339: Property 'X' does not exist on type 'Y'

**Pattern:** `Property '.*' does not exist on type`

**Common Causes:**

- Typo in property name
- Type not narrowed (union type)
- Property is optional, not checked

**Fixes:**

```typescript
// Narrow the union first
if ("propertyName" in obj) {
  obj.propertyName;
}

// Use optional chaining for optionals
obj.maybeProp?.nested;

// Check for typos - case sensitivity matters
```

**Prevention:** Use discriminated unions with `type` or `kind` fields.

---

### TS7006: Parameter 'x' implicitly has an 'any' type

**Pattern:** `implicitly has an 'any' type`

**Common Causes:**

- Callback without type annotation
- Event handlers
- Array methods with complex inference

**Fixes:**

```typescript
// Annotate the parameter
arr.map((item: ItemType) => item.name);

// Use generic constraint
function process<T extends BaseType>(items: T[]) { }

// For events, use proper event types
onClick={(e: React.MouseEvent<HTMLButtonElement>) => { }}
```

**Prevention:** Enable `noImplicitAny` in tsconfig (should already be on).

---

### TS2532: Object is possibly 'undefined'

**Pattern:** `Object is possibly 'undefined'|Object is possibly 'null'`

**Common Causes:**

- Optional property access without check
- Array `.find()` return
- Map/WeakMap `.get()` return

**Fixes:**

```typescript
// Null check
if (value !== undefined) {
  value.prop;
}

// Optional chaining
value?.prop;

// Non-null assertion (ONLY if you're certain)
value!.prop;

// Default value
const result = value ?? defaultValue;
```

**Prevention:** Prefer `??` over `||` for defaults (handles `0` and `""` correctly).

---

### TS2416: Property 'X' in type 'Y' is not assignable to the same property in base type

**Pattern:** `not assignable to the same property in base type`

**Common Causes:**

- Override with incompatible return type
- Contravariance in method parameters

**Fixes:**

```typescript
// Ensure override matches or extends base type
// Use `override` keyword for clarity
class Child extends Parent {
  override method(): ChildReturn {}
}
```

---

### TS2769: No overload matches this call

**Pattern:** `No overload matches this call`

**Common Causes:**

- Wrong argument count
- Wrong argument types for all overloads
- Generic inference failed

**Fixes:**

```typescript
// Check ALL overload signatures
// Explicitly type generic params
func<SpecificType>(arg);

// Read error details - shows each overload attempt
```

---

## Next.js / React Errors

### Hydration Mismatch

**Pattern:** `Hydration failed|Text content does not match|There was an error while hydrating`

**Common Causes:**

- `Date.now()` or `Math.random()` in render
- Browser-only APIs (`window`, `localStorage`) used during SSR
- Different content between server and client
- Extensions injecting HTML

**Fixes:**

```typescript
// Use useEffect for browser-only code
const [mounted, setMounted] = useState(false);
useEffect(() => setMounted(true), []);
if (!mounted) return null;

// Use dynamic import with ssr: false
const Component = dynamic(() => import('./Component'), { ssr: false });

// Suppress hydration warning (last resort)
<div suppressHydrationWarning>{dynamicContent}</div>
```

**Prevention:** Never access browser APIs during initial render. Use `useEffect`.

---

### "use client" / "use server" Errors

**Pattern:** `You're importing a component that needs|Cannot use .* in a Server Component`

**Common Causes:**

- Using hooks in Server Component
- Using `useState`, `useEffect` without "use client"
- Passing functions as props to Client Components

**Fixes:**

```typescript
// Add directive at TOP of file
"use client";

// Or move state to client wrapper
// ServerComponent.tsx (no hooks)
// ClientWrapper.tsx ("use client" + hooks)
```

**Prevention:** Default to Server Components. Only add "use client" when you need interactivity.

---

### async/await in Client Components

**Pattern:** `async/await is not yet supported in Client Components`

**Common Causes:**

- Trying to fetch data in Client Component
- Using async function in component body

**Fixes:**

```typescript
// Move data fetching to Server Component
// Pass data down as props

// Or use useEffect + useState
const [data, setData] = useState(null);
useEffect(() => {
  fetchData().then(setData);
}, []);

// Or use React Query / SWR
const { data } = useQuery({ queryKey: ["data"], queryFn: fetchData });
```

---

### Metadata Export Errors

**Pattern:** `Metadata export .* is not allowed in a client component`

**Common Causes:**

- `export const metadata` in file with "use client"

**Fixes:**

```typescript
// Remove "use client" from page.tsx
// Move interactive parts to separate Client Component
// Keep metadata in Server Component

// layout.tsx or page.tsx (Server Component)
export const metadata: Metadata = { title: "..." };

// InteractiveSection.tsx (Client Component)
("use client");
// ... hooks and interactivity
```

---

### Dynamic Server Usage

**Pattern:** `Dynamic server usage|couldn't be rendered statically|used dynamic`

**Common Causes:**

- Using `cookies()`, `headers()` without understanding
- `searchParams` in static page
- `fetch` without cache options

**Fixes:**

```typescript
// For dynamic routes
export const dynamic = "force-dynamic";

// For static with revalidation
export const revalidate = 3600; // seconds

// For fetches
fetch(url, { cache: "force-cache" }); // static
fetch(url, { cache: "no-store" }); // dynamic
fetch(url, { next: { revalidate: 60 } }); // ISR
```

---

### Server Action Errors

**Pattern:** `Server actions must be async|Only async functions are allowed|Could not find the module`

**Common Causes:**

- Server action not `async`
- Missing "use server" directive
- Importing server action incorrectly

**Fixes:**

```typescript
// In separate file
"use server";

export async function myAction(formData: FormData) {
  // ...
}

// Or inline in Server Component
async function handleSubmit() {
  "use server";
  // ...
}
```

---

## Effect-TS Errors

### Effect Never Terminates

**Pattern:** `Effect<never, never, never>|type 'never' is not assignable`

**Common Causes:**

- Missing `yield*` in generator
- Effect not returned from pipe
- Type inference failed

**Fixes:**

```typescript
// Ensure yield* for each Effect
const result = yield* someEffect;

// Check pipe returns Effect
pipe(
  effect,
  Effect.map(x => x), // must return Effect
);

// Explicit type annotation
const myEffect: Effect.Effect<Result, Error, Deps> = ...
```

---

### Layer/Service Not Provided

**Pattern:** `Service not found|Layer.*not provided|missing.*dependency`

**Common Causes:**

- Forgot to provide Layer in main
- Layer provided in wrong scope
- Circular dependency

**Fixes:**

```typescript
// Provide all layers
const main = pipe(
  program,
  Effect.provide(MyServiceLive),
  Effect.provide(OtherServiceLive),
);

// Or compose layers
const AppLayer = Layer.merge(MyServiceLive, OtherServiceLive);
Effect.provide(AppLayer);
```

---

### Schema Decode Errors

**Pattern:** `Expected .* but got|Decode error|ParseError`

**Common Causes:**

- Runtime data doesn't match schema
- Missing field
- Wrong type

**Fixes:**

```typescript
// Add optional for missing fields
Schema.optional(Schema.String);

// Add default for missing
Schema.optional(Schema.String, { default: () => "" });

// Transform for type coercion
Schema.transform(Schema.String, Schema.Number, {
  decode: (s) => parseInt(s),
  encode: (n) => String(n),
});
```

---

## Build / Bundler Errors

### Module Not Found

**Pattern:** `Module not found|Cannot find module|Could not resolve`

**Common Causes:**

- Typo in import path
- Missing dependency
- Wrong file extension
- Case sensitivity (Linux)

**Fixes:**

```bash
# Check if package is installed
pnpm list <package>

# Install if missing
pnpm add <package>

# Check for typos in import
# Check file actually exists at that path
# Verify case matches exactly
```

---

### Cannot Use Import Statement Outside Module

**Pattern:** `Cannot use import statement outside a module|SyntaxError: Unexpected token`

**Common Causes:**

- ESM/CJS mismatch
- Missing "type": "module" in package.json
- Node running TS directly

**Fixes:**

```json
// package.json
{ "type": "module" }

// Or use .mjs extension

// For Node + TS, use tsx
npx tsx script.ts
```

---

### Circular Dependency

**Pattern:** `Circular dependency|ReferenceError: Cannot access.*before initialization`

**Common Causes:**

- A imports B, B imports A
- Index barrel files creating cycles

**Fixes:**

```typescript
// Extract shared types to separate file
// types.ts - no imports from A or B
// a.ts - imports types.ts
// b.ts - imports types.ts

// Avoid barrel files (index.ts) that re-export everything
// Import directly from source files
```

**Prevention:** Use `madge` or similar to visualize and prevent cycles.

---

## Runtime Errors

### Cannot Read Property of Undefined

**Pattern:** `Cannot read propert.*of undefined|Cannot read propert.*of null`

**Common Causes:**

- Accessing nested property without null check
- Array index out of bounds
- Object not initialized

**Fixes:**

```typescript
// Optional chaining
obj?.nested?.property;

// Array bounds check
arr[index] ?? defaultValue;

// Nullish coalescing
const value = maybeNull ?? defaultValue;
```

---

### Maximum Call Stack Size Exceeded

**Pattern:** `Maximum call stack size exceeded|RangeError`

**Common Causes:**

- Infinite recursion
- Circular object serialization
- useEffect with bad deps

**Fixes:**

```typescript
// Add base case to recursion
if (depth > MAX_DEPTH) return;

// Use JSON-safe serialization
// Check useEffect deps for objects/functions
// Memoize if needed
const memoized = useMemo(() => computeValue, [stableDep]);
```

---

### Fetch Failed

**Pattern:** `fetch failed|ECONNREFUSED|ETIMEDOUT|NetworkError`

**Common Causes:**

- Server not running
- Wrong URL/port
- CORS issues
- Network timeout

**Fixes:**

```typescript
// Check server is running
// Verify URL (http vs https, port)
// Add error handling
try {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
} catch (e) {
  if (e instanceof TypeError) {
    // Network error
  }
}

// For CORS, check server headers or use proxy
```

---

## Adding New Patterns

When you encounter a novel error:

1. **Identify the pattern**: What's the error message/code?
2. **Find the root cause**: Why did this happen?
3. **Document the fix**: What solved it?
4. **Add prevention**: How to avoid it next time?

```markdown
### <Error Name/Code>

**Pattern:** `<regex-friendly error message fragment>`

**Common Causes:**

- <cause 1>
- <cause 2>

**Fixes:**
\`\`\`typescript
// <solution code>
\`\`\`

**Prevention:** <how to avoid>
```
