# Framework Comparison and Migration Overview

Overview of migrating to ElysiaJS from other web frameworks. Elysia is designed to feel familiar to developers coming from Express, Fastify, Hono, or tRPC while offering end-to-end type safety, high performance on Bun, and an ergonomic API.

Source: https://elysiajs.com/migrate

## Why Elysia

- **End-to-End Type Safety** -- Full type inference from server routes to client (via Eden Treaty), eliminating manual type definitions
- **Bun Runtime** -- Built natively for Bun, leveraging its performance advantages over Node.js
- **Ergonomic API** -- Declarative route definitions with inline validation, lifecycle hooks, and plugin composition
- **Unified Validation** -- Built-in schema validation using TypeBox (`t`), with automatic OpenAPI documentation generation
- **Plugin Ecosystem** -- Official plugins for JWT, CORS, OpenAPI, GraphQL, static files, and more

## Migration Guides

Detailed migration guides are available for each framework:

### From Express

Express developers will find Elysia's routing and middleware patterns familiar, with key differences in how middleware chains, validation, and context work.

See: `migrations/from-express.md`

### From Fastify

Fastify users will recognize Elysia's plugin system and schema-based validation approach. Key differences include Elysia's type inference and lifecycle hook model.

See: `migrations/from-fastify.md`

### From Hono

Hono developers transitioning to Elysia will find a similar lightweight philosophy. Key differences are in the type system integration and runtime target.

See: `migrations/from-hono.md`

### From tRPC

tRPC users will appreciate Elysia's end-to-end type safety via Eden Treaty. Unlike tRPC's procedure-based approach, Elysia uses standard HTTP routes with full type inference.

See: `migrations/from-trpc.md`

## Quick Comparison Table

| Feature | Express | Fastify | Hono | tRPC | Elysia |
|---------|---------|---------|------|------|--------|
| Runtime | Node.js | Node.js | Multi | Node.js | Bun |
| Type Safety | Manual | Plugin | Partial | Full | Full |
| Validation | External | Schema | Zod | Zod | TypeBox (built-in) |
| API Docs | External | Plugin | External | N/A | Built-in (OpenAPI) |
| E2E Client | No | No | No | Yes | Yes (Eden) |
| Plugin System | Middleware | Plugins | Middleware | Middleware | Plugins |

## Common Migration Patterns

### Route Definitions

```typescript
// Express
app.get('/user/:id', (req, res) => {
    res.json({ id: req.params.id })
})

// Elysia
app.get('/user/:id', ({ params: { id } }) => ({ id }))
```

### Validation

```typescript
// Express (with external library)
app.post('/user', validate(schema), (req, res) => {
    res.json(req.body)
})

// Elysia (built-in)
app.post('/user', ({ body }) => body, {
    body: t.Object({
        name: t.String(),
        email: t.String({ format: 'email' })
    })
})
```

### Middleware / Lifecycle

```typescript
// Express
app.use((req, res, next) => {
    console.log('Request received')
    next()
})

// Elysia
app.onRequest(() => {
    console.log('Request received')
})
```

See also:
- `references/cheat-sheet.md` -- Quick reference for all core Elysia APIs
- `references/lifecycle.md` -- Full lifecycle hook documentation
- `references/plugin.md` -- Plugin system overview
