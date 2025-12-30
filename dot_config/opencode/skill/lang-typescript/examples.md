# TypeScript Production-Ready Examples

## Full-Stack Application Setup

### TanStack Start + SolidJS + Drizzle

```
my-app/
├── app/
│   ├── components/
│   │   ├── ui/
│   │   └── features/
│   ├── routes/
│   │   ├── __root.tsx
│   │   ├── index.tsx
│   │   ├── (auth)/
│   │   │   ├── login.tsx
│   │   │   └── register.tsx
│   │   ├── dashboard/
│   │   │   └── index.tsx
│   │   ├── posts/
│   │   │   ├── index.tsx
│   │   │   └── $id.tsx
│   │   └── api/
│   │       └── auth.ts
│   ├── server/
│   │   ├── functions/
│   │   │   ├── user.ts
│   │   │   └── post.ts
│   │   ├── middleware/
│   │   │   └── auth.ts
│   │   └── db/
│   │       ├── index.ts
│   │       └── schema.ts
│   ├── lib/
│   │   ├── schemas.ts
│   │   └── auth.ts
│   ├── client.tsx
│   ├── router.tsx
│   └── ssr.tsx
├── drizzle/
│   └── migrations/
├── drizzle.config.ts
├── app.config.ts
├── package.json
└── tsconfig.json
```

### package.json

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "bunx vinxi dev",
    "build": "bunx vinxi build",
    "start": "bun run .output/server/index.mjs",
    "lint": "bunx biome lint .",
    "test": "bun test",
    "test:e2e": "bunx playwright test",
    "db:generate": "bunx drizzle-kit generate",
    "db:migrate": "bunx drizzle-kit migrate",
    "db:push": "bunx drizzle-kit push",
    "db:studio": "bunx drizzle-kit studio",
    "typecheck": "bunx tsc --noEmit"
  },
  "dependencies": {
    "@tanstack/solid-router": "^1.0.0",
    "@tanstack/start": "^1.0.0",
    "@tanstack/valibot-adapter": "^1.0.0",
    "solid-js": "^1.9.0",
    "drizzle-orm": "^0.38.0",
    "valibot": "^1.0.0",
    "vinxi": "^0.5.0"
  },
  "devDependencies": {
    "@types/bun": "^1.1.0",
    "typescript": "^5.9.0",
    "drizzle-kit": "^0.30.0",
    "@solidjs/testing-library": "^0.8.0",
    "@playwright/test": "^1.48.0",
    "@biomejs/biome": "^1.9.0"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "ES2022"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "jsxImportSource": "solid-js",
    "incremental": true,
    "paths": {
      "~/*": ["./app/*"]
    }
  },
  "include": ["**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
```

### app.config.ts

```typescript
import { defineConfig } from "@tanstack/start/config";

export default defineConfig({
  server: {
    preset: "bun", // or 'node-server', 'vercel', 'netlify', 'cloudflare-pages'
  },
  vite: {
    ssr: {
      noExternal: ["@kobalte/core"],
    },
  },
});
```

---

## Database Layer (Drizzle)

### drizzle.config.ts

```typescript
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./app/server/db/schema.ts",
  out: "./drizzle/migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
```

### app/server/db/schema.ts

```typescript
import { pgTable, text, timestamp, boolean, pgEnum } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

// Enums
export const roleEnum = pgEnum("role", ["USER", "ADMIN"]);

// Users table
export const users = pgTable("users", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  email: text("email").notNull().unique(),
  name: text("name"),
  passwordHash: text("password_hash"),
  role: roleEnum("role").default("USER").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

// Posts table
export const posts = pgTable("posts", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  title: text("title").notNull(),
  content: text("content"),
  published: boolean("published").default(false).notNull(),
  authorId: text("author_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

// Tags table
export const tags = pgTable("tags", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  name: text("name").notNull().unique(),
});

// Posts to Tags junction table
export const postsToTags = pgTable("posts_to_tags", {
  postId: text("post_id").notNull().references(() => posts.id, { onDelete: "cascade" }),
  tagId: text("tag_id").notNull().references(() => tags.id, { onDelete: "cascade" }),
});

// Sessions table
export const sessions = pgTable("sessions", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  expiresAt: timestamp("expires_at").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// Relations
export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
  sessions: many(sessions),
}));

export const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id],
  }),
  postsToTags: many(postsToTags),
}));

export const tagsRelations = relations(tags, ({ many }) => ({
  postsToTags: many(postsToTags),
}));

