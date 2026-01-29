# From Express to Elysia

This guide helps Express developers migrate to Elysia by comparing syntax, patterns, and features side-by-side.

**Express** is a popular Node.js web framework known for simplicity and flexibility.

**Elysia** is an ergonomic web framework for Bun and Node.js emphasizing sound type safety and performance.

## Performance

Elysia achieves significantly higher throughput than Express:

- **Elysia**: 2,454,631 reqs/s
- **Express**: 113,117 reqs/s

_(TechEmpower Benchmark Round 22, 2023-10-17, PlainText)_

---

## Routing

**Express:**

```typescript
import express from 'express'

const app = express()

app.get('/', (req, res) => {
    res.send('Hello World')
})

app.post('/id/:id', (req, res) => {
    res.status(201).send(req.params.id)
})

app.listen(3000)
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
- Express uses separate `req` and `res` objects; Elysia uses a single context object.
- Elysia returns responses directly instead of calling `res.send()`.
- Elysia supports inline values when context is not needed (e.g. `'Hello World'`).

---

## Handler

Both frameworks provide similar properties for accessing `headers`, `query`, `params`, and `body`.

**Express:**

```typescript
import express from 'express'

const app = express()

app.use(express.json())

app.post('/user', (req, res) => {
    const limit = req.query.limit
    const name = req.body.name
    const auth = req.headers.authorization

    res.json({ limit, name, auth })
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

Elysia parses JSON, URL-encoded data, and form data by default, whereas Express requires explicit middleware like `express.json()`.

---

## Subrouter

**Express:**

```typescript
import express from 'express'

const subRouter = express.Router()

subRouter.get('/user', (req, res) => {
    res.send('Hello User')
})

const app = express()

app.use('/api', subRouter)
```

**Elysia:**

```typescript
import { Elysia } from 'elysia'

const subRouter = new Elysia({ prefix: '/api' })
    .get('/user', 'Hello User')

const app = new Elysia()
    .use(subRouter)
```

Elysia treats every instance as a component, enabling plug-and-play composition via `.use()`.

---

## Validation

Express lacks built-in validation. Elysia provides built-in support using TypeBox and supports Standard Schema (Zod, Valibot, ArkType, Effect Schema).

**Express with Zod (manual validation):**

```typescript
import express from 'express'
import { z } from 'zod'

const app = express()

app.use(express.json())

const paramSchema = z.object({
    id: z.coerce.number()
})

const bodySchema = z.object({
    name: z.string()
})

app.patch('/user/:id', (req, res) => {
    const params = paramSchema.safeParse(req.params)
    if (!params.success)
        return res.status(422).json(result.error)

    const body = bodySchema.safeParse(req.body)
    if (!body.success)
        return res.status(422).json(result.error)

    res.json({
        params: params.id.data,
        body: body.data
    })
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

Elysia uses TypeBox for validation and coerces types automatically, while supporting multiple validation libraries with identical syntax.

---

## File Upload

Express requires the external `multer` library. Elysia provides built-in support for file and form data, including MIME-type validation.

**Express:**

```typescript
import express from 'express'
import multer from 'multer'
import { fileTypeFromFile } from 'file-type'
import path from 'path'

const app = express()
const upload = multer({ dest: 'uploads/' })

app.post('/upload', upload.single('image'), async (req, res) => {
    const file = req.file

    if (!file)
        return res
            .status(422)
            .send('No file uploaded')

    const type = await fileTypeFromFile(file.path)
    if (!type || !type.mime.startsWith('image/'))
        return res
            .status(422)
            .send('File is not a valid image')

    const filePath = path.resolve(file.path)
    res.sendFile(filePath)
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

Elysia handles file and mimetype validation declaratively, automatically validating MIME types. Express requires multer plus manual validation with external libraries.

---

## Middleware / Lifecycle

Express uses a single queue-based order for middleware. Elysia uses an event-based lifecycle with granular control over each point in the request pipeline.

**Express:**

```typescript
import express from 'express'

const app = express()

// Global middleware
app.use((req, res, next) => {
    console.log(`${req.method} ${req.url}`)
    next()
})

app.get(
    '/protected',
    // Route-specific middleware
    (req, res, next) => {
        const token = req.headers.authorization

        if (!token)
            return res.status(401).send('Unauthorized')

        next()
    },
    (req, res) => {
        res.send('Protected route')
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

Elysia uses a specific event interceptor for each point in the request pipeline (e.g. `onRequest`, `beforeHandle`, `afterHandle`) rather than linear `next()` progression.

---

## Sound Type Safety

Express requires `@ts-ignore` and `declare module` workarounds for type-safe context customization. Elysia provides sound type safety natively.

**Express (with type issues):**

```typescript
import express from 'express'
import type { Request, Response } from 'express'

const app = express()

const getVersion = (req: Request, res: Response, next: Function) => {
    // @ts-ignore
    req.version = 2

    next()
}

app.get('/version', getVersion, (req, res) => {
    res.send(req.version)
})

const authenticate = (req: Request, res: Response, next: Function) => {
    const token = req.headers.authorization

    if (!token)
        return res.status(401).send('Unauthorized')

    // @ts-ignore
    req.token = token.split(' ')[1]

    next()
}

app.get('/token', getVersion, authenticate, (req, res) => {
    req.version
    res.send(req.token)
})
```

Express workaround (globally declared, not type-safe):

```typescript
declare module 'express' {
    interface Request {
        version: number
        token: string
    }
}
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

Elysia provides sound type safety where `decorate` and `resolve` add typed properties to the context automatically. Express requires `declare module` globally without runtime guarantees.

---

## Middleware Parameter

Express uses functions returning middleware for reusable route-specific logic. Elysia uses macros with full type safety.

**Express:**

```typescript
import express from 'express'
import type { Request, Response } from 'express'

const app = express()

const role = (role: 'user' | 'admin') =>
    (req: Request, res: Response, next: Function) => {
        const user = findUser(req.headers.authorization)

        if (user.role !== role)
            return res.status(401).send('Unauthorized')

        // @ts-ignore
        req.user = user

        next()
    }

app.get('/token', role('admin'), (req, res) => {
    res.send(req.user)
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

Elysia uses `macro` to pass custom arguments to custom middleware with type safety. The `user` property is automatically typed in the handler.

---

## Error Handling

Express uses a single global error handler. Elysia provides granular control over error handling with both global and route-specific handlers.

**Express:**

```typescript
import express from 'express'

const app = express()

class CustomError extends Error {
    constructor(message: string) {
        super(message)
        this.name = 'CustomError'
    }
}

// global error handler
app.use((error, req, res, next) => {
    if(error instanceof CustomError) {
        res.status(500).json({
            message: 'Something went wrong!',
            error
        })
    }
})

// route-specific error handler
app.get('/error', (req, res) => {
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

Elysia provides:
1. Both global and route-specific error handlers.
2. Shorthand for HTTP status and `toResponse` for error mapping.
3. Custom error codes for each error type via `.error()`.

---

## Encapsulation

Express middleware affects scope globally and can cause unintended side-effects. Elysia provides explicit scoping mechanisms.

**Express (global side-effects):**

```typescript
import express from 'express'

const app = express()

app.get('/', (req, res) => {
    res.send('Hello World')
})

const subRouter = express.Router()

subRouter.use((req, res, next) => {
    const token = req.headers.authorization

    if (!token)
        return res.status(401).send('Unauthorized')

    next()
})

app.use(subRouter)

// has side-effect from subRouter
app.get('/side-effect', (req, res) => {
    res.send('hi')
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
    // now have side-effect from subRouter
    .get('/side-effect', () => 'hi')
```

Elysia offers three scoping mechanisms:
1. **local** - Applies to current instance only, no side-effect (default).
2. **scoped** - Affects parent instance only.
3. **global** - Affects every instance.

Express lacks true encapsulation, leading to difficult debugging scenarios with unintended side-effects.

---

## Cookie

Express requires the external `cookie-parser` package. Elysia has built-in support for cookies using a signal-based approach.

**Express:**

```typescript
import express from 'express'
import cookieParser from 'cookie-parser'

const app = express()

app.use(cookieParser('secret'))

app.get('/', function (req, res) {
    req.cookies.name
    req.signedCookies.name

    res.cookie('name', 'value', {
        signed: true,
        maxAge: 1000 * 60 * 60 * 24
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

Elysia automates signature handling and verification. Express requires manual management of signed vs. unsigned cookies.

---

## OpenAPI

Express requires separate OpenAPI specification configuration that can drift from actual implementation. Elysia uses the schema as a single source of truth.

**Express:**

```typescript
import express from 'express'
import swaggerUi from 'swagger-ui-express'

const app = express()
app.use(express.json())

app.post('/users', (req, res) => {
    // TODO: validate request body
    res.status(201).json(req.body)
})

const swaggerSpec = {
    openapi: '3.0.0',
    info: {
        title: 'My API',
        version: '1.0.0'
    },
    paths: {
        '/users': {
            post: {
                summary: 'Create user',
                requestBody: {
                    content: {
                        'application/json': {
                            schema: {
                                type: 'object',
                                properties: {
                                    name: {
                                        type: 'string',
                                        description: 'First name only'
                                    },
                                    age: { type: 'integer' }
                                },
                                required: ['name', 'age']
                            }
                        }
                    }
                },
                responses: {
                    '201': {
                        description: 'User created'
                    }
                }
            }
        }
    }
}

app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec))
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

Elysia generates an OpenAPI specification, validates requests and responses, and infers types automatically from schemas. The schema is the single source of truth for validation, types, and documentation.

---

## Testing

Express uses `supertest` for testing. Elysia works with Web Standard API and supports any testing library.

**Express:**

```typescript
import express from 'express'
import request from 'supertest'
import { describe, it, expect } from 'vitest'

const app = express()

app.get('/', (req, res) => {
    res.send('Hello World')
})

describe('GET /', () => {
    it('should return Hello World', async () => {
        const res = await request(app).get('/')

        expect(res.status).toBe(200)
        expect(res.text).toBe('Hello World')
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

Elysia's Eden library provides end-to-end type safety without code generation, making tests fully type-checked.

---

## End-to-End Type Safety

Elysia offers built-in support for end-to-end type safety without code generation using Eden. This feature is not available in Express.

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

Eden provides end-to-end type safety without code generation, including typed error handling. Express has no equivalent feature.
