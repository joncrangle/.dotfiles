# JavaScript Production-Ready Examples

## Full-Stack Application Setup

### Project Structure

```
my-api/
├── src/
│   ├── index.js              # Application entry point
│   ├── config/
│   │   ├── env.js            # Environment validation
│   │   └── database.js       # Database configuration
│   ├── routes/
│   │   ├── index.js          # Route aggregator
│   │   ├── users.js          # User routes
│   │   └── posts.js          # Post routes
│   ├── middleware/
│   │   ├── auth.js           # Authentication
│   │   └── errorHandler.js   # Error handling
│   ├── services/
│   │   ├── userService.js    # Business logic
│   │   └── postService.js
│   └── db/
│       ├── index.js          # Database connection
│       └── schema.js         # Drizzle schema
├── test/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── drizzle/
│   └── migrations/
├── package.json
├── biome.json
├── drizzle.config.js
├── bunfig.toml
└── Dockerfile
```

### package.json

```json
{
  "name": "my-api",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "bun run --watch src/index.js",
    "start": "bun run src/index.js",
    "test": "bun test",
    "test:watch": "bun test --watch",
    "test:coverage": "bun test --coverage",
    "lint": "bunx biome lint .",
    "format": "bunx biome format --write .",
    "check": "bunx biome check --write .",
    "db:generate": "bunx drizzle-kit generate",
    "db:migrate": "bunx drizzle-kit migrate",
    "db:push": "bunx drizzle-kit push",
    "db:studio": "bunx drizzle-kit studio"
  },
  "dependencies": {
    "hono": "^4.6.0",
    "@hono/valibot-validator": "^0.4.0",
    "valibot": "^1.0.0",
    "drizzle-orm": "^0.38.0"
  },
  "devDependencies": {
    "@types/bun": "^1.1.0",
    "@biomejs/biome": "^1.9.0",
    "drizzle-kit": "^0.30.0"
  }
}
```

### bunfig.toml

```toml
[test]
preload = ["./test/setup.js"]

[test.coverage]
enabled = true
```

---

## Hono Complete API Example

### src/index.js

```javascript
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { secureHeaders } from 'hono/secure-headers';
import { prettyJSON } from 'hono/pretty-json';
import { timing } from 'hono/timing';
import { env } from './config/env.js';
import { userRoutes } from './routes/users.js';
import { postRoutes } from './routes/posts.js';

const app = new Hono();

// Global middleware
app.use('*', logger());
app.use('*', secureHeaders());
app.use('*', timing());
app.use('/api/*', cors({
  origin: env.CORS_ORIGINS,
  credentials: true,
}));
app.use('/api/*', prettyJSON());

// Health check
app.get('/health', (c) => c.json({
  status: 'ok',
  timestamp: new Date().toISOString(),
}));

// API routes
app.route('/api/v1/users', userRoutes);
app.route('/api/v1/posts', postRoutes);

// Error handling
app.onError((err, c) => {
  console.error(err);

  if (err.name === 'ValidationError') {
    return c.json({ error: err.message, details: err.issues }, 400);
  }

  return c.json({
    error: env.NODE_ENV === 'production' ? 'Internal Server Error' : err.message,
  }, 500);
});

app.notFound((c) => c.json({ error: 'Not Found' }, 404));

// Start server
console.log(`Server running on http://localhost:${env.PORT}`);

export default {
  port: env.PORT,
  fetch: app.fetch,
};
```

### src/config/env.js

```javascript
import * as v from 'valibot';

const envSchema = v.object({
  NODE_ENV: v.optional(v.picklist(['development', 'production', 'test']), 'development'),
  PORT: v.optional(v.pipe(v.string(), v.transform(Number)), '3000'),
  DATABASE_URL: v.pipe(v.string(), v.minLength(1)),
  JWT_SECRET: v.pipe(v.string(), v.minLength(32)),
  CORS_ORIGINS: v.optional(v.string(), 'http://localhost:3000'),
});

const result = v.safeParse(envSchema, Bun.env);

if (!result.success) {
  console.error('Invalid environment variables:');
  console.error(result.issues);
  process.exit(1);
}

export const env = {
  ...result.output,
  PORT: Number(result.output.PORT),
  CORS_ORIGINS: result.output.CORS_ORIGINS.split(','),
  isDev: result.output.NODE_ENV === 'development',
  isProd: result.output.NODE_ENV === 'production',
};
```

### src/db/schema.js

```javascript
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  role: text('role', { enum: ['user', 'admin'] }).default('user').notNull(),
  createdAt: integer('created_at', { mode: 'timestamp' }).$defaultFn(() => new Date()),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).$defaultFn(() => new Date()),
});

