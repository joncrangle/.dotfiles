# Vitest Examples

## 1. Basic Test Suite
Standard BDD style (Jest-compatible).

```typescript
import { describe, it, expect } from "vitest";
import { add } from "./math";

describe("Math Utils", () => {
  it("should add two numbers", () => {
    expect(add(1, 2)).toBe(3);
  });

  it("should handle negative numbers", () => {
    expect(add(-1, -2)).toBe(-3);
  });
});
```

## 2. Mocking (vi.fn & vi.mock)
Isolating dependencies.

```typescript
import { describe, it, expect, vi } from "vitest";
import * as db from "./db";
import { createUser } from "./user";

// Mock entire module
vi.mock("./db", () => ({
  insertUser: vi.fn(),
}));

describe("User Service", () => {
  it("should create a user", async () => {
    // Setup return value
    vi.mocked(db.insertUser).mockResolvedValue({ id: 1, name: "Alice" });

    const user = await createUser("Alice");

    expect(db.insertUser).toHaveBeenCalledWith("Alice");
    expect(user).toEqual({ id: 1, name: "Alice" });
  });
});
```

## 3. Spying (vi.spyOn)
Spying on existing object methods.

```typescript
import { it, expect, vi } from "vitest";

const cart = {
  getTotal: () => 100,
};

it("should spy on method", () => {
  const spy = vi.spyOn(cart, "getTotal");
  
  cart.getTotal();
  
  expect(spy).toHaveBeenCalled();
  
  // Restore original implementation
  spy.mockRestore();
});
```

## 4. In-Source Testing
Writing tests inside the source file (requires config).

```typescript
// src/add.ts
export const add = (a: number, b: number) => a + b;

// In-source test block
if (import.meta.vitest) {
  const { it, expect } = import.meta.vitest;
  it("add", () => {
    expect(add(1, 2)).toBe(3);
  });
}
```

## 5. Snapshot Testing
Comparing output against a stored snapshot.

```typescript
import { it, expect } from "vitest";

it("should match snapshot", () => {
  const user = { id: 1, name: "Alice", createdAt: new Date() };
  
  expect(user).toMatchSnapshot({
    createdAt: expect.any(Date),
  });
});
```

## 6. Test Context (Fixtures)
Passing context to tests.

```typescript
import { test } from "vitest";

// Extend test context (advanced)
const myTest = test.extend({
  db: async ({}, use) => {
    const db = await connect();
    await use(db);
    await db.disconnect();
  },
});

myTest("database test", ({ db }) => {
  // db is available and auto-cleaned
});
```
