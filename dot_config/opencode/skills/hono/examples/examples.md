# Hono Examples

## 1. Basic App with RPC & Validation
The "Gold Standard" Hono pattern: Zod validation + RPC export.

```typescript
import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";

const app = new Hono();

const route = app
  .post(
    "/posts",
    zValidator(
      "json",
      z.object({
        title: z.string(),
        body: z.string(),
      })
    ),
    (c) => {
      // Fully typed body from validator
      const { title, body } = c.req.valid("json");
      return c.json({
        id: 123,
        message: \`Created: \${title}\`,
      });
    }
  )
  .get("/hello", (c) => {
    return c.json({ message: "Hello Hono!" });
  });

// Export type for client
export type AppType = typeof route;
export default app;
```

## 2. Cloudflare Workers (Bindings)
Accessing KV, D1, or R2 bindings via `c.env`.

```typescript
import { Hono } from "hono";

// Define Bindings Type
type Bindings = {
  MY_KV: KVNamespace;
  DB: D1Database;
  API_KEY: string;
};

const app = new Hono<{ Bindings: Bindings }>();

app.get("/kv/:key", async (c) => {
  const key = c.req.param("key");
  // c.env is typed!
  const value = await c.env.MY_KV.get(key);
  return c.json({ key, value });
});

app.get("/users", async (c) => {
  const { results } = await c.env.DB.prepare("SELECT * FROM users").all();
  return c.json(results);
});

export default app;
```

## 3. Middleware (Auth & Logging)
Using built-in and custom middleware.

```typescript
import { Hono } from "hono";
import { logger } from "hono/logger";
import { cors } from "hono/cors";
import { createMiddleware } from "hono/factory";

const app = new Hono();

// Built-in
app.use("*", logger());
app.use("/api/*", cors());

// Custom Middleware
const authMiddleware = createMiddleware(async (c, next) => {
  const token = c.req.header("Authorization");
  if (token !== "secret") {
    return c.json({ error: "Unauthorized" }, 401);
  }
  await next();
});

app.use("/protected/*", authMiddleware);

app.get("/protected/profile", (c) => c.json({ user: "admin" }));
```

## 4. Hono Client (RPC)
Consuming the API type-safely on the client (e.g., in React/Solid).

```typescript
import { hc } from "hono/client";
import type { AppType } from "./server"; // Import type only

const client = hc<AppType>("http://localhost:8787");

async function createPost() {
  const res = await client.posts.$post({
    json: {
      title: "My Post",
      body: "Content here",
    },
  });

  if (res.ok) {
    const data = await res.json();
    console.log(data.message); // Typed!
  }
}
```

## 5. Testing (Integration)
Testing without spinning up a server.

```typescript
import { testClient } from "hono/testing";
import app from "./server"; // The Hono app instance

test("GET /hello", async () => {
  const res = await app.request("/hello");
  expect(res.status).toBe(200);
  expect(await res.json()).toEqual({ message: "Hello Hono!" });
});

test("RPC Test", async () => {
  const client = testClient(app);
  const res = await client.hello.$get();
  expect(await res.json()).toEqual({ message: "Hello Hono!" });
});
```

## 6. JSX Server-Side Rendering
Using `hono/jsx` for lightweight HTML responses.

```tsx
import { Hono } from "hono";
import { FC } from "hono/jsx";

const app = new Hono();

const Layout: FC = (props) => (
  <html>
    <body>{props.children}</body>
  </html>
);

app.get("/", (c) => {
  return c.html(
    <Layout>
      <h1>Hello Hono JSX</h1>
      <p>Server-side rendered!</p>
    </Layout>
  );
});
```
