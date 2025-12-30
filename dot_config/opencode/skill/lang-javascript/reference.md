# JavaScript Development Reference

## ES2024/ES2025 Complete Reference

### ES2024 Feature Matrix

| Feature | Description | Use Case |
|---------|-------------|----------|
| Set Methods | intersection, union, difference, etc. | Collection operations |
| Promise.withResolvers | External resolve/reject access | Deferred promises |
| Immutable Arrays | toSorted, toReversed, toSpliced, with | Functional programming |
| Object.groupBy | Group array items by key | Data categorization |
| Unicode String Methods | isWellFormed, toWellFormed | Unicode validation |
| ArrayBuffer Resizing | resize, transfer methods | Memory management |

### ES2025 Feature Matrix

| Feature | Description | Use Case |
|---------|-------------|----------|
| Import Attributes | with { type: 'json' } | JSON/CSS modules |
| RegExp.escape | Escape regex special chars | Safe regex patterns |
| Iterator Helpers | map, filter, take on iterators | Lazy iteration |
| Float16Array | 16-bit floating point arrays | ML/Graphics |
| Duplicate Named Capture Groups | Same name in regex alternation | Pattern matching |

### Complete Set Operations

```javascript
const setA = new Set([1, 2, 3, 4, 5]);
const setB = new Set([4, 5, 6, 7, 8]);

// Union - all elements from both sets
const union = setA.union(setB);
// Set {1, 2, 3, 4, 5, 6, 7, 8}

// Intersection - elements in both sets
const intersection = setA.intersection(setB);
// Set {4, 5}

// Difference - elements in A but not in B
const difference = setA.difference(setB);
// Set {1, 2, 3}

// Symmetric Difference - elements in either but not both
const symmetricDiff = setA.symmetricDifference(setB);
// Set {1, 2, 3, 6, 7, 8}

// Subset check - all elements of A are in B
setA.isSubsetOf(setB); // false
new Set([4, 5]).isSubsetOf(setB); // true

// Superset check - A contains all elements of B
setA.isSupersetOf(new Set([1, 2])); // true

// Disjoint check - no common elements
setA.isDisjointFrom(new Set([10, 11])); // true
```

### Iterator Helpers (ES2025)

```javascript
function* fibonacci() {
  let a = 0, b = 1;
  while (true) {
    yield a;
    [a, b] = [b, a + b];
  }
}

// Take first 10 Fibonacci numbers
const first10 = fibonacci().take(10).toArray();
// [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

// Filter and map
const evenFib = fibonacci()
  .filter(n => n % 2 === 0)
  .map(n => n * 2)
  .take(5)
  .toArray();
// [0, 4, 16, 68, 288]

// Reduce with iterator
const sum = fibonacci()
  .take(10)
  .reduce((acc, n) => acc + n, 0);
// 88

// forEach on iterator
fibonacci()
  .take(5)
  .forEach(n => console.log(n));

// Find on iterator
const firstOver100 = fibonacci().find(n => n > 100);
// 144

// Some and every
fibonacci().take(10).some(n => n > 10); // true
fibonacci().take(5).every(n => n < 10); // true
```

---

## Bun Runtime Reference

### Bun Feature Overview

| Feature | Description |
|---------|-------------|
| JavaScript Runtime | V8-compatible, 4x faster startup than Node.js |
| Package Manager | 30x faster than npm |
| Bundler | Built-in, esbuild-compatible |
| Test Runner | Jest-compatible, built-in |
| TypeScript | Native support, no compilation step |
| SQLite | Built-in via `bun:sqlite` |
| File I/O | `Bun.file()`, `Bun.write()` |
| HTTP Server | `Bun.serve()` |
| Password Hashing | `Bun.password.hash()`, `Bun.password.verify()` |

### Bun File I/O

```javascript
// Read file
const file = Bun.file('./data.json');
const exists = await file.exists();
const size = file.size;
const type = file.type; // MIME type

// Read as different formats
const text = await file.text();
const json = await file.json();
const buffer = await file.arrayBuffer();
const stream = file.stream();

// Write file
await Bun.write('./output.txt', 'Hello, World!');
await Bun.write('./data.json', JSON.stringify({ key: 'value' }));
await Bun.write('./copy.txt', Bun.file('./original.txt'));

// Glob files
const glob = new Bun.Glob('**/*.js');
for await (const file of glob.scan('.')) {
  console.log(file);
}

// Scan with options
for await (const file of glob.scan({
  cwd: './src',
  onlyFiles: true,
  absolute: true,
})) {
  console.log(file);
}
```