export const postsToTagsRelations = relations(postsToTags, ({ one }) => ({
  post: one(posts, {
    fields: [postsToTags.postId],
    references: [posts.id],
  }),
  tag: one(tags, {
    fields: [postsToTags.tagId],
    references: [tags.id],
  }),
}));

// Type exports
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Post = typeof posts.$inferSelect;
export type NewPost = typeof posts.$inferInsert;
export type Tag = typeof tags.$inferSelect;
```

### app/server/db/index.ts

```typescript
import { drizzle } from "drizzle-orm/bun-sql";
import { Database } from "bun:sqlite";
import * as schema from "./schema";

// For PostgreSQL with Bun, use:
// import { drizzle } from "drizzle-orm/node-postgres";
// import { Pool } from "pg";
// const pool = new Pool({ connectionString: process.env.DATABASE_URL });
// export const db = drizzle(pool, { schema });

// SQLite example (simpler for development)
const sqlite = new Database("sqlite.db");
export const db = drizzle(sqlite, { schema });
```

---

## Validation Schemas

### app/lib/schemas.ts

```typescript
import * as v from "valibot";

// User schemas
export const UserSchema = v.object({
  id: v.string(),
  email: v.pipe(v.string(), v.email()),
  name: v.nullable(v.string()),
  role: v.picklist(["USER", "ADMIN"]),
  createdAt: v.date(),
});

export type User = v.InferOutput<typeof UserSchema>;

export const CreateUserSchema = v.object({
  email: v.pipe(v.string(), v.email()),
  name: v.pipe(v.string(), v.minLength(2), v.maxLength(100)),
  password: v.pipe(v.string(), v.minLength(8)),
});

export const UpdateUserSchema = v.object({
  name: v.optional(v.pipe(v.string(), v.minLength(2), v.maxLength(100))),
  email: v.optional(v.pipe(v.string(), v.email())),
});

// Post schemas
export const CreatePostSchema = v.object({
  title: v.pipe(v.string(), v.minLength(1), v.maxLength(200)),
  content: v.optional(v.string()),
  tags: v.optional(v.array(v.string())),
});

export const UpdatePostSchema = v.object({
  id: v.string(),
  title: v.optional(v.pipe(v.string(), v.minLength(1), v.maxLength(200))),
  content: v.optional(v.string()),
  published: v.optional(v.boolean()),
  tags: v.optional(v.array(v.string())),
});

// Pagination schema
export const PaginationSchema = v.object({
  page: v.optional(v.pipe(v.number(), v.minValue(1)), 1),
  limit: v.optional(v.pipe(v.number(), v.minValue(1), v.maxValue(100)), 10),
});

// Login schema
export const LoginSchema = v.object({
  email: v.pipe(v.string(), v.email()),
  password: v.pipe(v.string(), v.minLength(1)),
});
```

---

## Server Functions

### app/server/middleware/auth.ts

```typescript
import { createMiddleware } from "@tanstack/start";
import { getSession } from "~/lib/auth";

export const authMiddleware = createMiddleware().server(async ({ next }) => {
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

export const adminMiddleware = createMiddleware()
  .middleware([authMiddleware])
  .server(async ({ next, context }) => {
    if (context.role !== "ADMIN") {
      throw new Error("Forbidden");
    }
    return next();
  });
```

### app/server/functions/user.ts

```typescript
import { createServerFn } from "@tanstack/start";
import { valibotValidator } from "@tanstack/valibot-adapter";
import * as v from "valibot";
import { eq, ilike, or, count, desc } from "drizzle-orm";
import { db } from "../db";
import { users } from "../db/schema";
import { authMiddleware, adminMiddleware } from "../middleware/auth";
import { UpdateUserSchema, PaginationSchema } from "~/lib/schemas";

// Public: Get user by ID
export const getUserById = createServerFn({ method: "GET" })
  .validator(valibotValidator(v.object({ id: v.string() })))
  .handler(async ({ data }) => {
    const user = await db.query.users.findFirst({
      where: eq(users.id, data.id),
      columns: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
      },
    });

    if (!user) {
      throw new Error("User not found");
    }

    return user;
  });

// Protected: Get current user profile
export const getMe = createServerFn({ method: "GET" })
  .middleware([authMiddleware])
  .handler(async ({ context }) => {
    const user = await db.query.users.findFirst({
      where: eq(users.id, context.userId),
      columns: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
      },
      with: {
        posts: true,
      },
    });

    return {
      ...user,
      _count: { posts: user?.posts.length ?? 0 },
    };
  });

