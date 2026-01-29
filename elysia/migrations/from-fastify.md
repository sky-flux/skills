# From Fastify to Elysia

This guide helps Fastify developers migrate to Elysia by comparing syntax, patterns, and features side-by-side.

**Fastify** is a fast and low overhead web framework for Node.js, designed to be simple and easy to use.

**Elysia** is an ergonomic web framework for Bun, Node.js, and any runtime that supports Web Standard API, emphasizing sound type safety and performance.

## Performance

Elysia achieves significantly higher throughput than Fastify:

- **Elysia**: 2,454,631 reqs/s
- **Fastify**: 415,600 reqs/s

_(TechEmpower Benchmark Round 22, 2023-10-17)_

---

## Routing

**Fastify:**

```typescript
import fastify from 'fastify'

const app = fastify()

app.get('/', (request, reply) => {
    reply.send('Hello World')
})

app.post('/id/:id', (request, reply) => {
    reply.status(201).send(request.params.id)
})

app.listen({ port: 3000 })
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
- Fastify uses `request`/`reply` objects; Elysia uses a unified context and returns responses directly.
- Elysia supports inline values when context is not needed.

---

## Handler

**Fastify:**

```typescript
import fastify from 'fastify'

const app = fastify()

app.post('/user', (request, reply) => {
    const limit = request.query.limit
    const name = request.body.name
    const auth = request.headers.authorization

    reply.send({ limit, name, auth })
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

Both frameworks parse request data automatically, but Elysia organizes everything through a single context object and returns responses directly.

---

## Subrouter / Plugin

Fastify uses function callbacks with `register`. Elysia treats instances as plug-and-play components.

**Fastify:**

```typescript
import fastify, { FastifyPluginCallback } from 'fastify'

const subRouter: FastifyPluginCallback = (app, opts, done) => {
    app.get('/user', (request, reply) => {
        reply.send('Hello User')
    })

    done()
}

const app = fastify()

app.register(subRouter, {
    prefix: '/api'
})
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const subRouter = new Elysia({ prefix: '/api' })
    .get('/user', 'Hello User')

const app = new Elysia()
    .use(subRouter)
```

Elysia treats every instance as a component. No callback functions or `done()` calls are needed.

---

## Validation

Fastify uses JSON Schema with type providers for validation. Elysia provides built-in validation using TypeBox and supports Standard Schema (Zod, Valibot, ArkType).

**Fastify:**

```typescript
import fastify from 'fastify'
import { JsonSchemaToTsProvider } from '@fastify/type-provider-json-schema-to-ts'

const app = fastify().withTypeProvider<JsonSchemaToTsProvider>()

app.patch(
    '/user/:id',
    {
        schema: {
            params: {
                type: 'object',
                properties: {
                    id: {
                        type: 'string',
                        pattern: '^[0-9]+$'
                    }
                },
                required: ['id']
            },
            body: {
                type: 'object',
                properties: {
                    name: { type: 'string' }
                },
                required: ['name']
            },
        }
    },
    (request, reply) => {
        request.params.id = +request.params.id

        reply.send({
            params: request.params,
            body: request.body
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

Elysia automatically coerces types (e.g., string path params to numbers) and supports multiple validation libraries with consistent syntax.

---

## File Upload

Fastify requires the external `@fastify/multipart` library. Elysia provides built-in support for file and form data, including MIME-type validation.

**Fastify:**

```typescript
import fastify from 'fastify'
import multipart from '@fastify/multipart'

import { fileTypeFromBuffer } from 'file-type'

const app = fastify()
app.register(multipart, {
    attachFieldsToBody: 'keyValues'
})

app.post(
    '/upload',
    {
        schema: {
            body: {
                type: 'object',
                properties: {
                    file: { type: 'object' }
                },
                required: ['file']
            }
        }
    },
    async (req, res) => {
        const file = req.body.file
        if (!file) return res.status(422).send('No file uploaded')

        const type = await fileTypeFromBuffer(file)
        if (!type || !type.mime.startsWith('image/'))
            return res.status(422).send('File is not a valid image')

        res.header('Content-Type', type.mime)
        res.send(file)
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

Elysia provides declarative file and mimetype validation. Fastify requires manual verification with external libraries.

---

## Lifecycle Events

Both Fastify and Elysia use event-based lifecycle approaches. However, Elysia automatically detects lifecycle events and does not require calling `done()`.

**Fastify:**

```typescript
import fastify from 'fastify'

const app = fastify()

// Global middleware
app.addHook('onRequest', (request, reply, done) => {
    console.log(`${request.method} ${request.url}`)

    done()
})

app.get(
    '/protected',
    {
        // Route-specific middleware
        preHandler(request, reply, done) {
            const token = request.headers.authorization

            if (!token) reply.status(401).send('Unauthorized')

            done()
        }
    },
    (request, reply) => {
        reply.send('Protected route')
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
            if (!headers.authorizaton)
                return status(401)
        }
    })
```

Key differences:
- Elysia does not require calling `done()` -- lifecycle events resolve automatically.
- Elysia uses specific event names like `onRequest`, `beforeHandle`, and `afterHandle` for granular control.

---

## Sound Type Safety

Fastify requires `@ts-ignore` and module augmentation for type-safe context customization. Elysia provides sound type safety natively.

**Fastify (type issues):**

```typescript
import fastify from 'fastify'

const app = fastify()

app.decorateRequest('version', 2)

app.get('/version', (req, res) => {
    res.send(req.version)
})

app.get(
    '/token',
    {
        preHandler(req, res, done) {
            const token = req.headers.authorization

            if (!token) return res.status(401).send('Unauthorized')

            // @ts-ignore
            req.token = token.split(' ')[1]

            done()
        }
    },
    (req, res) => {
        res.send(req.token)
    }
)

app.listen({
    port: 3000
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
        return token
    })
```

Elysia provides sound type safety where `decorate` and `resolve` add typed properties to the context automatically without `@ts-ignore` or module augmentation.

---

## Middleware Parameter

Fastify uses higher-order functions returning middleware. Elysia uses macros with full type safety.

**Fastify:**

```typescript
import fastify from 'fastify'
import type { FastifyRequest, FastifyReply } from 'fastify'

const app = fastify()

const role =
    (role: 'user' | 'admin') =>
    (request: FastifyRequest, reply: FastifyReply, next: Function) => {
        const user = findUser(request.headers.authorization)

        if (user.role !== role) return reply.status(401).send('Unauthorized')

        // @ts-ignore
        request.user = user

        next()
    }

app.get(
    '/token',
    {
        preHandler: role('admin')
    },
    (request, reply) => {
        reply.send(request.user)
    }
)
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

Elysia macros provide type-safe custom middleware parameters. The `user` property is automatically typed in the handler.

---

## Error Handling

Both Fastify and Elysia support global and route-specific error handlers. Elysia additionally provides custom error codes, status shortcuts, and type-safe error handling.

**Fastify:**

```typescript
import fastify from 'fastify'

class CustomError extends Error {
    constructor(message: string) {
        super(message)
        this.name = 'CustomError'
    }
}

const app = fastify()

// global error handler
app.setErrorHandler((error, request, reply) => {
    if (error instanceof CustomError)
        reply.status(500).send({
            message: 'Something went wrong!',
            error
        })
})

app.get(
    '/error',
    {
        // route-specific error handler
        errorHandler(error, request, reply) {
            reply.send({
                message: 'Only for this route!',
                error
            })
        }
    },
    (request, reply) => {
        throw new CustomError('oh uh')
    }
)
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

Elysia provides:
1. Both global and route-specific error handlers.
2. Custom error codes for each error type via `.error()`.
3. Shorthand `status` property and `toResponse()` method on error classes.

---

## Encapsulation

Fastify has plugin-based encapsulation through `register`. Elysia provides explicit scoping mechanisms with three levels.

**Fastify:**

```typescript
import fastify from 'fastify'
import type { FastifyPluginCallback } from 'fastify'

const subRouter: FastifyPluginCallback = (app, opts, done) => {
    app.addHook('preHandler', (request, reply) => {
        if (!request.headers.authorization?.startsWith('Bearer '))
            reply.code(401).send({ error: 'Unauthorized' })
    })

    done()
}

const app = fastify()
    .get('/', (request, reply) => {
        reply.send('Hello World')
    })
    .register(subRouter)
    // doesn't have side-effect from subRouter
    .get('/side-effect', () => 'hi')
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
    // now have side-effect from subRouter
    .get('/side-effect', () => 'hi')
```

Elysia offers three scoping mechanisms:
1. **local** - Applies to current instance only, no side-effect (default).
2. **scoped** - Affects parent instance only.
3. **global** - Affects every instance.

### Plugin Deduplication

Fastify can suffer from duplicate middleware execution when plugins are registered multiple times. Elysia deduplicates using the `name` property.

**Fastify (duplicate execution problem):**

```typescript
import fastify from 'fastify'
import type {
    FastifyRequest,
    FastifyReply,
    FastifyPluginCallback
} from 'fastify'

const log = (request: FastifyRequest, reply: FastifyReply, done: Function) => {
    console.log('Middleware executed')

    done()
}

const app = fastify()

app.addHook('onRequest', log)
app.get('/main', (request, reply) => {
    reply.send('Hello from main!')
})

const subRouter: FastifyPluginCallback = (app, opts, done) => {
    app.addHook('onRequest', log)

    // This would log twice
    app.get('/sub', (request, reply) => {
        return reply.send('Hello from sub router!')
    })

    done()
}

app.register(subRouter, {
    prefix: '/sub'
})

app.listen({
    port: 3000
})
```

**Elysia (deduplication):**

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

By setting a unique `name`, Elysia ensures the plugin is only applied once regardless of how many times `.use()` is called.

---

## Cookie

Fastify requires the external `@fastify/cookie` package. Elysia has built-in support for cookies using a signal-based approach.

**Fastify:**

```typescript
import fastify from 'fastify'
import cookie from '@fastify/cookie'

const app = fastify()

app.register(cookie, {
    secret: 'secret',
    hook: 'onRequest'
})

app.get('/', function (request, reply) {
    request.unsignCookie(request.cookies.name)

    reply.setCookie('name', 'value', {
        path: '/',
        signed: true
    })
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

Elysia uses a signal-based approach with automatic signature verification. No explicit sign/unsign calls are needed.

---

## OpenAPI

Fastify uses `@fastify/swagger` with JSON Schema. Elysia uses the schema as a single source of truth and defaults to Scalar UI.

**Fastify:**

```typescript
import fastify from 'fastify'
import swagger from '@fastify/swagger'

const app = fastify()
app.register(swagger, {
    openapi: '3.0.0',
    info: {
        title: 'My API',
        version: '1.0.0'
    }
})

app.addSchema({
    $id: 'user',
    type: 'object',
    properties: {
        name: {
            type: 'string',
            description: 'First name only'
        },
        age: { type: 'integer' }
    },
    required: ['name', 'age']
})

app.post(
    '/users',
    {
        schema: {
            summary: 'Create user',
            body: {
                $ref: 'user#'
            },
            response: {
                '201': {
                    $ref: 'user#'
                }
            }
        }
    },
    (req, res) => {
        res.status(201).send(req.body)
    }
)

await app.ready()
app.swagger()
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

Elysia generates OpenAPI specifications from schemas automatically, provides type safety for model references, and defaults to Scalar UI (more modern than Swagger).

---

## Testing

Fastify uses `inject` for testing. Elysia uses Web Standard API and supports any testing library.

**Fastify:**

```typescript
import fastify from 'fastify'
import { describe, it, expect } from 'vitest'

function build(opts = {}) {
    const app = fastify(opts)

    app.get('/', async function (request, reply) {
        reply.send({ hello: 'world' })
    })

    return app
}

describe('GET /', () => {
    it('should return Hello World', async () => {
        const app = build()

        const response = await app.inject({
            url: '/',
            method: 'GET',
        })

        expect(response.statusCode).toBe(200)
        expect(response.body).toBe('Hello World')
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

**Elysia with Eden (recommended):**

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

Elysia's Eden library provides end-to-end type safety for testing without code generation.

---

## End-to-End Type Safety

Elysia offers built-in support for end-to-end type safety without code generation using Eden. Fastify does not have a native equivalent.

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

Eden provides end-to-end type safety without code generation, including typed error handling. Fastify lacks sound type safety and the end-to-end type safety offered by next generation frameworks.