### Bun HTTP Server

```javascript
// Basic server
Bun.serve({
  port: 3000,
  fetch(req) {
    const url = new URL(req.url);

    if (url.pathname === '/') {
      return new Response('Hello World!');
    }

    if (url.pathname === '/api/data') {
      return Response.json({ message: 'Hello' });
    }

    return new Response('Not Found', { status: 404 });
  },
});

// With WebSocket
Bun.serve({
  port: 3000,
  fetch(req, server) {
    if (server.upgrade(req)) {
      return; // WebSocket upgrade
    }
    return new Response('HTTP response');
  },
  websocket: {
    open(ws) {
      console.log('Client connected');
    },
    message(ws, message) {
      ws.send(`Echo: ${message}`);
    },
    close(ws) {
      console.log('Client disconnected');
    },
  },
});
```

### Bun SQLite

```javascript
import { Database } from 'bun:sqlite';

// Create/open database
const db = new Database('app.db');
const memoryDb = new Database(':memory:');

// Execute statements
db.run(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
  )
`);

// Prepared statements
const insert = db.prepare('INSERT INTO users (name, email) VALUES (?, ?)');
insert.run('John', 'john@example.com');

// Query
const select = db.query('SELECT * FROM users WHERE id = ?');
const user = select.get(1);
const allUsers = db.query('SELECT * FROM users').all();

// Transaction
const insertMany = db.transaction((users) => {
  for (const user of users) {
    insert.run(user.name, user.email);
  }
});

insertMany([
  { name: 'Alice', email: 'alice@example.com' },
  { name: 'Bob', email: 'bob@example.com' },
]);
```

### Bun Password Hashing

```javascript
// Hash password (uses Argon2id by default)
const hash = await Bun.password.hash('mypassword');

// Verify password
const isValid = await Bun.password.verify('mypassword', hash);

// With options
const customHash = await Bun.password.hash('mypassword', {
  algorithm: 'argon2id', // or 'argon2i', 'argon2d', 'bcrypt'
  memoryCost: 65536,
  timeCost: 3,
});
```

### Bun Environment Variables

```javascript
// Access environment variables
const port = Bun.env.PORT || '3000';
const secret = Bun.env.JWT_SECRET;

// Check if running in Bun
if (typeof Bun !== 'undefined') {
  console.log('Running in Bun');
}
```

---

## Hono Framework Reference

### Hono Middleware Stack

```javascript
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { secureHeaders } from 'hono/secure-headers';
import { prettyJSON } from 'hono/pretty-json';
import { compress } from 'hono/compress';
import { etag } from 'hono/etag';
import { timing } from 'hono/timing';
import { cache } from 'hono/cache';
import { jwt } from 'hono/jwt';
import { basicAuth } from 'hono/basic-auth';
import { bearerAuth } from 'hono/bearer-auth';

const app = new Hono();

// Logging
app.use('*', logger());

// Security headers
app.use('*', secureHeaders());

// Response timing
app.use('*', timing());

// CORS
app.use('/api/*', cors({
  origin: ['http://localhost:3000'],
  credentials: true,
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE'],
}));

// Compression
app.use('*', compress());

// ETag for caching
app.use('*', etag());

// Pretty JSON in development
app.use('/api/*', prettyJSON());

// Cache control
app.get('/api/static/*', cache({
  cacheName: 'static',
  cacheControl: 'max-age=3600',
}));

// JWT authentication
app.use('/api/protected/*', jwt({ secret: Bun.env.JWT_SECRET }));

// Basic auth
app.use('/admin/*', basicAuth({
  username: 'admin',
  password: 'secret',
}));
```

### Hono Routing Patterns

```javascript
import { Hono } from 'hono';

const app = new Hono();

// Basic routes
app.get('/', (c) => c.text('Hello'));
app.post('/users', (c) => c.json({ created: true }));
app.put('/users/:id', (c) => c.json({ updated: true }));
app.delete('/users/:id', (c) => c.body(null, 204));

// Path parameters
app.get('/users/:id', (c) => {
  const id = c.req.param('id');
  return c.json({ id });
});

// Multiple parameters
app.get('/posts/:postId/comments/:commentId', (c) => {
  const { postId, commentId } = c.req.param();
  return c.json({ postId, commentId });
});