// Protected: Update current user
export const updateMe = createServerFn({ method: "POST" })
  .middleware([authMiddleware])
  .validator(valibotValidator(UpdateUserSchema))
  .handler(async ({ data, context }) => {
    const [updated] = await db
      .update(users)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(users.id, context.userId))
      .returning();

    return updated;
  });

// Admin: List all users with pagination
export const listUsers = createServerFn({ method: "GET" })
  .middleware([adminMiddleware])
  .validator(
    valibotValidator(
      v.object({
        ...PaginationSchema.entries,
        search: v.optional(v.string()),
      })
    )
  )
  .handler(async ({ data }) => {
    const { page = 1, limit = 10, search } = data;
    const offset = (page - 1) * limit;

    const whereClause = search
      ? or(
          ilike(users.name, `%${search}%`),
          ilike(users.email, `%${search}%`)
        )
      : undefined;

    const [userList, [{ total }]] = await Promise.all([
      db.query.users.findMany({
        where: whereClause,
        offset,
        limit,
        orderBy: desc(users.createdAt),
        columns: {
          id: true,
          email: true,
          name: true,
          role: true,
          createdAt: true,
        },
      }),
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
  });

// Admin: Delete user
export const deleteUser = createServerFn({ method: "POST" })
  .middleware([adminMiddleware])
  .validator(valibotValidator(v.object({ id: v.string() })))
  .handler(async ({ data, context }) => {
    if (data.id === context.userId) {
      throw new Error("Cannot delete your own account");
    }

    const [deleted] = await db
      .delete(users)
      .where(eq(users.id, data.id))
      .returning();

    return deleted;
  });
```

### app/server/functions/post.ts

```typescript
import { createServerFn } from "@tanstack/start";
import { valibotValidator } from "@tanstack/valibot-adapter";
import * as v from "valibot";
import { eq, and, desc, count } from "drizzle-orm";
import { db } from "../db";
import { posts, tags, postsToTags } from "../db/schema";
import { authMiddleware } from "../middleware/auth";
import { CreatePostSchema, UpdatePostSchema, PaginationSchema } from "~/lib/schemas";

// Public: List published posts
export const listPosts = createServerFn({ method: "GET" })
  .validator(
    valibotValidator(
      v.object({
        ...PaginationSchema.entries,
        tag: v.optional(v.string()),
      })
    )
  )
  .handler(async ({ data }) => {
    const { page = 1, limit = 10, tag } = data;
    const offset = (page - 1) * limit;

    const postList = await db.query.posts.findMany({
      where: eq(posts.published, true),
      offset,
      limit,
      orderBy: desc(posts.createdAt),
      with: {
        author: {
          columns: { id: true, name: true },
        },
        postsToTags: {
          with: {
            tag: true,
          },
        },
      },
    });

    const [{ total }] = await db
      .select({ total: count() })
      .from(posts)
      .where(eq(posts.published, true));

    // Transform to flatten tags
    const transformed = postList.map((post) => ({
      ...post,
      tags: post.postsToTags.map((pt) => pt.tag),
    }));

    return { posts: transformed, total, page, totalPages: Math.ceil(total / limit) };
  });

// Public: Get single post
export const getPostById = createServerFn({ method: "GET" })
  .validator(valibotValidator(v.object({ id: v.string() })))
  .handler(async ({ data }) => {
    const post = await db.query.posts.findFirst({
      where: and(eq(posts.id, data.id), eq(posts.published, true)),
      with: {
        author: {
          columns: { id: true, name: true },
        },
        postsToTags: {
          with: {
            tag: true,
          },
        },
      },
    });

    if (!post) {
      throw new Error("Post not found");
    }

    return {
      ...post,
      tags: post.postsToTags.map((pt) => pt.tag),
    };
  });

// Protected: Create post
export const createPost = createServerFn({ method: "POST" })
  .middleware([authMiddleware])
  .validator(valibotValidator(CreatePostSchema))
  .handler(async ({ data, context }) => {
    const { tags: tagNames, ...postData } = data;

    // Create post
    const [newPost] = await db
      .insert(posts)
      .values({
        ...postData,
        authorId: context.userId,
      })
      .returning();

    // Handle tags
    if (tagNames?.length) {
      for (const name of tagNames) {
        // Upsert tag
        let tag = await db.query.tags.findFirst({
          where: eq(tags.name, name),
        });

        if (!tag) {
          [tag] = await db.insert(tags).values({ name }).returning();
        }

        // Link post to tag
        await db.insert(postsToTags).values({
          postId: newPost.id,
          tagId: tag.id,
        });
      }
    }

    return newPost;
  });

// Protected: Update own post
export const updatePost = createServerFn({ method: "POST" })
  .middleware([authMiddleware])
  .validator(valibotValidator(UpdatePostSchema))
  .handler(async ({ data, context }) => {
    const { id, tags: tagNames, ...updateData } = data;

    const post = await db.query.posts.findFirst({
      where: eq(posts.id, id),
    });

    if (!post) {
      throw new Error("Post not found");
    }

    if (post.authorId !== context.userId) {
      throw new Error("Forbidden");
    }

    // Update post
    const [updated] = await db
      .update(posts)
      .set({ ...updateData, updatedAt: new Date() })
      .where(eq(posts.id, id))
      .returning();

    // Update tags if provided
    if (tagNames !== undefined) {
      // Remove existing tags
      await db.delete(postsToTags).where(eq(postsToTags.postId, id));

      // Add new tags
      if (tagNames.length) {
        for (const name of tagNames) {
          let tag = await db.query.tags.findFirst({
            where: eq(tags.name, name),
          });

          if (!tag) {
            [tag] = await db.insert(tags).values({ name }).returning();
          }

          await db.insert(postsToTags).values({
            postId: id,
            tagId: tag.id,
          });
        }
      }
    }

    return updated;
  });

// Protected: Delete own post
export const deletePost = createServerFn({ method: "POST" })
  .middleware([authMiddleware])
  .validator(valibotValidator(v.object({ id: v.string() })))
  .handler(async ({ data, context }) => {
    const post = await db.query.posts.findFirst({
      where: eq(posts.id, data.id),
    });

    if (!post) {
      throw new Error("Post not found");
    }

    if (post.authorId !== context.userId) {
      throw new Error("Forbidden");
    }

    const [deleted] = await db
      .delete(posts)
      .where(eq(posts.id, data.id))
      .returning();

    return deleted;
  });

// Protected: Get user's drafts
export const getMyDrafts = createServerFn({ method: "GET" })
  .middleware([authMiddleware])
  .handler(async ({ context }) => {
    const drafts = await db.query.posts.findMany({
      where: and(
        eq(posts.authorId, context.userId),
        eq(posts.published, false)
      ),
      orderBy: desc(posts.updatedAt),
      with: {
        postsToTags: {
          with: {
            tag: true,
          },
        },
      },
    });

    return drafts.map((post) => ({
      ...post,
      tags: post.postsToTags.map((pt) => pt.tag),
    }));
  });
```

---

## Routes

### app/routes/__root.tsx

```typescript
import { createRootRoute, Outlet } from "@tanstack/solid-router";
import { Component, Suspense } from "solid-js";

const RootLayout: Component = () => {
  return (
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>My App</title>
      </head>
      <body>
        <Suspense fallback={<div>Loading...</div>}>
          <Outlet />
        </Suspense>
      </body>
    </html>
  );
};

export const Route = createRootRoute({
  component: RootLayout,
});
```

### app/routes/index.tsx

```typescript
import { createFileRoute } from "@tanstack/solid-router";
import { Component } from "solid-js";

const HomePage: Component = () => {
  return (
    <main>
      <h1>Welcome to My App</h1>
      <p>Built with TanStack Start, SolidJS, and Valibot</p>
    </main>
  );
};

export const Route = createFileRoute("/")({
  component: HomePage,
});
```

### app/routes/posts/index.tsx

```typescript
import { createFileRoute } from "@tanstack/solid-router";
import { Component, For, Show, createSignal } from "solid-js";
import { listPosts } from "~/server/functions/post";

export const Route = createFileRoute("/posts/")({
  loader: () => listPosts({ data: { page: 1, limit: 10 } }),
  component: PostListPage,
});

function PostListPage() {
  const data = Route.useLoaderData();
  const [page, setPage] = createSignal(1);

  return (
    <main>
      <h1>Posts</h1>

      <div class="posts-grid">
        <For each={data().posts}>
          {(post) => <PostCard post={post} />}
        </For>
      </div>

      <Show when={data().totalPages > 1}>
        <Pagination
          currentPage={page()}
          totalPages={data().totalPages}
          onPageChange={setPage}
        />
      </Show>
    </main>
  );
}

interface Post {
  id: string;
  title: string;
  content: string | null;
  author: { id: string; name: string | null };
  tags: { name: string }[];
}

const PostCard: Component<{ post: Post }> = (props) => {
  return (
    <article class="post-card">
      <h2>
        <a href={`/posts/${props.post.id}`}>{props.post.title}</a>
      </h2>
      <Show when={props.post.content}>
        <p class="post-excerpt">{props.post.content?.slice(0, 150)}...</p>
      </Show>
      <div class="post-meta">
        <span>By {props.post.author.name}</span>
        <div class="tags">
          <For each={props.post.tags}>
            {(tag) => <span class="tag">{tag.name}</span>}
          </For>
        </div>
      </div>
    </article>
  );
};

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

const Pagination: Component<PaginationProps> = (props) => {
  return (
    <nav class="pagination">
      <button
        disabled={props.currentPage <= 1}
        onClick={() => props.onPageChange(props.currentPage - 1)}
      >
        Previous
      </button>
      <span>
        Page {props.currentPage} of {props.totalPages}
      </span>
      <button
        disabled={props.currentPage >= props.totalPages}
        onClick={() => props.onPageChange(props.currentPage + 1)}
      >
        Next
      </button>
    </nav>
  );
};
```

### app/routes/posts/$id.tsx

```typescript
import { createFileRoute, useNavigate } from "@tanstack/solid-router";
import { Component, Show } from "solid-js";
import { getPostById } from "~/server/functions/post";

export const Route = createFileRoute("/posts/$id")({
  loader: ({ params }) => getPostById({ data: { id: params.id } }),
  component: PostDetailPage,
});

function PostDetailPage() {
  const post = Route.useLoaderData();
  const navigate = useNavigate();

  return (
    <main>
      <button onClick={() => navigate({ to: "/posts" })}>← Back to Posts</button>

      <article>
        <h1>{post().title}</h1>
        <div class="post-meta">
          <span>By {post().author.name}</span>
        </div>

        <Show when={post().content}>
          <div class="post-content">{post().content}</div>
        </Show>

        <Show when={post().tags.length > 0}>
          <div class="tags">
            <For each={post().tags}>
              {(tag) => <span class="tag">{tag.name}</span>}
            </For>
          </div>
        </Show>
      </article>
    </main>
  );
}
```

---

## SolidJS Components

### app/components/features/CreatePostForm.tsx

```typescript
import { Component, createSignal, Show } from "solid-js";
import { useNavigate } from "@tanstack/solid-router";
import { createPost } from "~/server/functions/post";
import * as v from "valibot";
import { CreatePostSchema } from "~/lib/schemas";

export const CreatePostForm: Component = () => {
  const navigate = useNavigate();
  const [title, setTitle] = createSignal("");
  const [content, setContent] = createSignal("");
  const [tags, setTags] = createSignal("");
  const [error, setError] = createSignal<string | null>(null);
  const [isSubmitting, setIsSubmitting] = createSignal(false);

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      const tagList = tags()
        .split(",")
        .map((t) => t.trim())
        .filter(Boolean);

      const data = {
        title: title(),
        content: content() || undefined,
        tags: tagList.length > 0 ? tagList : undefined,
      };

      // Validate on client first
      const result = v.safeParse(CreatePostSchema, data);
      if (!result.success) {
        setError(result.issues[0].message);
        return;
      }

      const post = await createPost({ data: result.output });
      navigate({ to: "/posts/$id", params: { id: post.id } });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create post");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} class="create-post-form">
      <div class="form-field">
        <label for="title">Title</label>
        <input
          id="title"
          type="text"
          value={title()}
          onInput={(e) => setTitle(e.currentTarget.value)}
          disabled={isSubmitting()}
          required
        />
      </div>

      <div class="form-field">
        <label for="content">Content</label>
        <textarea
          id="content"
          value={content()}
          onInput={(e) => setContent(e.currentTarget.value)}
          rows={10}
          disabled={isSubmitting()}
        />
      </div>

      <div class="form-field">
        <label for="tags">Tags (comma-separated)</label>
        <input
          id="tags"
          type="text"
          value={tags()}
          onInput={(e) => setTags(e.currentTarget.value)}
          placeholder="solid, typescript, tanstack"
          disabled={isSubmitting()}
        />
      </div>

      <Show when={error()}>
        <p class="error">{error()}</p>
      </Show>

      <button type="submit" disabled={isSubmitting()}>
        {isSubmitting() ? "Creating..." : "Create Post"}
      </button>
    </form>
  );
};
```

---

## Testing Examples

### bunfig.toml

```toml
[test]
preload = ["./app/test/setup.ts"]

[test.coverage]
enabled = true
```

### app/test/setup.ts

```typescript
import { afterEach, mock } from "bun:test";
import { cleanup } from "@solidjs/testing-library";

afterEach(() => {
  cleanup();
});

// Mock TanStack Router
mock.module("@tanstack/solid-router", () => ({
  useNavigate: () => mock(() => {}),
  createFileRoute: mock(() => {}),
  Link: (props: any) => <a href={props.to}>{props.children}</a>,
}));
```

### app/components/features/__tests__/PostCard.test.tsx

```typescript
import { describe, it, expect } from "bun:test";
import { render, screen } from "@solidjs/testing-library";
import { PostCard } from "../PostCard";

const mockPost = {
  id: "1",
  title: "Test Post",
  content: "This is test content",
  published: true,
  author: { id: "1", name: "John Doe" },
  tags: [{ name: "solid" }, { name: "typescript" }],
  createdAt: new Date(),
};

describe("PostCard", () => {
  it("renders post title and content", () => {
    render(() => <PostCard post={mockPost} />);

    expect(screen.getByText("Test Post")).toBeDefined();
    expect(screen.getByText(/This is test content/)).toBeDefined();
  });

  it("displays author name", () => {
    render(() => <PostCard post={mockPost} />);

    expect(screen.getByText(/John Doe/)).toBeDefined();
  });

  it("renders all tags", () => {
    render(() => <PostCard post={mockPost} />);

    expect(screen.getByText("solid")).toBeDefined();
    expect(screen.getByText("typescript")).toBeDefined();
  });

  it("links to post detail page", () => {
    render(() => <PostCard post={mockPost} />);

    const link = screen.getByRole("link", { name: /Test Post/i });
    expect(link.getAttribute("href")).toBe("/posts/1");
  });
});
```

### E2E Test: playwright/posts.spec.ts

```typescript
import { test, expect } from "@playwright/test";

test.describe("Posts", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/posts");
  });

  test("should display list of posts", async ({ page }) => {
    await expect(page.getByRole("article")).toHaveCount.above(0);
  });

  test("should navigate to post detail", async ({ page }) => {
    const firstPost = page.getByRole("article").first();
    const title = await firstPost.getByRole("heading").textContent();

    await firstPost.getByRole("link").click();

    await expect(page).toHaveURL(/\/posts\/.+/);
    await expect(page.getByRole("heading", { level: 1 })).toHaveText(title!);
  });

  test("should filter posts by tag", async ({ page }) => {
    await page.getByRole("button", { name: "solid" }).click();

    const posts = page.getByRole("article");
    for (const post of await posts.all()) {
      await expect(post.getByText("solid")).toBeVisible();
    }
  });
});

