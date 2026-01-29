# At Glance

> **Source**: https://elysiajs.com/at-glance

Elysia is an ergonomic web framework for building backend servers with Bun. It emphasizes simplicity, type safety, and high performance through a familiar API with extensive TypeScript support optimized for Bun.

## Hello World

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/', 'Hello Elysia')
    .get('/user/:id', ({ params: { id } }) => id)
    .post('/form', ({ body }) => body)
    .listen(3000)
```

---

## Performance Benchmarks

Elysia achieves high performance through Bun optimization and static code analysis. Benchmark results measured in requests per second:

| Framework | Runtime | Average | Plain Text | Dynamic Params | JSON Body |
|-----------|---------|---------|-----------|----------------|-----------|
| bun | bun | 262,660 | 326,376 | 237,083 | 224,522 |
| **elysia** | **bun** | **255,575** | **313,074** | **241,892** | **211,759** |
| hyper-express | node | 234,396 | 311,775 | 249,675 | 141,737 |
| hono | bun | 203,938 | 239,230 | 201,663 | 170,920 |
| h3 | node | 96,515 | 114,972 | 87,936 | 86,637 |
| oak | deno | 46,570 | 55,174 | 48,260 | 36,275 |
| fastify | bun | 65,897 | 92,857 | 81,605 | 23,230 |
| fastify | node | 60,322 | 71,151 | 62,060 | 47,756 |
| koa | node | 39,594 | 46,220 | 40,962 | 31,601 |
| express | bun | 29,716 | 39,455 | 34,701 | 14,990 |
| express | node | 15,913 | 17,737 | 17,129 | 12,874 |

---

## TypeScript and Type Safety

Elysia is designed to help you write less TypeScript by automatically inferring types from code without explicit declarations. This provides both compile-time and runtime safety.

### Basic Path Parameter

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/user/:id', ({ params: { id } }) => id)
    .listen(3000)
```

### Type Integrity with Schema Validation

Using `t` (TypeBox) to define schemas that enforce runtime validation and provide TypeScript types:

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
    .get('/user/:id', ({ params: { id } }) => id, {
        params: t.Object({
            id: t.Number()
        })
    })
    .listen(3000)
```

---

## Standard Schema Support

Elysia supports [Standard Schema](https://github.com/standard-schema/standard-schema), enabling use of preferred validation libraries including Zod, Valibot, ArkType, Effect Schema, Yup, and Joi.

```typescript
import { Elysia } from 'elysia'
import { z } from 'zod'
import * as v from 'valibot'

new Elysia()
    .get('/id/:id', ({ params: { id }, query: { name } }) => id, {
        params: z.object({
            id: z.coerce.number()
        }),
        query: v.object({
            name: v.literal('Lilith')
        })
    })
    .listen(3000)
```

---

## OpenAPI Integration

Elysia can automatically generate OpenAPI documentation from your route schemas.

### Basic OpenAPI Setup

```typescript
import { Elysia, t } from 'elysia'
import { openapi } from '@elysiajs/openapi'

new Elysia()
    .use(openapi())
    .get('/user/:id', ({ params: { id } }) => id, {
        params: t.Object({
            id: t.Number()
        })
    })
    .listen(3000)
```

### OpenAPI with Type-Based References

Using `fromTypes()` to generate OpenAPI references from TypeScript types:

```typescript
import { Elysia, t } from 'elysia'
import { openapi, fromTypes } from '@elysiajs/openapi'

export const app = new Elysia()
    .use(openapi({
        references: fromTypes()
    }))
    .get('/user/:id', ({ params: { id } }) => id, {
        params: t.Object({
            id: t.Number()
        })
    })
    .listen(3000)

export type App = typeof app
```

---

## End-to-End Type Safety with Eden

Eden provides a type-safe client that mirrors your Elysia server's API, enabling full end-to-end type safety.

### Server Setup

```typescript
import { Elysia, t } from 'elysia'
import { openapi, fromTypes } from '@elysiajs/openapi'

export const app = new Elysia()
    .use(openapi({
        references: fromTypes()
    }))
    .get('/user/:id', ({ params: { id } }) => id, {
        params: t.Object({
            id: t.Number()
        })
    })
    .listen(3000)

export type App = typeof app
```

### Client Implementation

```typescript
import { treaty } from '@elysiajs/eden'
import type { App } from './server'

const app = treaty<App>('localhost:3000')

// Get data from /user/617
const { data } = await app.user({ id: 617 }).get()

console.log(data)
```

---

## Type Soundness with Macro Error Handling

Macros allow reusable lifecycle patterns with full type safety, including status code inference:

```typescript
import { Elysia, t } from 'elysia'

const plugin = new Elysia()
    .macro({
        auth: {
            cookie: t.Object({
                session: t.String()
            }),
            beforeHandle({ cookie: { session }, status }) {
                if (session.value !== 'valid')
                    return status(401)
            }
        }
    })

const app = new Elysia()
    .use(plugin)
    .get('/user/:id', ({ params: { id }, status }) => {
        if (Math.random() > 0.1)
            return status(420)

        return id
    }, {
        auth: true,
        params: t.Object({
            id: t.Number()
        })
    })
    .listen(3000)

export type App = typeof app
```

---

## Platform Agnostic (WinterTC)

Elysia achieves platform agnosticity through WinterTC compliance, supporting deployment on multiple runtimes and platforms:

- **Bun** (primary, optimized)
- **Node.js**
- **Deno**
- **Cloudflare Worker**
- **Vercel**
- **Expo** (via API routes)
- **Next.js** (via API routes)
- **Astro** (via API routes)

---

## Community and Production Use

Elysia is used in production by many companies and projects worldwide. It has been actively maintained since 2022 and is used by over 10,000 open source projects on GitHub.