// Query parameters
app.get('/search', (c) => {
  const query = c.req.query('q');
  const page = c.req.query('page') || '1';
  return c.json({ query, page });
});

// Request body
app.post('/users', async (c) => {
  const body = await c.req.json();
  return c.json(body, 201);
});

// Headers
app.get('/headers', (c) => {
  const auth = c.req.header('Authorization');
  return c.json({ auth });
});

// Route groups
const api = new Hono();
api.get('/users', (c) => c.json([]));
api.get('/posts', (c) => c.json([]));

app.route('/api/v1', api);

// Wildcard routes
app.get('/files/*', (c) => {
  const path = c.req.path;
  return c.text(`File: ${path}`);
});
```

### Hono Validation with Valibot

```javascript
import { Hono } from 'hono';
import { vValidator } from '@hono/valibot-validator';
import * as v from 'valibot';

const app = new Hono();

// JSON body validation
const CreateUserSchema = v.object({
  name: v.pipe(v.string(), v.minLength(2)),
  email: v.pipe(v.string(), v.email()),
  age: v.optional(v.pipe(v.number(), v.minValue(0))),
});

app.post('/users',
  vValidator('json', CreateUserSchema),
  (c) => {
    const data = c.req.valid('json');
    return c.json(data, 201);
  }
);

// Query validation
const PaginationSchema = v.object({
  page: v.optional(v.pipe(v.string(), v.transform(Number)), '1'),
  limit: v.optional(v.pipe(v.string(), v.transform(Number)), '10'),
});

app.get('/users',
  vValidator('query', PaginationSchema),
  (c) => {
    const { page, limit } = c.req.valid('query');
    return c.json({ page, limit });
  }
);

// Param validation
const IdSchema = v.object({
  id: v.pipe(v.string(), v.uuid()),
});

app.get('/users/:id',
  vValidator('param', IdSchema),
  (c) => {
    const { id } = c.req.valid('param');
    return c.json({ id });
  }
);

// Custom error handling
app.post('/strict',
  vValidator('json', CreateUserSchema, (result, c) => {
    if (!result.success) {
      return c.json({
        error: 'Validation failed',
        issues: result.issues,
      }, 400);
    }
  }),
  (c) => c.json({ ok: true })
);
```

### Hono Context Helpers

```javascript
// Response helpers
c.text('Hello');
c.json({ key: 'value' });
c.html('<h1>Hello</h1>');
c.body(null, 204);
c.redirect('/new-location');
c.redirect('/new-location', 301);

// Set headers
c.header('X-Custom', 'value');
c.header('Set-Cookie', 'name=value; HttpOnly');

// Set status
return c.json({ error: 'Not found' }, 404);

// Stream response
return c.stream(async (stream) => {
  await stream.write('Hello');
  await stream.sleep(1000);
  await stream.write(' World');
});

// Set/get context values
c.set('userId', '123');
const userId = c.get('userId');

// Get JWT payload
const payload = c.get('jwtPayload');
```

---

## Bun Testing Reference

### Test Syntax

```javascript
import { describe, it, test, expect, beforeAll, afterAll, beforeEach, afterEach, mock, spyOn } from 'bun:test';

describe('Math operations', () => {
  it('adds numbers', () => {
    expect(1 + 1).toBe(2);
  });

  test('subtracts numbers', () => {
    expect(5 - 3).toBe(2);
  });
});

// Async tests
it('fetches data', async () => {
  const response = await fetch('https://api.example.com/data');
  expect(response.ok).toBe(true);
});

// Skip and todo
it.skip('skipped test', () => {});
it.todo('implement later');

// Only run this test
it.only('focused test', () => {});
```

### Matchers

```javascript
// Equality
expect(value).toBe(expected);           // Strict equality
expect(value).toEqual(expected);        // Deep equality
expect(value).toStrictEqual(expected);  // Strict deep equality

// Truthiness
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();

// Numbers
expect(value).toBeGreaterThan(3);
expect(value).toBeGreaterThanOrEqual(3);
expect(value).toBeLessThan(5);
expect(value).toBeLessThanOrEqual(5);
expect(value).toBeCloseTo(0.3, 5);

// Strings
expect(value).toMatch(/regex/);
expect(value).toContain('substring');

// Arrays
expect(array).toContain(item);
expect(array).toHaveLength(3);

// Objects
expect(object).toHaveProperty('key');
expect(object).toHaveProperty('key', 'value');
expect(object).toMatchObject({ partial: 'match' });

