# From Hono to Elysia

This guide helps Hono developers migrate to Elysia by comparing syntax, patterns, and features side-by-side.

**Hono** is a fast and lightweight web framework built on Web Standard, supporting Deno, Bun, Cloudflare Workers, and Node.js.

**Elysia** is an ergonomic web framework designed for developer experience with a focus on sound type safety and performance.

## When to Use Which

**Hono strengths:**
- Originally built for Cloudflare Workers with integrated ecosystem support.
- Supports multiple runtimes via Web Standard.
- Lightweight and minimalistic for edge environments.
- Middleware-based approach similar to Express/Koa.
- Larger user base.

**Elysia strengths:**
- Originally built for native Bun, also supports Node.js and Cloudflare Workers.
- Better performance optimized for long-running servers via JIT.
- Superior OpenAPI support with seamless integration.
- Event-based lifecycle approach for request pipeline control.
- Sound type safety across middleware and error handling.

## Performance

Elysia has significant performance improvements over Hono thanks to static code analysis:

- **Elysia**: 1,837,294 reqs/s
- **Hono**: 740,451 reqs/s

_(TechEmpower Benchmark Round 23)_

---

## Routing

**Hono:**

```typescript
import { Hono } from 'hono'

const app = new Hono()

app.get('/', (c) => {
    return c.text('Hello World')
})

app.post('/id/:id', (c) => {
    c.status(201)
    return c.text(c.req.param('id'))
})

export default app
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
- Hono uses helper methods like `c.text()` and `c.json()` to return responses. Elysia maps values to responses automatically.
- Elysia supports inline values when context is not needed (e.g. `'Hello World'`).

---

## Handler

**Hono:**

```typescript
import { Hono } from 'hono'

const app = new Hono()

