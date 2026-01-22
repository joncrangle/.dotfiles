# SolidJS Examples

## 1. Basic Counter (Signal)
```tsx
import { createSignal } from "solid-js";

function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <button onClick={() => setCount((c) => c + 1)}>
      Count: {count()}
    </button>
  );
}
```

## 2. Derived State (Memo)
```tsx
import { createSignal, createMemo } from "solid-js";

function Fibonacci() {
  const [count, setCount] = createSignal(10);
  const fib = createMemo(() => {
    return calculateFib(count());
  });

  return (
    <div>
      <input 
        type="number" 
        value={count()} 
        onInput={(e) => setCount(parseInt(e.currentTarget.value))} 
      />
      <p>Fibonacci: {fib()}</p>
    </div>
  );
}
```

## 3. Async Data (Resource)
```tsx
import { createResource, Show } from "solid-js";

const fetchUser = async (id: string) => {
  const res = await fetch(\`/api/users/\${id}\`);
  return res.json();
};

function UserProfile(props: { id: string }) {
  const [user] = createResource(() => props.id, fetchUser);

  return (
    <Show when={!user.loading} fallback={<p>Loading...</p>}>
      <h1>{user()?.name}</h1>
      <Show when={user.error}>
        <p class="error">Failed to load: {user.error.message}</p>
      </Show>
    </Show>
  );
}
```

## 4. Control Flow (For & Index)
```tsx
import { createSignal, For, Index } from "solid-js";

function TodoList() {
  const [todos, setTodos] = createSignal([
    { id: 1, text: "Buy milk" },
    { id: 2, text: "Walk dog" }
  ]);

  return (
    <ul>
      {/* Use For for object references (keyed by object identity) */}
      <For each={todos()}>
        {(todo, index) => (
          <li>
            {index() + 1}. {todo.text}
          </li>
        )}
      </For>
    </ul>
  );
}

function PrimitiveList() {
    const [names, setNames] = createSignal(["Alice", "Bob"]);
    
    return (
        <ul>
            {/* Use Index for primitives to avoid recreating DOM nodes when value changes but index stays same */}
            <Index each={names()}>
                {(name, index) => <li>{index}: {name()}</li>}
            </Index>
        </ul>
    )
}
```

## 5. Store (Nested State)
```tsx
import { createStore } from "solid-js/store";

function TaskManager() {
  const [state, setState] = createStore({
    tasks: [],
    meta: { count: 0 }
  });

  const addTask = (text: string) => {
    setState("tasks", (t) => [...t, { id: Date.now(), text, done: false }]);
    setState("meta", "count", (c) => c + 1);
  };

  const toggleTask = (id: number) => {
    setState("tasks", (t) => t.id === id, "done", (d) => !d);
  };
  
  // Updating nested array
  const updateTaskText = (id: number, text: string) => {
      setState("tasks", (t) => t.id === id, "text", text);
  }

  return (
    // ...
  );
}
```

## 6. Suspense & ErrorBoundary
```tsx
import { Suspense, ErrorBoundary, createResource } from "solid-js";

function AsyncComponent() {
    const [data] = createResource(async () => {
        await new Promise(r => setTimeout(r, 1000));
        if (Math.random() > 0.5) throw new Error("Random Failure");
        return "Success!";
    });
    
    return <div>{data()}</div>;
}

function App() {
    return (
        <ErrorBoundary fallback={(err, reset) => (
            <div onClick={reset}>Error: {err.toString()}. Click to retry.</div>
        )}>
            <Suspense fallback={<div>Loading...</div>}>
                <AsyncComponent />
            </Suspense>
        </ErrorBoundary>
    )
}
```

## 7. Directives (use:___)
```tsx
// Declare module for TS support
declare module "solid-js" {
  namespace JSX {
    interface Directives {
      clickOutside: (el: HTMLElement, accessor: () => any) => void;
    }
  }
}

function clickOutside(el: HTMLElement, accessor: () => any) {
  const onClick = (e: MouseEvent) => !el.contains(e.target as Node) && accessor()?.();
  document.body.addEventListener("click", onClick);
  onCleanup(() => document.body.removeEventListener("click", onClick));
}

function Modal() {
    return (
        <div use:clickOutside={() => console.log("Closed!")}>
            Click outside me
        </div>
    )
}
```
