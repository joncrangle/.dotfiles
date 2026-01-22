# JavaScript Implementation Guide & Patterns

## ES2024 Key Features

### Set Operations
```javascript
const setA = new Set([1, 2, 3, 4]);
const setB = new Set([3, 4, 5, 6]);

setA.intersection(setB);      // Set {3, 4}
setA.union(setB);             // Set {1, 2, 3, 4, 5, 6}
setA.difference(setB);        // Set {1, 2}
setA.symmetricDifference(setB); // Set {1, 2, 5, 6}
setA.isSubsetOf(setB);        // false
setA.isSupersetOf(setB);      // false
setA.isDisjointFrom(setB);    // false
```

### Promise.withResolvers()
```javascript
function createDeferred() {
  const { promise, resolve, reject } = Promise.withResolvers();
  return { promise, resolve, reject };
}

const deferred = createDeferred();
setTimeout(() => deferred.resolve('done'), 1000);
const result = await deferred.promise;
```

### Immutable Array Methods
```javascript
const original = [3, 1, 4, 1, 5];

// New methods return new arrays (don't mutate)
const sorted = original.toSorted();           // [1, 1, 3, 4, 5]
const reversed = original.toReversed();       // [5, 1, 4, 1, 3]
const spliced = original.toSpliced(1, 2, 9);  // [3, 9, 1, 5]
const changed = original.with(2, 99);         // [3, 1, 99, 1, 5]

console.log(original); // [3, 1, 4, 1, 5] - unchanged
```

### Object.groupBy and Map.groupBy
```javascript
const items = [
  { type: 'fruit', name: 'apple' },
  { type: 'vegetable', name: 'carrot' },
  { type: 'fruit', name: 'banana' },
];

const grouped = Object.groupBy(items, item => item.type);
// { fruit: [{...}, {...}], vegetable: [{...}] }

const mapGrouped = Map.groupBy(items, item => item.type);
// Map { 'fruit' => [...], 'vegetable' => [...] }
```

## ES2025 Features

### Import Attributes (JSON Modules)
```javascript
import config from './config.json' with { type: 'json' };
import styles from './styles.css' with { type: 'css' };

console.log(config.apiUrl);
```

### RegExp.escape
```javascript
const userInput = 'hello (world)';
const safePattern = RegExp.escape(userInput);
// "hello\\ \\(world\\)"
const regex = new RegExp(safePattern);
```

## Bun Runtime

Bun is an all-in-one JavaScript runtime with built-in bundler, test runner, and package manager.

### File I/O
```javascript
// Read file
const file = Bun.file('./data.json');
const content = await file.json();

// Write file
await Bun.write('./output.txt', 'Hello, World!');

// Glob files
const glob = new Bun.Glob('**/*.js');
for await (const file of glob.scan('.')) {
  console.log(file);
}
```

### HTTP Server
```javascript
Bun.serve({
  port: 3000,
  fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === '/api/health') {
      return Response.json({ status: 'ok' });
    }
    return new Response('Not Found', { status: 404 });
  },
});
```

### SQLite (Built-in)
```javascript
import { Database } from 'bun:sqlite';

const db = new Database('app.db');

db.run(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
  )
`);

const insert = db.prepare('INSERT INTO users (name, email) VALUES (?, ?)');
insert.run('John', 'john@example.com');

const users = db.query('SELECT * FROM users').all();
```

## Hono Web Framework

Hono is an ultrafast, edge-first web framework that works with Bun, Deno, Cloudflare Workers, and Node.js.

### Basic Setup
```javascript
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { secureHeaders } from 'hono/secure-headers';

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', secureHeaders());
app.use('/api/*', cors());

// Routes
app.get('/', (c) => c.text('Hello Hono!'));

app.get('/api/users', async (c) => {
  const users = await db.query('SELECT * FROM users').all();
  return c.json(users);
});

app.get('/api/users/:id', async (c) => {
  const id = c.req.param('id');
  const user = await db.query('SELECT * FROM users WHERE id = ?').get(id);
  if (!user) {
    return c.json({ error: 'Not found' }, 404);
  }
  return c.json(user);
});

export default app;
```

### Validation with Valibot
```javascript
import { Hono } from 'hono';
import { vValidator } from '@hono/valibot-validator';
import * as v from 'valibot';

const app = new Hono();

const CreateUserSchema = v.object({
  name: v.pipe(v.string(), v.minLength(2), v.maxLength(100)),
  email: v.pipe(v.string(), v.email()),
});

app.post('/api/users',
  vValidator('json', CreateUserSchema),
  async (c) => {
    const data = c.req.valid('json');
    const result = db.prepare(
      'INSERT INTO users (name, email) VALUES (?, ?) RETURNING *'
    ).get(data.name, data.email);
    return c.json(result, 201);
  }
);
```

### JWT Authentication
```javascript
import { Hono } from 'hono';
import { jwt } from 'hono/jwt';

const app = new Hono();

// Protect routes
app.use('/api/protected/*', jwt({ secret: Bun.env.JWT_SECRET }));

app.get('/api/protected/profile', (c) => {
  const payload = c.get('jwtPayload');
  return c.json({ userId: payload.sub });
});
```

### Error Handling
```javascript
app.onError((err, c) => {
  console.error(err);
  return c.json({ error: err.message }, 500);
});

app.notFound((c) => {
  return c.json({ error: 'Not Found' }, 404);
});
```

## Testing with Bun

Bun has a built-in Jest-compatible test runner.

### Test File
```javascript
// user.test.js
import { describe, it, expect, beforeEach, mock } from 'bun:test';
import { createUser, getUser } from './user.js';

describe('User Service', () => {
  beforeEach(() => {
    // Reset mocks
  });

  it('should create a user', async () => {
    const user = await createUser({ name: 'John', email: 'john@example.com' });
    expect(user).toMatchObject({ name: 'John', email: 'john@example.com' });
    expect(user.id).toBeDefined();
  });

  it('should throw on invalid email', async () => {
    expect(() => createUser({ name: 'John', email: 'invalid' }))
      .toThrow('Invalid email');
  });
});
```

### Running Tests
```bash
# Run all tests
bun test

# Run specific file
bun test user.test.js

# Watch mode
bun test --watch

# Coverage
bun test --coverage
```

## Biome (Linter + Formatter)

### Configuration (biome.json)
```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": { "recommended": true }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "always"
    }
  }
}
```

### Commands
```bash
# Lint
bunx biome lint .

# Format
bunx biome format --write .

# Check all (lint + format)
bunx biome check --write .
```
