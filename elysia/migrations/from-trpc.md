# From tRPC to Elysia

This guide helps tRPC developers migrate to Elysia by comparing syntax, patterns, and features side-by-side.

**tRPC** is a typesafe RPC framework for building APIs using TypeScript, using proprietary RPC abstractions over RESTful APIs.

**Elysia** is an ergonomic web framework focusing on RESTful standards while offering end-to-end type safety through Eden.

## Key Differences

tRPC uses proprietary RPC abstractions (procedures, routers) over RESTful APIs. Elysia focuses on standard RESTful patterns (HTTP methods, path parameters) while providing end-to-end type safety through Eden.

---

## Routing

tRPC uses nested routers and procedures. Elysia uses HTTP methods and path parameters.

**tRPC:**

```typescript
import { initTRPC } from '@trpc/server'
import { createHTTPServer } from '@trpc/server/adapters/standalone'

const t = initTRPC.create()

const appRouter = t.router({
    hello: t.procedure.query(() => 'Hello World'),
    user: t.router({
        getById: t.procedure
            .input((id: string) => id)
            .query(({ input }) => {
                return { id: input }
            })
    })
})

const server = createHTTPServer({
    router: appRouter
})

server.listen(3000)
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    .get('/', 'Hello World')
    .post(
        '/id/:id',
        ({ status, params: { id } }) => {
            return status(201, id)
        }
    )
    .listen(3000)
```

Key differences:
- tRPC uses nested router objects and procedures (`t.procedure.query()`).
- Elysia uses Express-like HTTP method syntax (`.get()`, `.post()`).
- tRPC routes are function-based (RPC); Elysia routes are path-based (REST).

---

## Handler

tRPC procedures differentiate between `query` (read) and `mutation` (write), treating all input as a single parameter. Elysia uses standard HTTP methods with specific context properties.

**tRPC:**

```typescript
import { initTRPC } from '@trpc/server'

const t = initTRPC.create()

const appRouter = t.router({
    user: t.procedure
        .input((val: { limit?: number; name: string; authorization?: string }) => val)
        .mutation(({ input }) => {
            const limit = input.limit
            const name = input.name
            const auth = input.authorization

            return { limit, name, auth }
        })
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    .post('/user', (ctx) => {
        const limit = ctx.query.limit
        const name = ctx.body.name
        const auth = ctx.headers.authorization

        return { limit, name, auth }
    })
```

Elysia uses static code analysis to determine what to parse, and only parses the required properties. tRPC collapses all input into a single `input` object, while Elysia separates concerns into `query`, `body`, `headers`, and `params`.

---

## Subrouter

tRPC uses nested router objects. Elysia uses `.use()` with separate Elysia instances.

**tRPC:**

```typescript
import { initTRPC } from '@trpc/server'

const t = initTRPC.create()

const subRouter = t.router({
    user: t.procedure.query(() => 'Hello User')
})

const appRouter = t.router({
    api: subRouter
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const subRouter = new Elysia()
    .get('/user', 'Hello User')

const app = new Elysia()
    .use(subRouter)
```

Elysia treats every instance as a plug-and-play component. Subrouters can optionally define a prefix in the constructor: `new Elysia({ prefix: '/api' })`.

---

## Validation

Both frameworks support Standard Schema for validation with libraries like Zod, Valibot, and ArkType. Elysia also provides built-in TypeBox validation.

**tRPC:**

```typescript
import { initTRPC } from '@trpc/server'
import { z } from 'zod'

const t = initTRPC.create()

const appRouter = t.router({
    user: t.procedure
        .input(
            z.object({
                id: z.number(),
                name: z.string()
            })
        )
        .mutation(({ input }) => input)
})
```

**Elysia with TypeBox:**

```typescript
import { Elysia, t } from 'elysia'

const app = new Elysia()
    .patch('/user/:id', ({ params, body }) => ({
        params,
        body
    }),
    {
        params: t.Object({
            id: t.Number()
        }),
        body: t.Object({
            name: t.String()
        })
    })
```

**Elysia with Zod:**

```typescript
import { Elysia } from 'elysia'
import { z } from 'zod'

const app = new Elysia()
    .patch('/user/:id', ({ params, body }) => ({
        params,
        body
    }),
    {
        params: z.object({
            id: z.number()
        }),
        body: z.object({
            name: z.string()
        })
    })
```

**Elysia with Valibot:**

```typescript
import { Elysia } from 'elysia'
import * as v from 'valibot'

const app = new Elysia()
    .patch('/user/:id', ({ params, body }) => ({
        params,
        body
    }),
    {
        params: v.object({
            id: v.number()
        }),
        body: v.object({
            name: v.string()
        })
    })
```

