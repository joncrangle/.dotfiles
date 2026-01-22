---
name: hono
description: Specialist in Hono (v4+), an ultrafast web framework for Edge (Cloudflare, Bun, Deno) and Node. Focuses on type-safe RPC, middleware, and Web Standards.
---
<skill_doc>
<trigger_keywords>
## Trigger Keywords

Activate this skill when the user mentions any of:

**Core**: Hono, c (Context), app.get, app.post, app.use, hono/jsx

**RPC / Types**: zValidator, hono/client, hc, AppType, client.index.$get

**Environments**: Cloudflare Workers, Bun, Deno, Edge, c.env, Bindings

**Testing**: app.request, testClient
</trigger_keywords>

## ⛔ Forbidden Patterns

1.  **NO Node.js Specifics on Edge**: Avoid `fs`, `path`, or `process` when targeting Cloudflare/Deno.
2.  **NO Untyped Validators**: Don't use `c.req.json()` raw if you have `zValidator`. Use `c.req.valid('json')`.
3.  **NO Controller Classes**: Avoid OOP-style controller classes. They break Hono RPC type inference. Use inline handlers or `factory.createHandlers`.
4.  **NO `res.send`**: This is not Express. Return `c.json()`, `c.text()`, or a `Response` object.
5.  **NO Global State**: In serverless/edge, global variables may not persist. Use `c.set/c.get` for request-scoped state or `c.env` for config.

## 🤖 Agent Tool Strategy

1.  **Runtime Check**: Identify the target runtime (Cloudflare, Bun, Node) to recommend correct bindings and adapters.
2.  **RPC First**: Suggest Hono RPC (`client`) for frontend-backend communication to share types automatically.
3.  **Validation**: Always pair inputs with `@hono/zod-validator` for runtime safety and type inference.
4.  **Testing**: Prefer `app.request()` for fast integration tests over spinning up a localhost server.

## Quick Reference (30 seconds)

Hono Specialist - Ultrafast, Standards-based, Multi-runtime.

**Core Philosophy**:
- **Web Standards**: Built on `Request` and `Response`.
- **RegExpRouter**: Extremely fast routing engine.
- **Type-Safe RPC**: Share `AppType` with client for autocompletion.

**Context (`c`)**:
- `c.req`: Request object.
- `c.env`: Environment variables/bindings.
- `c.json()`: Send JSON response.
- `c.var`: Request-scoped variables (middleware).

---

## Resources

- **Examples**: See `examples/examples.md` for detailed code patterns.
- **References**: See `references/reference.md` for official documentation links.
</skill_doc>