app.post('/user', async (c) => {
    const limit = c.req.query('limit')
    const { name } = await c.req.json()
    const auth = c.req.header('authorization')

    return c.json({ limit, name, auth })
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

Elysia uses static code analysis to determine what to parse, and only parses the required properties. Body parsing is synchronous because Elysia pre-parses based on the route definition.

---

## Subrouter

**Hono:**

```typescript
import { Hono } from 'hono'

const subRouter = new Hono()

subRouter.get('/user', (c) => {
    return c.text('Hello User')
})

const app = new Hono()

app.route('/api', subRouter)
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const subRouter = new Elysia({ prefix: '/api' })
    .get('/user', 'Hello User')

const app = new Elysia()
    .use(subRouter)
```

Hono requires a prefix to separate the subrouter via `app.route('/prefix', subRouter)`. Elysia defines the prefix on the subrouter instance itself and does not require a prefix to separate the subrouter.

---

## Validation

Hono uses `@hono/zod-validator` for validation with Zod. Elysia provides built-in validation using TypeBox and supports Standard Schema (Zod, Valibot, ArkType).

**Hono with Zod:**

```typescript
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import { z } from 'zod'

const app = new Hono()

app.patch(
    '/user/:id',
    zValidator(
        'param',
        z.object({
            id: z.coerce.number()
        })
    ),
    zValidator(
        'json',
        z.object({
            name: z.string()
        })
    ),
    (c) => {
        return c.json({
            params: c.req.param(),
            body: c.req.json()
        })
    }
)
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

Elysia automatically coerces types and uses a unified validation syntax regardless of the validation library.

---

## File Upload

Hono requires a separate `file-type` library to validate MIME types. Elysia handles file and mimetype validation declaratively.

**Hono:**

```typescript
import { Hono } from 'hono'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'
import { fileTypeFromBlob } from 'file-type'

const app = new Hono()

app.post(
    '/upload',
    zValidator(
        'form',
        z.object({
            file: z.instanceof(File)
        })
    ),
    async (c) => {
        const body = await c.req.parseBody()

        const type = await fileTypeFromBlob(body.image as File)
        if (!type || !type.mime.startsWith('image/')) {
            c.status(422)
            return c.text('File is not a valid image')
        }

        return new Response(body.image)
    }
)
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

Elysia handles file and mimetype validation declaratively using `t.File()`, eliminating the need for external libraries.

---

## Middleware

Hono uses a queue-based middleware approach with `next()`. Elysia uses an event-based lifecycle without `next()`.

**Hono:**

```typescript
import { Hono } from 'hono'

const app = new Hono()

// Global middleware
app.use(async (c, next) => {
    console.log(`${c.req.method} ${c.req.url}`)

    await next()
})

app.get(
    '/protected',
    // Route-specific middleware
    async (c, next) => {
        const token = c.req.header('authorization')

        if (!token) {
            c.status(401)
            return c.text('Unauthorized')
        }

        await next()
    },
    (c) => {
        return c.text('Protected route')
    }
)
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

Key differences:
- Hono has a `next` function to call the next middleware; Elysia does not.
- Elysia uses specific event interceptors (`onRequest`, `beforeHandle`, `afterHandle`) for each point in the request pipeline.

---

## Sound Type Safety

Hono provides type safety via `createMiddleware` and `c.set()`/`c.get()`, but it is not sound everywhere. Elysia provides sound type safety natively.

**Hono:**

```typescript
import { Hono } from 'hono'
import { createMiddleware } from 'hono/factory'

const app = new Hono()

const getVersion = createMiddleware(async (c, next) => {
    c.set('version', 2)

    await next()
})

app.use(getVersion)

app.get('/version', getVersion, (c) => {
    return c.text(c.get('version') + '')
})

const authenticate = createMiddleware(async (c, next) => {
    const token = c.req.header('authorization')

    if (!token) {
        c.status(401)
        return c.text('Unauthorized')
    }

    c.set('token', token.split(' ')[1])

    await next()
})

app.post('/user', authenticate, async (c) => {
    c.get('version')
    return c.text(c.get('token'))
})
```

**Elysia (type-safe):**

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

Hono can use `declare module` to extend the `ContextVariableMap` interface, but it is globally available and does not have sound type safety. Elysia's `decorate` and `resolve` provide type safety that is scoped and verified at compile time.

---

## Middleware Parameter

Hono uses higher-order functions with `createMiddleware`. Elysia uses macros with full type safety.

**Hono:**

```typescript
import { Hono } from 'hono'
import { createMiddleware } from 'hono/factory'

const app = new Hono()

const role = (role: 'user' | 'admin') => createMiddleware(async (c, next) => {
    const user = findUser(c.req.header('Authorization'))

    if(user.role !== role) {
        c.status(401)
        return c.text('Unauthorized')
    }

    c.set('user', user)

    await next()
})

app.get('/user/:id', role('admin'), (c) => {
    return c.json(c.get('user'))
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

Elysia macros provide type-safe custom middleware parameters as route configuration options.

---

## Error Handling

Hono provides a global error handler. Elysia provides both global and route-specific error handlers with custom error codes.

**Hono:**

```typescript
import { Hono } from 'hono'

class CustomError extends Error {
    constructor(message: string) {
        super(message)
        this.name = 'CustomError'
    }
}

const app = new Hono()

// global error handler
app.onError((error, c) => {
    if(error instanceof CustomError) {
        c.status(500)

        return c.json({
            message: 'Something went wrong!',
            error
        })
    }
})

// route that throws
app.get('/error', (c) => {
    throw new CustomError('oh uh')
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

class CustomError extends Error {
    // Optional: custom HTTP status code
    status = 500

    constructor(message: string) {
        super(message)
        this.name = 'CustomError'
    }

    // Optional: what should be sent to the client
    toResponse() {
        return {
            message: "If you're seeing this, our dev forgot to handle this error",
            error: this
        }
    }
}

const app = new Elysia()
    // Optional: register custom error class
    .error({
        CUSTOM: CustomError,
    })
    // Global error handler
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
        // Optional: route specific error handler
        error({ error }) {
            return {
                message: 'Only for this route!',
                error
            }
        }
    })
```

Elysia provides more granular control over error handling with scoping mechanisms, custom error codes, and route-specific handlers.

---

## Encapsulation

Hono subrouters are naturally isolated. Elysia provides explicit scoping mechanisms with three levels.

**Hono:**

```typescript
import { Hono } from 'hono'

const subRouter = new Hono()

subRouter.get('/user', (c) => {
    return c.text('Hello User')
})

const app = new Hono()

app.route('/api', subRouter)
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
2. **scoped** - Scoped side-effect to the parent instance but not beyond.
3. **global** - Affects every instance.

### Plugin Deduplication

```typescript
import { Elysia } from 'elysia'

const subRouter = new Elysia({ name: 'subRouter' })
    .onBeforeHandle(({ status, headers: { authorization } }) => {
        if(!authorization?.startsWith('Bearer '))
            return status(401)
    })
    .as('scoped')

const app = new Elysia()
    .get('/', 'Hello World')
    .use(subRouter)
    .use(subRouter)
    .use(subRouter)
    .use(subRouter)
    // side-effect only called once
    .get('/side-effect', () => 'hi')
```

Using a unique `name`, Elysia ensures the plugin is only applied once regardless of how many times `.use()` is called.

---

## Cookie

Hono uses helper functions from `hono/cookie`. Elysia has built-in cookie support with a signal-based approach and automatic signature handling.

**Hono:**

```typescript
import { Hono } from 'hono'
import { getSignedCookie, setSignedCookie } from 'hono/cookie'

const app = new Hono()

app.get('/', async (c) => {
    const name = await getSignedCookie(c, 'secret', 'name')

    await setSignedCookie(
        c,
        'name',
        'value',
        'secret',
        {
            maxAge: 1000,
        }
    )
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const app = new Elysia({
    cookie: {
        secret: 'secret'
    }
})
    .get('/', ({ cookie: { name } }) => {
        // signature verification is handled automatically
        name.value

        // cookie signature is signed automatically
        name.value = 'value'
        name.maxAge = 1000 * 60 * 60 * 24
    })
```

Elysia uses a signal-based approach where reading and writing cookies with signatures is handled automatically. No explicit sign/unsign calls are needed.

---

## OpenAPI

Hono requires additional effort and libraries to describe OpenAPI specifications. Elysia seamlessly integrates the specification into the schema.

**Hono:**

```typescript
import { Hono } from 'hono'
import { describeRoute, openAPISpecs } from 'hono-openapi'
import { resolver, validator as zodValidator } from 'hono-openapi/zod'
import { swaggerUI } from '@hono/swagger-ui'
import { z } from '@hono/zod-openapi'

const app = new Hono()

const model = z.array(
    z.object({
        name: z.string().openapi({
            description: 'first name only'
        }),
        age: z.number()
    })
)

const detail = await resolver(model).builder()

app.post(
    '/',
    zodValidator('json', model),
    describeRoute({
        validateResponse: true,
        summary: 'Create user',
        requestBody: {
            content: {
                'application/json': { schema: detail.schema }
            }
        },
        responses: {
            201: {
                description: 'User created',
                content: {
                    'application/json': { schema: resolver(model) }
                }
            }
        }
    }),
    (c) => {
        c.status(201)
        return c.json(c.req.valid('json'))
    }
)

app.get('/ui', swaggerUI({ url: '/doc' }))

app.get(
    '/doc',
    openAPISpecs(app, {
        documentation: {
            info: {
                title: 'Hono API',
                version: '1.0.0',
                description: 'Greeting API'
            },
            components: {
                ...detail.components
            }
        }
    })
)

export default app
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

Hono requires additional effort with multiple libraries to describe the specification. Elysia seamlessly integrates the specification into the schema, using a single source of truth for validation, types, and documentation.

---

## Testing

Both Hono and Elysia support Web Standard API for testing. Elysia additionally provides Eden for type-safe testing.

**Hono:**

```typescript
import { Hono } from 'hono'
import { describe, it, expect } from 'vitest'

const app = new Hono()
    .get('/', (c) => c.text('Hello World'))

describe('GET /', () => {
    it('should return Hello World', async () => {
        const res = await app.request('/')

        expect(res.status).toBe(200)
        expect(await res.text()).toBe('Hello World')
    })
})
```

**Elysia (Web Standard):**

```typescript
import { Elysia } from 'elysia'
import { describe, it, expect } from 'vitest'

const app = new Elysia()
    .get('/', 'Hello World')

describe('GET /', () => {
    it('should return Hello World', async () => {
        const res = await app.handle(
            new Request('http://localhost')
        )

        expect(res.status).toBe(200)
        expect(await res.text()).toBe('Hello World')
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

describe('GET /', () => {
    it('should return Hello World', async () => {
        const { data, error, status } = await api.hello.get()

        expect(status).toBe(200)
        expect(data).toBe('Hello World')
    })
})
```

Both frameworks support Web Standard API for testing. Elysia's Eden library additionally provides end-to-end type safety without code generation.

---

## End-to-End Type Safety

Both Hono and Elysia support end-to-end type safety, but Elysia provides better type inference performance and handles more routes.

**Hono:**

```typescript
import { Hono } from 'hono'
import { hc } from 'hono/client'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'

const app = new Hono()
    .post(
        '/mirror',
        zValidator(
            'json',
            z.object({
                message: z.string()
            })
        ),
        (c) => c.json(c.req.valid('json'))
    )

const client = hc<typeof app>('/')

const response = await client.mirror.$post({
    json: {
        message: 'Hello, world!'
    }
})

const data = await response.json()

console.log(data)
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

Type inference performance comparison:
- **Elysia**: 536ms for type inference (handles up to 2,000 routes with complex validation).
- **Hono**: 1.27s with errors; fails beyond ~100 routes with "Type instantiation is excessively deep and possibly infinite."

Elysia provides superior type inference performance and scales to significantly more routes.