export const posts = sqliteTable('posts', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  title: text('title').notNull(),
  content: text('content'),
  published: integer('published', { mode: 'boolean' }).default(false).notNull(),
  authorId: integer('author_id').notNull().references(() => users.id),
  createdAt: integer('created_at', { mode: 'timestamp' }).$defaultFn(() => new Date()),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).$defaultFn(() => new Date()),
});
```

### src/db/index.js

```javascript
import { drizzle } from 'drizzle-orm/bun-sqlite';
import { Database } from 'bun:sqlite';
import * as schema from './schema.js';

const sqlite = new Database('app.db');
export const db = drizzle(sqlite, { schema });
```

### src/routes/users.js

```javascript
import { Hono } from 'hono';
import { vValidator } from '@hono/valibot-validator';
import * as v from 'valibot';
import { userService } from '../services/userService.js';
import { authMiddleware } from '../middleware/auth.js';

const app = new Hono();

// Schemas
const CreateUserSchema = v.object({
  name: v.pipe(v.string(), v.minLength(2), v.maxLength(100)),
  email: v.pipe(v.string(), v.email()),
  password: v.pipe(v.string(), v.minLength(8), v.maxLength(100)),
});

const UpdateUserSchema = v.object({
  name: v.optional(v.pipe(v.string(), v.minLength(2), v.maxLength(100))),
  email: v.optional(v.pipe(v.string(), v.email())),
});

const QuerySchema = v.object({
  page: v.optional(v.pipe(v.string(), v.transform(Number)), '1'),
  limit: v.optional(v.pipe(v.string(), v.transform(Number)), '10'),
  search: v.optional(v.string()),
});

// List users
app.get('/', vValidator('query', QuerySchema), async (c) => {
  const query = c.req.valid('query');
  const result = await userService.list(query);
  return c.json(result);
});

// Get user by ID
app.get('/:id', async (c) => {
  const id = Number(c.req.param('id'));
  const user = await userService.getById(id);
  if (!user) {
    return c.json({ error: 'User not found' }, 404);
  }
  return c.json(user);
});

// Create user
app.post('/', vValidator('json', CreateUserSchema), async (c) => {
  const data = c.req.valid('json');
  const user = await userService.create(data);
  return c.json(user, 201);
});

// Update user (protected)
app.put('/:id', authMiddleware, vValidator('json', UpdateUserSchema), async (c) => {
  const id = Number(c.req.param('id'));
  const data = c.req.valid('json');
  const user = await userService.update(id, data);
  return c.json(user);
});

// Delete user (protected)
app.delete('/:id', authMiddleware, async (c) => {
  const id = Number(c.req.param('id'));
  await userService.delete(id);
  return c.body(null, 204);
});

export { app as userRoutes };
```

### src/services/userService.js

```javascript
import { eq, ilike, or, count, desc } from 'drizzle-orm';
import { db } from '../db/index.js';
import { users } from '../db/schema.js';