test.describe("Authenticated User", () => {
  test.use({ storageState: "playwright/.auth/user.json" });

  test("should create new post", async ({ page }) => {
    await page.goto("/posts/new");

    await page.getByLabel("Title").fill("My New Post");
    await page.getByLabel("Content").fill("This is my new post content.");
    await page.getByLabel("Tags").fill("test, e2e");

    await page.getByRole("button", { name: "Create Post" }).click();

    await expect(page).toHaveURL(/\/posts\/.+/);
    await expect(page.getByRole("heading", { level: 1 })).toHaveText("My New Post");
  });
});
```

---

## Environment Configuration

### .env.example

```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/myapp?schema=public"

# Auth
AUTH_SECRET="your-secret-key-min-32-chars"

# App
PUBLIC_APP_URL="http://localhost:3000"
```

### app/lib/env.ts

```typescript
import * as v from "valibot";

const envSchema = v.object({
  DATABASE_URL: v.pipe(v.string(), v.url()),
  AUTH_SECRET: v.pipe(v.string(), v.minLength(32)),
  NODE_ENV: v.optional(v.picklist(["development", "production", "test"]), "development"),
  PUBLIC_APP_URL: v.optional(v.pipe(v.string(), v.url())),
});

const result = v.safeParse(envSchema, process.env);

if (!result.success) {
  console.error("Invalid environment variables:", JSON.stringify(result.issues, null, 2));
  throw new Error("Invalid environment variables");
}

export const env = result.output;
```

---

Version: 1.1.0
Last Updated: 2025-12-30