// Errors
expect(() => fn()).toThrow();
expect(() => fn()).toThrow('message');
expect(() => fn()).toThrow(Error);

// Async errors
await expect(asyncFn()).rejects.toThrow();

// Snapshots
expect(value).toMatchSnapshot();
```

### Mocking

```javascript
import { mock, spyOn } from 'bun:test';

// Create mock function
const mockFn = mock(() => 'mocked value');

mockFn('arg1', 'arg2');

expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(1);
expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');

// Mock implementation
mockFn.mockImplementation(() => 'new value');
mockFn.mockReturnValue('static value');
mockFn.mockResolvedValue('async value');
mockFn.mockRejectedValue(new Error('error'));

// Spy on object method
const obj = { method: () => 'original' };
const spy = spyOn(obj, 'method');

obj.method();

expect(spy).toHaveBeenCalled();

// Mock module
mock.module('./database.js', () => ({
  db: {
    query: mock(() => []),
  },
}));
```

---

## Valibot Reference

### Schema Types

| Type | Example |
|------|---------|
| string | `v.string()` |
| number | `v.number()` |
| boolean | `v.boolean()` |
| object | `v.object({ ... })` |
| array | `v.array(v.string())` |
| optional | `v.optional(v.string())` |
| nullable | `v.nullable(v.string())` |
| picklist | `v.picklist(['a', 'b'])` |
| literal | `v.literal('value')` |
| union | `v.union([v.string(), v.number()])` |
| variant | `v.variant('type', [...])` |

### Pipeline Pattern

```javascript
import * as v from 'valibot';

// Chain validations with pipe
const EmailSchema = v.pipe(
  v.string(),
  v.email('Invalid email'),
  v.maxLength(255)
);

const AgeSchema = v.pipe(
  v.number(),
  v.minValue(0),
  v.maxValue(120)
);

// Transform
const SlugSchema = v.pipe(
  v.string(),
  v.transform((s) => s.toLowerCase().replace(/\s+/g, '-'))
);

// Coerce from string
const NumberFromString = v.pipe(
  v.string(),
  v.transform(Number),
  v.number()
);
```

### Parsing

```javascript
// Throws on error
const data = v.parse(Schema, input);

// Safe parse (no throw)
const result = v.safeParse(Schema, input);
if (result.success) {
  console.log(result.output);
} else {
  console.log(result.issues);
}
```

---

## Context7 Library Mappings

### Primary Libraries

```
/oven-sh/bun             - Bun runtime
/honojs/hono             - Hono web framework
/fabian-hiller/valibot   - Valibot validation
/drizzle-team/drizzle-orm - Drizzle ORM
```

### Build Tools

```
/biomejs/biome           - Biome linter/formatter
/evanw/esbuild           - esbuild bundler
```

### Utilities

```
/date-fns/date-fns       - Date utilities
```

---

## Security Best Practices

### Input Validation

```javascript
import * as v from 'valibot';

const userSchema = v.object({
  name: v.pipe(v.string(), v.minLength(1), v.maxLength(100)),
  email: v.pipe(v.string(), v.email()),
  age: v.optional(v.pipe(v.number(), v.minValue(0), v.maxValue(150))),
});

function validateUser(input) {
  const result = v.safeParse(userSchema, input);
  if (!result.success) {
    throw new Error(result.issues[0].message);
  }
  return result.output;
}
```

### Environment Variable Validation

```javascript
import * as v from 'valibot';

const envSchema = v.object({
  NODE_ENV: v.picklist(['development', 'production', 'test']),
  PORT: v.pipe(v.string(), v.transform(Number)),
  DATABASE_URL: v.pipe(v.string(), v.minLength(1)),
  JWT_SECRET: v.pipe(v.string(), v.minLength(32)),
});

const env = v.parse(envSchema, Bun.env);
export default env;
```

### Secure Headers with Hono

```javascript
import { Hono } from 'hono';
import { secureHeaders } from 'hono/secure-headers';

const app = new Hono();

app.use('*', secureHeaders({
  contentSecurityPolicy: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],
  },
  crossOriginEmbedderPolicy: true,
  crossOriginOpenerPolicy: 'same-origin',
  crossOriginResourcePolicy: 'same-origin',
  strictTransportSecurity: 'max-age=31536000; includeSubDomains',
}));
```

---

Last Updated: 2025-12-30
Version: 1.1.0