class UserService {
  async list({ page, limit, search }) {
    const offset = (page - 1) * limit;

    const whereClause = search
      ? or(
          ilike(users.name, `%${search}%`),
          ilike(users.email, `%${search}%`)
        )
      : undefined;

    const [userList, [{ total }]] = await Promise.all([
      db.select({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        createdAt: users.createdAt,
      })
        .from(users)
        .where(whereClause)
        .orderBy(desc(users.createdAt))
        .limit(limit)
        .offset(offset),
      db.select({ total: count() }).from(users).where(whereClause),
    ]);

    return {
      users: userList,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getById(id) {
    const [user] = await db.select({
      id: users.id,
      name: users.name,
      email: users.email,
      role: users.role,
      createdAt: users.createdAt,
    })
      .from(users)
      .where(eq(users.id, id));

    return user || null;
  }

  async create(data) {
    // Check for existing email
    const [existing] = await db.select().from(users).where(eq(users.email, data.email));
    if (existing) {
      throw new Error('Email already exists');
    }

    // Hash password
    const passwordHash = await Bun.password.hash(data.password);

    const [user] = await db.insert(users)
      .values({
        name: data.name,
        email: data.email,
        passwordHash,
      })
      .returning({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        createdAt: users.createdAt,
      });

    return user;
  }

  async update(id, data) {
    const [existing] = await db.select().from(users).where(eq(users.id, id));
    if (!existing) {
      throw new Error('User not found');
    }

    if (data.email && data.email !== existing.email) {
      const [emailExists] = await db.select().from(users).where(eq(users.email, data.email));
      if (emailExists) {
        throw new Error('Email already exists');
      }
    }

    const [user] = await db.update(users)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(users.id, id))
      .returning({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        createdAt: users.createdAt,
      });

    return user;
  }

  async delete(id) {
    const [existing] = await db.select().from(users).where(eq(users.id, id));
    if (!existing) {
      throw new Error('User not found');
    }
    await db.delete(users).where(eq(users.id, id));
  }

  async authenticate(email, password) {
    const [user] = await db.select().from(users).where(eq(users.email, email));
    if (!user) {
      return null;
    }

    const valid = await Bun.password.verify(password, user.passwordHash);
    if (!valid) {
      return null;
    }

    return user;
  }
}

export const userService = new UserService();
```

### src/middleware/auth.js

```javascript
import { jwt } from 'hono/jwt';
import { env } from '../config/env.js';

export const authMiddleware = jwt({ secret: env.JWT_SECRET });

// Helper to get current user from context
export function getCurrentUser(c) {
  return c.get('jwtPayload');
}
```

---

## Testing Examples

### test/setup.js

```javascript
import { beforeAll, afterAll, afterEach, mock } from 'bun:test';
import { Database } from 'bun:sqlite';

// Use in-memory database for tests
const testDb = new Database(':memory:');

beforeAll(async () => {
  // Run migrations or create tables
  testDb.run(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT DEFAULT 'user',
      created_at INTEGER,
      updated_at INTEGER
    )
  `);
});

afterAll(async () => {
  testDb.close();
});

afterEach(() => {
  // Clear tables between tests
  testDb.run('DELETE FROM users');
});
```

### test/unit/userService.test.js

```javascript
import { describe, it, expect, beforeEach, mock, spyOn } from 'bun:test';
import { userService } from '../../src/services/userService.js';

describe('UserService', () => {
  const mockUser = {
    id: 1,
    name: 'John Doe',
    email: 'john@example.com',
    role: 'user',
    createdAt: new Date(),
  };

  describe('list', () => {
    it('returns paginated users', async () => {
      const result = await userService.list({ page: 1, limit: 10 });

      expect(result.users).toBeDefined();
      expect(result.pagination).toMatchObject({
        page: 1,
        limit: 10,
      });
    });

    it('calculates offset correctly', async () => {
      const result = await userService.list({ page: 3, limit: 20 });

      expect(result.pagination.page).toBe(3);
    });
  });

  describe('create', () => {
    it('creates user with hashed password', async () => {
      const result = await userService.create({
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
      });

      expect(result.name).toBe('John Doe');
      expect(result.email).toBe('john@example.com');
      expect(result.id).toBeDefined();
    });

    it('throws on duplicate email', async () => {
      await userService.create({
        name: 'John',
        email: 'duplicate@example.com',
        password: 'password',
      });

      expect(() =>
        userService.create({
          name: 'Jane',
          email: 'duplicate@example.com',
          password: 'password',
        })
      ).toThrow('Email already exists');
    });
  });
});
```

### test/integration/users.test.js

```javascript
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'bun:test';
import app from '../../src/index.js';

describe('Users API', () => {
  beforeEach(async () => {
    // Clean up database
  });

  describe('POST /api/v1/users', () => {
    it('creates a new user', async () => {
      const response = await app.fetch(
        new Request('http://localhost/api/v1/users', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: 'John Doe',
            email: 'john@example.com',
            password: 'password123',
          }),
        })
      );

      expect(response.status).toBe(201);
      const body = await response.json();
      expect(body).toMatchObject({
        name: 'John Doe',
        email: 'john@example.com',
      });
      expect(body.id).toBeDefined();
    });

    it('returns 400 for invalid email', async () => {
      const response = await app.fetch(
        new Request('http://localhost/api/v1/users', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: 'John Doe',
            email: 'invalid-email',
            password: 'password123',
          }),
        })
      );

      expect(response.status).toBe(400);
    });
  });

  describe('GET /api/v1/users', () => {
    it('returns paginated users', async () => {
      const response = await app.fetch(
        new Request('http://localhost/api/v1/users?page=1&limit=10')
      );

      expect(response.status).toBe(200);
      const body = await response.json();
      expect(body.users).toBeDefined();
      expect(body.pagination).toBeDefined();
    });
  });
});
```

---

## Biome Configuration

### biome.json

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "correctness": {
        "noUnusedVariables": "error",
        "noUnusedImports": "error"
      },
      "style": {
        "useConst": "error",
        "noVar": "error"
      },
      "suspicious": {
        "noExplicitAny": "warn"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "always"
    }
  },
  "files": {
    "ignore": ["node_modules", "dist", "coverage", ".output"]
  }
}
```

---

## Drizzle Configuration

### drizzle.config.js

```javascript
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema.js',
  out: './drizzle/migrations',
  dialect: 'sqlite',
  dbCredentials: {
    url: './app.db',
  },
});
```

---

## Dockerfile

```dockerfile
# Build stage
FROM oven/bun:1 AS builder
WORKDIR /app
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile --production

# Production stage
FROM oven/bun:1-slim
WORKDIR /app

# Security: run as non-root user
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 appuser

COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["bun", "run", "src/index.js"]
```

---

## Environment Configuration

### .env.example

```env
# Server
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=./app.db

# Auth
JWT_SECRET=your-secret-key-at-least-32-characters-long

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
```

---

Last Updated: 2025-12-30
Version: 1.1.0