Both frameworks offer automatic type inference from schemas. Elysia separates validation into `params`, `body`, `query`, and `headers` for fine-grained control.

---

## File Upload

tRPC lacks native file upload support, requiring base64 encoding without mimetype validation. Elysia provides built-in file upload with Web Standard API.

**tRPC:**

```typescript
import { initTRPC, TRPCError } from '@trpc/server'
import { z } from 'zod'
import { fileTypeFromBuffer } from 'file-type'

const t = initTRPC.create()

export const uploadRouter = t.router({
    uploadImage: t.procedure
        .input(z.string().base64())
        .mutation(async ({ input }) => {
            const buffer = Buffer.from(input, 'base64')

            const type = await fileTypeFromBuffer(buffer)
            if (!type || !type.mime.startsWith('image/'))
                throw new TRPCError({
                    code: 'UNPROCESSABLE_CONTENT',
                    message: 'Invalid file type',
                })

            return input
        })
})
```

**Elysia:**

```typescript
import { Elysia, t } from 'elysia'

const app = new Elysia()
    .post('/upload', ({ body }) => body.file, {
        body: t.Object({
            file: t.File({
                type: 'image'
            })
        })
    })
```

Elysia handles file and mimetype validation declaratively using Web Standard API. tRPC requires workarounds like base64 encoding and external libraries for MIME type detection.

---

## Middleware

tRPC uses queue-based middleware with a `next` function. Elysia uses an event-based lifecycle with granular control.

**tRPC:**

```typescript
import { initTRPC } from '@trpc/server'

const t = initTRPC.create()

const log = t.middleware(async ({ ctx, next }) => {
    console.log('Request started')

    const result = await next()

    console.log('Request ended')

    return result
})

const appRouter = t.router({
    hello: log
        .unstable_pipe(t.procedure)
        .query(() => 'Hello World')
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    // Global middleware
    .onRequest(({ method, path }) => {
        console.log(`${method} ${path}`)
    })
    // Route-specific middleware
    .get('/protected', () => 'protected', {
        beforeHandle({ status, headers }) {
            if (!headers.authorization)
                return status(401)
        }
    })
```

Elysia uses specific event interceptors (`onRequest`, `beforeHandle`, `afterHandle`) for each point in the request pipeline, providing more granular control than tRPC's linear middleware chain.

---

## Sound Type Safety

tRPC uses context typing that requires manual type definition. Elysia provides sound type safety with `decorate` and `resolve` methods.

**tRPC:**

```typescript
import { initTRPC } from '@trpc/server'

const t = initTRPC.context<{
    version: number
    token: string
}>().create()

const appRouter = t.router({
    version: t.procedure.query(({ ctx: { version } }) => version),

    token: t.procedure.query(({ ctx: { token, version } }) => {
        version

        return token
    })
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    .decorate('version', 2)
    .get('/version', ({ version }) => version)
    .resolve(({ status, headers: { authorization } }) => {
        if(!authorization?.startsWith('Bearer '))
            return status(401)

        return {
            token: authorization.split(' ')[1]
        }
    })
    .get('/token', ({ token, version }) => {
        version

        return token
    })
```

tRPC requires you to define the full context type upfront and ensure it is provided correctly at runtime. Elysia's `decorate` and `resolve` progressively build the typed context, with each addition automatically reflected in downstream handlers.

---

## Middleware Parameter

tRPC uses higher-order functions for parameterized middleware. Elysia uses macros with full type safety.

**tRPC:**

```typescript
import { initTRPC, TRPCError } from '@trpc/server'

const t = initTRPC.create()

const findUser = (authorization?: string) => {
    return {
        name: 'Jane Doe',
        role: 'admin' as const
    }
}

const role = (role: 'user' | 'admin') =>
    t.middleware(({ next, input }) => {
        const user = findUser(input as string)

        if(user.role !== role)
            throw new TRPCError({
                code: 'UNAUTHORIZED',
                message: 'Unauthorized',
            })

        return next({
            ctx: {
                user
            }
        })
    })

const appRouter = t.router({
    token: t.procedure
        .use(role('admin'))
        .query(({ ctx: { user } }) => user)
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    .macro({
        role: (role: 'user' | 'admin') => ({
            resolve({ status, headers: { authorization } }) {
                const user = findUser(authorization)

                if(user.role !== role)
                    return status(401)

                return {
                    user
                }
            }
        })
    })
    .get('/token', ({ user }) => user, {
        role: 'admin'
    })
```

