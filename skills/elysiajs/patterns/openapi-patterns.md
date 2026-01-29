# OpenAPI Patterns
Pattern-level guide for OpenAPI usage in ElysiaJS. Covers route documentation, tagging, models, and schema generation. See also `plugins/openapi.md` for the plugin API reference.

## Setup

Install and register the plugin:

```bash
bun add @elysiajs/openapi
```

```typescript
import { Elysia } from 'elysia'
import { openapi } from '@elysiajs/openapi'

new Elysia()
    .use(openapi())
```

Access `/openapi` to view generated Scalar UI documentation.

## Generating from Types

Use `fromTypes` to generate documentation directly from TypeScript types:

```typescript
import { Elysia, t } from 'elysia'
import { openapi, fromTypes } from '@elysiajs/openapi'

export const app = new Elysia()
    .use(
        openapi({
            references: fromTypes()
        })
    )
    .get('/', { test: 'hello' as const })
    .post('/json', ({ body, status }) => body, {
        body: t.Object({
            hello: t.String()
        })
    })
    .listen(3000)
```

### Production Optimization

Pre-generate declaration files in production:

```typescript
openapi({
    references: fromTypes(
        process.env.NODE_ENV === 'production'
            ? 'dist/index.d.ts'
            : 'src/index.ts'
    )
})
```

## Route Documentation

### detail Property

Add metadata using `detail` on route options:

```typescript
.post('/sign-in', ({ body }) => body, {
    body: t.Object(
        {
            username: t.String(),
            password: t.String({
                minLength: 8,
                description: 'User password (at least 8 characters)'
            })
        },
        { description: 'Expected a username and password' }
    ),
    detail: {
        summary: 'Sign in the user',
        tags: ['authentication']
    }
})
```

### Response Headers

Document response headers with `withHeader`:

```typescript
import { withHeader } from '@elysiajs/openapi'

.get('/thing', ({ body, set }) => {
    set.headers['x-powered-by'] = 'Elysia'
    return body
}, {
    response: withHeader(
        t.Literal('Hi'),
        { 'x-powered-by': t.Literal('Elysia') }
    )
})
```

`withHeader` is annotation-only; headers must still be set manually in the handler.

### Hiding Routes

Exclude a route from generated documentation:

```typescript
detail: {
    hide: true
}
```

## Tags & Organization

### Define Available Tags

```typescript
new Elysia().use(
    openapi({
        documentation: {
            tags: [
                { name: 'App', description: 'General endpoints' },
                { name: 'Auth', description: 'Authentication endpoints' }
            ]
        }
    })
)
```

### Assign Tags to Routes

```typescript
.get('/', () => 'Hello Elysia', {
    detail: {
        tags: ['App']
    }
})
```

### Instance-Level Tags

Apply tags to every route in an Elysia instance:

```typescript
new Elysia({
    tags: ['user']
})
    .get('/user', 'user')
```

## Reference Models

Use named models for reusable schemas:

```typescript
new Elysia()
    .model({
        User: t.Object({
            id: t.Number(),
            username: t.String()
        })
    })
    .get('/user', () => ({ id: 1, username: 'saltyaom' }), {
        response: { 200: 'User' },
        detail: { tags: ['User'] }
    })
```

## Guards

Apply descriptions to grouped routes:

```typescript
new Elysia()
    .guard({
        detail: {
            description: 'Require user to be logged in'
        }
    })
    .get('/user', 'user')
```

## Configuration

### Custom Endpoint Path

```typescript
.use(
    openapi({
        path: '/v2/openapi'
    })
)
```

### Custom Info

```typescript
openapi({
    documentation: {
        info: {
            title: 'Elysia Documentation',
            version: '1.0.0'
        }
    }
})
```

### Security Schemes

Define Bearer/JWT authentication:

```typescript
openapi({
    documentation: {
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT'
                }
            }
        }
    }
})

new Elysia({
    prefix: '/address',
    detail: {
        tags: ['Address'],
        security: [{ bearerAuth: [] }]
    }
})
```

## Non-Native Schema Support

For schemas like Zod, provide a custom mapper:

```typescript
// Zod 4
import * as z from 'zod'
openapi({
    mapJsonSchema: {
        zod: z.toJSONSchema
    }
})

// Zod 3
import { zodToJsonSchema } from 'zod-to-json-schema'
openapi({
    mapJsonSchema: {
        zod: zodToJsonSchema
    }
})
```

## Troubleshooting

- **Type generation issues** — Use the `Prettify<T>` helper to inline explicit types.
- **Root path reliability** — Explicitly provide the project root path, especially in monorepos.
- **Multiple tsconfig files** — Specify the correct path via the `tsconfigPath` option.
