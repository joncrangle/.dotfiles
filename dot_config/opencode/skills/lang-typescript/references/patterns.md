# TypeScript Implementation Guide & Patterns

## TypeScript 5.9 Key Features

### Satisfies Operator - Type checking without widening
```typescript
type Colors = "red" | "green" | "blue";
const palette = {
  red: [255, 0, 0],
  green: "#00ff00",
  blue: [0, 0, 255],
} satisfies Record<Colors, string | number[]>;

palette.red.map((n) => n * 2); // Works - red is number[]
palette.green.toUpperCase();   // Works - green is string
```

### Deferred Module Evaluation
```typescript
import defer * as analytics from "./heavy-analytics";
function trackEvent(name: string) {
  analytics.track(name); // Loads module on first use
}
```

### Modern Decorators (Stage 3)
```typescript
function logged<T extends (...args: any[]) => any>(
  target: T,
  context: ClassMethodDecoratorContext
) {
  return function (this: ThisParameterType<T>, ...args: Parameters<T>) {
    console.log(`Calling ${String(context.name)}`);
    return target.apply(this, args);
  };
}

class API {
  @logged
  async fetchUser(id: string) { return fetch(`/api/users/${id}`); }
}
```

## Solid JS Patterns

**CRITICAL: This is SolidJS, NOT React!**
**SolidJS uses different primitives than React. Never use React hooks!**

| SolidJS | React (DON'T USE) |
|---------|-------------------|
| `createSignal()` | `useState()` |
| `createEffect()` | `useEffect()` |
| `createStore()` | `useState()` |
| `createMemo()` | `useMemo()` |
| `<For>` | `array.map()` |
| `<Show>` | `&&` conditional |

### Signal Pattern (Simple State)
```tsx
import { createSignal } from "solid-js";

const Counter: Component = () => {
    // Signal returns [getter, setter]
    const [count, setCount] = createSignal(0);

    // Getter is a function - must call it
    const increment = () => {
        setCount(count() + 1);  // count() to read
    };

    // Can also use callback form
    const decrement = () => {
        setCount(c => c - 1);   // Callback receives current value
    };

    return (
        <div>
            <p>Count: {count()}</p>  {/* Must call count() */}
            <button onClick={increment}>+</button>
            <button onClick={decrement}>-</button>
        </div>
    );
};
```

### Store Pattern (Complex State)
```tsx
import { createStore } from "solid-js/store";

interface FormState {
    firstName: string;
    lastName: string;
    email: string;
    preferences: {
        theme: "light" | "dark";
        notifications: boolean;
    };
}

const UserForm: Component = () => {
    const [formState, setFormState] = createStore<FormState>({
        firstName: "",
        lastName: "",
        email: "",
        preferences: {
            theme: "light",
            notifications: true,
        },
    });

    // Update top-level field
    const updateFirstName = (value: string) => {
        setFormState("firstName", value);
    };

    // Update nested field
    const updateTheme = (theme: "light" | "dark") => {
        setFormState("preferences", "theme", theme);
    };

    // Update multiple fields
    const updatePreferences = () => {
        setFormState("preferences", {
            theme: "dark",
            notifications: false,
        });
    };

    return (
        <form>
            <input
                value={formState.firstName}
                onInput={(e) => setFormState("firstName", e.currentTarget.value)}
            />
            <input
                value={formState.email}
                onInput={(e) => setFormState("email", e.currentTarget.value)}
            />
        </form>
    );
};
```

### Memo Pattern (Computed Values)
```tsx
import { createSignal, createMemo } from "solid-js";

const UserProfile: Component = () => {
    const [firstName, setFirstName] = createSignal("John");
    const [lastName, setLastName] = createSignal("Doe");

    // Memoized computed value
    const fullName = createMemo(() => {
        return `${firstName()} ${lastName()}`;
    });

    // Only recalculates when firstName or lastName changes
    const initials = createMemo(() => {
        return `${firstName()[0]}${lastName()[0]}`;
    });

    return (
        <div>
            <p>Full Name: {fullName()}</p>
            <p>Initials: {initials()}</p>
        </div>
    );
};
```

### Resource Pattern (Data Fetching)
```tsx
import { createSignal, createResource } from "solid-js";

const [userId, setUserId] = createSignal(1);

const [user] = createResource(userId, async (id) => {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
});

// Automatically refetches when userId changes
setUserId(2);
```

### Component Pattern
```tsx
import { Component, createSignal } from "solid-js";
import styles from "./MyComponent.module.scss";

interface MyComponentProps {
    title: string;
    initialCount?: number;
    onSubmit?: (value: number) => void;
}

const MyComponent: Component<MyComponentProps> = (props) => {
    const [count, setCount] = createSignal(props.initialCount || 0);

    const handleSubmit = () => {
        props.onSubmit?.(count());
    };

    return (
        <div class={styles.container}>
            <h2>{props.title}</h2>
            <p>Count: {count()}</p>
            <button onClick={() => setCount(c => c + 1)}>Increment</button>
            <button onClick={handleSubmit}>Submit</button>
        </div>
    );
};

export default MyComponent;
```

### Conditional Rendering
```tsx
import { Show } from "solid-js";

<Show when={isLoading()} fallback={<p>Loaded!</p>}>
    <Spinner />
</Show>
```

### List Rendering
```tsx
import { For } from "solid-js";

<For each={users()}>
    {(user) => (
        <div class={styles.userCard}>
            <p>{user.name}</p>
        </div>
    )}
</For>
```

## TanStack Start Patterns

### Route Definition
```typescript
// app/routes/posts/$id.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$id')({
  loader: async ({ params }) => {
    return fetchPost(params.id)
  },
  component: PostComponent,
})

function PostComponent() {
  const post = Route.useLoaderData()
  return <h1>{post.title}</h1>
}
```

### Server Functions
```typescript
import { createServerFn } from '@tanstack/start'
import { valibotValidator } from '@tanstack/valibot-adapter'
import * as v from 'valibot'

const UpdateUserSchema = v.object({
  id: v.pipe(v.string(), v.uuid()),
  name: v.pipe(v.string(), v.minLength(2), v.maxLength(100)),
})

export const updateUser = createServerFn({ method: 'POST' })
  .validator(valibotValidator(UpdateUserSchema))
  .handler(async ({ data }) => {
    return db.user.update({ where: { id: data.id }, data })
  })
```

## Valibot Schema Patterns

```typescript
import * as v from "valibot";

const UserSchema = v.object({
  id: v.pipe(v.string(), v.uuid()),
  name: v.pipe(v.string(), v.minLength(2), v.maxLength(100)),
  email: v.pipe(v.string(), v.email()),
  role: v.picklist(["admin", "user", "guest"]),
});

const result = v.safeParse(UserSchema, data);
```

## Advanced State Management
```typescript
import { createContext, useContext } from "solid-js";
import { createStore } from "solid-js/store";

const AuthContext = createContext();

export const AuthProvider = (props) => {
  const [state, setState] = createStore({ user: null, isAuthenticated: false });
  // ...
  return <AuthContext.Provider value={[state, actions]}>{props.children}</AuthContext.Provider>;
};
```