Elysia macros provide type-safe custom middleware parameters as declarative route configuration options rather than chained method calls.

---

## Error Handling

tRPC handles errors through middleware-like patterns using `TRPCError`. Elysia provides custom error classes with HTTP status codes and multiple handler scopes.

**tRPC:**

```typescript
import { initTRPC, TRPCError } from '@trpc/server'

const t = initTRPC.create()

class CustomError extends Error {
    constructor(message: string) {
        super(message)
        this.name = 'CustomError'
    }
}

const appRouter = t.router({
    error: t.procedure
        .use(async ({ next }) => {
            try {
                return await next()
            } catch (error) {
                console.log(error)

                throw new TRPCError({
                    code: 'INTERNAL_SERVER_ERROR',
                    message: error.message
                })
            }
        })
        .query(() => {
            throw new CustomError('oh uh')
        })
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

class CustomError extends Error {
    status = 500

    constructor(message: string) {
        super(message)
        this.name = 'CustomError'
    }

    toResponse() {
        return {
            message: "If you're seeing this, our dev forgot to handle this error",
            error: this
        }
    }
}

const app = new Elysia()
    .error({
        CUSTOM: CustomError,
    })
    .onError(({ error, code }) => {
        if(code === 'CUSTOM')
            return {
                message: 'Something went wrong!',
                error
            }
    })
    .get('/error', () => {
        throw new CustomError('oh uh')
    }, {
        error({ error }) {
            return {
                message: 'Only for this route!',
                error
            }
        }
    })
```

Elysia provides:
1. Both global and route-specific error handlers.
2. Custom error codes via `.error()` for type-safe error identification.
3. Shorthand `status` property and `toResponse()` method on error classes.
4. tRPC requires wrapping errors in `TRPCError`; Elysia can use custom error classes directly.

---

## Encapsulation

tRPC automatically isolates procedure and router side-effects. Elysia provides explicit scoping control with three levels.

**tRPC:**

```typescript
import { initTRPC, TRPCError } from '@trpc/server'

const t = initTRPC.create()

const subRouter = t.router({
    protected: t.procedure
        .use(async ({ ctx, next }) => {
            if(!ctx.headers?.authorization?.startsWith('Bearer '))
                throw new TRPCError({
                    code: 'UNAUTHORIZED',
                    message: 'Unauthorized',
                })

            return next()
        })
        .query(() => 'Protected content')
})

const appRouter = t.router({
    hello: t.procedure.query(() => 'Hello World'),
    api: subRouter
})
```

**Elysia (local scope, default):**

```typescript
import { Elysia } from 'elysia'

const subRouter = new Elysia()
    .onBeforeHandle(({ status, headers: { authorization } }) => {
        if(!authorization?.startsWith('Bearer '))
            return status(401)
    })

const app = new Elysia()
    .get('/', 'Hello World')
    .use(subRouter)
    // doesn't have side-effect from subRouter
    .get('/side-effect', () => 'hi')
```

**Elysia (scoped):**

```typescript
import { Elysia } from 'elysia'

const subRouter = new Elysia()
    .onBeforeHandle(({ status, headers: { authorization } }) => {
        if(!authorization?.startsWith('Bearer '))
            return status(401)
    })
    // Scoped to parent instance but not beyond
    .as('scoped')

const app = new Elysia()
    .get('/', 'Hello World')
    .use(subRouter)
    // now has side-effects from subRouter
    .get('/side-effect', () => 'hi')
```

Elysia offers three scoping mechanisms:
1. **local** - Applies to current instance only, no side-effect (default).
2. **scoped** - Affects parent instance only.
3. **global** - Affects every instance.

---

## OpenAPI

tRPC requires third-party libraries for OpenAPI generation (e.g., `trpc-to-openapi`). Elysia provides built-in OpenAPI support.

**tRPC:**

```typescript
import { initTRPC } from '@trpc/server'
import { createHTTPServer } from '@trpc/server/adapters/standalone'
import { OpenApiMeta } from 'trpc-to-openapi'

const t = initTRPC.meta<OpenApiMeta>().create()

const appRouter = t.router({
    user: t.procedure
        .meta({
            openapi: {
                method: 'POST',
                path: '/users',
                tags: ['User'],
                summary: 'Create user',
            }
        })
        .input(
            z.array(
                z.object({
                    name: z.string(),
                    age: z.number()
                })
            )
        )
        .output(
            z.array(
                z.object({
                    name: z.string(),
                    age: z.number()
                })
            )
        )
        .mutation(({ input }) => input)
})

export const openApiDocument = generateOpenApiDocument(appRouter, {
    title: 'tRPC OpenAPI',
    version: '1.0.0',
    baseUrl: 'http://localhost:3000'
})
```

**Elysia:**

```typescript
import { Elysia, t } from 'elysia'
import { openapi } from '@elysiajs/openapi'

const app = new Elysia()
    .use(openapi())
    .model({
        user: t.Array(
            t.Object({
                name: t.String(),
                age: t.Number()
            })
        )
    })
    .post('/users', ({ body }) => body, {
        body: 'user',
        response: {
            201: 'user'
        },
        detail: {
            summary: 'Create user'
        }
    })
```

tRPC requires consistent awareness of router placement and procedure naming for OpenAPI generation. Elysia generates specs from the schema, providing a single source of truth for validation, types, and documentation.

---

## Testing

tRPC requires `createCallerFactory` setup for testing. Elysia uses Web Standard API and optionally Eden for type-safe testing.

**tRPC:**

```typescript
import { describe, it, expect } from 'vitest'
import { initTRPC } from '@trpc/server'
import { z } from 'zod'

const t = initTRPC.create()
const publicProcedure = t.procedure
const { createCallerFactory, router } = t

const appRouter = router({
    post: router({
        add: publicProcedure
            .input(
                z.object({
                    title: z.string().min(2)
                })
            )
            .mutation(({ input }) => input)
    })
})

const createCaller = createCallerFactory(appRouter)
const caller = createCaller({})

describe('POST /add', () => {
    it('should create a post', async () => {
        const newPost = await caller.post.add({
            title: '74 Itoki Hana'
        })

        expect(newPost).toEqual({
            title: '74 Itoki Hana'
        })
    })
})
```

**Elysia (Web Standard):**

```typescript
import { Elysia, t } from 'elysia'
import { describe, it, expect } from 'vitest'

const app = new Elysia()
    .post('/add', ({ body }) => body, {
        body: t.Object({
            title: t.String({ minLength: 2 })
        })
    })

describe('POST /add', () => {
    it('should create a post', async () => {
        const res = await app.handle(
            new Request('http://localhost/add', {
                method: 'POST',
                body: JSON.stringify({ title: '74 Itoki Hana' }),
                headers: {
                    'Content-Type': 'application/json'
                }
            })
        )

        expect(res.status).toBe(200)
        expect(await res.json()).toEqual({
            title: '74 Itoki Hana'
        })
    })
})
```

**Elysia with Eden (type-safe):**

```typescript
import { Elysia } from 'elysia'
import { treaty } from '@elysiajs/eden'
import { describe, expect, it } from 'bun:test'

const app = new Elysia().get('/hello', 'Hello World')
const api = treaty(app)

describe('GET /hello', () => {
    it('should return Hello World', async () => {
        const { data, error, status } = await api.hello.get()

        expect(status).toBe(200)
        expect(data).toBe('Hello World')
    })
})
```

Elysia uses Web Standard API with no special factory setup. Eden provides type-safe testing similar to tRPC's caller pattern.

---

## End-to-End Type Safety

Both frameworks support end-to-end type safety. Elysia provides better error type soundness.

**tRPC:**

```typescript
import { initTRPC } from '@trpc/server'
import { createHTTPServer } from '@trpc/server/adapters/standalone'
import { z } from 'zod'
import { createTRPCProxyClient, httpBatchLink } from '@trpc/client'

const t = initTRPC.create()

const appRouter = t.router({
    mirror: t.procedure
        .input(
            z.object({
                message: z.string()
            })
        )
        .output(
            z.object({
                message: z.string()
            })
        )
        .mutation(({ input }) => input)
})

const server = createHTTPServer({
    router: appRouter
})

server.listen(3000)

const client = createTRPCProxyClient<typeof appRouter>({
    links: [
        httpBatchLink({
            url: 'http://localhost:3000'
        })
    ]
})

const { message } = await client.mirror.mutate({
    message: 'Hello World'
})
```

**Elysia:**

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .post('/mirror', ({ body }) => body, {
        body: t.Object({
            message: t.String()
        })
    })

const api = treaty(app)

const { data, error } = await api.mirror.post({
    message: 'Hello World'
})

if(error)
    throw error

console.log(data)
```

Key differences:
- tRPC handles only the "happy path" scenarios, lacking error type soundness.
- Elysia provides complete type safety for both success and error cases via the `{ data, error }` pattern.
- tRPC requires a running server or separate client setup. Elysia's Eden can work directly with the app instance.
- Elysia is RESTful compliant with OpenAPI and WinterTC Standard, making it a better fit for building a universal API.
