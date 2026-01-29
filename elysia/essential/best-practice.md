# Best Practice

> **Source**: https://elysiajs.com/essential/best-practice

Recommended patterns for structuring Elysia applications using MVC principles, with emphasis on type safety and the Single Source of Truth approach.

---

## Project Structure

Elysia advocates for feature-based folder organization, grouping related code by feature:

```
src/
  modules/
    auth/
      index.ts       # Elysia controller
      service.ts     # Business logic
      model.ts       # Data structures and validation
    user/
      index.ts       # Elysia controller
      service.ts     # Business logic
      model.ts       # Data structures and validation
  utils/
    a/
      index.ts
    b/
      index.ts
```

This structure keeps related functionality together within feature directories and makes code easy to locate.

---

## MVC Pattern

Elysia adapts MVC principles while maintaining type safety:

| Layer | Responsibility |
|-------|---------------|
| **Controller** | HTTP routing, validation, cookies |
| **Service** | Business logic independent of HTTP concerns |
| **Model** | Data structures and validation schemas |

Each layer maintains clear separation of concerns while preserving type inference capabilities.

---

## Controller

### Recommended: Elysia Instance as Controller

Treat an Elysia instance directly as your controller. One Elysia instance = one controller:

```typescript
import { Elysia } from 'elysia'
import { Auth } from './service'
import { AuthModel } from './model'

export const auth = new Elysia({ prefix: '/auth' })
    .get(
        '/sign-in',
        async ({ body, cookie: { session } }) => {
            const response = await Auth.signIn(body)
            session.value = response.token
            return response
        }, {
            body: AuthModel.signInBody,
            response: {
                200: AuthModel.signInResponse,
                400: AuthModel.signInInvalid
            }
        }
    )
```

Elysia automatically infers the `Context` type, ensuring type integrity and consistency.

### Anti-Pattern: Traditional Controller Classes

Do **not** use controller classes that accept raw `Context`:

```typescript
// Don't do this
import { Elysia, t, type Context } from 'elysia'

abstract class Controller {
    static root(context: Context) {
        return Service.doStuff(context.stuff)
    }
}

new Elysia()
    .get('/', Controller.root)
```

`Context` is a highly dynamic type that loses integrity when passed wholesale. This pattern makes it difficult to type correctly.

### Alternative: HTTP-Agnostic Controllers

If you prefer controller classes, decouple them from Elysia entirely by destructuring properties:

```typescript
import { Elysia } from 'elysia'

abstract class Controller {
    static doStuff(stuff: string) {
        return Service.doStuff(stuff)
    }
}

new Elysia()
    .get('/', ({ stuff }) => Controller.doStuff(stuff))
```

This enables testing, reusability, and prevents vendor lock-in.

### Testing Controllers

Use Elysia's `.handle()` method for integration testing:

```typescript
import { Elysia } from 'elysia'
import { Service } from './service'
import { describe, it, expect } from 'bun:test'

const app = new Elysia()
    .get('/', ({ stuff }) => {
        Service.doStuff(stuff)
        return 'ok'
    })

describe('Controller', () => {
    it('should work', async () => {
        const response = await app
            .handle(new Request('http://localhost/'))
            .then((x) => x.text())
        expect(response).toBe('ok')
    })
})
```

---

## Service

Services encapsulate business logic decoupled from controllers.

### Non-Request-Dependent Services

For services that do not access HTTP context, use static classes or functions:

```typescript
import { Elysia, t } from 'elysia'

abstract class Service {
    static fibo(number: number): number {
        if (number < 2)
            return number
        return Service.fibo(number - 1) + Service.fibo(number - 2)
    }
}

new Elysia()
    .get('/fibo', ({ body }) => {
        return Service.fibo(body)
    }, {
        body: t.Numeric()
    })
```

Using `abstract class` with `static` methods avoids unnecessary class instantiation.

### Request-Dependent Services

For services that need HTTP request context, implement them as Elysia instances:

```typescript
import { Elysia } from 'elysia'

const AuthService = new Elysia({ name: 'Auth.Service' })
    .macro({
        isSignIn: {
            resolve({ cookie, status }) {
                if (!cookie.session.value) return status(401)
                return {
                    session: cookie.session.value,
                }
            }
        }
    })

const UserController = new Elysia()
    .use(AuthService)
    .get('/profile', ({ Auth: { user } }) => user, {
        isSignIn: true
    })
```

Elysia handles plugin deduplication automatically, creating singletons when a `name` property exists.

### Service with Error Handling

Services can throw HTTP status errors directly using the `status` function:

```typescript
import { status } from 'elysia'
import type { AuthModel } from './model'

export abstract class Auth {
    static async signIn({ username, password }: AuthModel.signInBody) {
        const user = await sql`
            SELECT password
            FROM users
            WHERE username = ${username}
            LIMIT 1`

        if (!await Bun.password.verify(password, user.password))
            throw status(
                400,
                'Invalid username or password' satisfies AuthModel.signInInvalid
            )

        return {
            username,
            token: await generateAndSaveTokenToDB(user.id)
        }
    }
}
```

### Decoration Best Practice

Decorate only request-dependent properties. Avoid overusing decorators as it ties code to Elysia and reduces testability:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .decorate('requestIP', ({ request }) =>
        request.headers.get('x-forwarded-for') || request.ip
    )
    .decorate('requestTime', () => Date.now())
    .decorate('session', ({ cookie }) => cookie.session.value)
    .get('/', ({ requestIP, requestTime, session }) => {
        return { requestIP, requestTime, session }
    })
```

---

## Model

Models define data structures and validation schemas. Elysia leverages `t` (TypeBox-based) as the single source of truth for both types and runtime validation.

### Recommended: Elysia Validation System

```typescript
import { Elysia, t } from 'elysia'

const customBody = t.Object({
    username: t.String(),
    password: t.String()
})

// Extract TypeScript type using `.static`
type CustomBody = typeof customBody.static

export { customBody }
```

### Using Models in Controllers

```typescript
new Elysia()
    .post('/login', ({ body }) => {
        return body
    }, {
        body: customBody
    })
```

### Anti-Pattern: Class-Based or Interface Models

Do **not** define models as classes or interfaces separately from validation schemas:

```typescript
// Don't do this
class CustomBody {
    username: string
    password: string
    constructor(username: string, password: string) {
        this.username = username
        this.password = password
    }
}

// Don't do this either
interface ICustomBody {
    username: string
    password: string
}
```

### Anti-Pattern: Separate Type Declarations

Always derive types from validation schemas rather than declaring them separately:

```typescript
// Don't do this
const customBody = t.Object({
    username: t.String(),
    password: t.String()
})

type CustomBody = {
    username: string
    password: string
}

// Do this instead
type CustomBody = typeof customBody.static
```

### Complete Model Example with Namespace

```typescript
import { t } from 'elysia'

export namespace AuthModel {
    // Define DTOs for Elysia validation
    export const signInBody = t.Object({
        username: t.String(),
        password: t.String(),
    })

    export type signInBody = typeof signInBody.static

    export const signInResponse = t.Object({
        username: t.String(),
        token: t.String(),
    })

    export type signInResponse = typeof signInResponse.static

    export const signInInvalid = t.Literal('Invalid username or password')
    export type signInInvalid = typeof signInInvalid.static
}
```

### Model Injection with References

Named models provide auto-completion, schema modification capability, OpenAPI compliance, and improved TypeScript inference speed through cached models:

```typescript
import { Elysia, t } from 'elysia'

const customBody = t.Object({
    username: t.String(),
    password: t.String()
})

const AuthModel = new Elysia()
    .model({
        sign: customBody
    })

const UserController = new Elysia({ prefix: '/auth' })
    .use(AuthModel)
    .prefix('model', 'auth.')
    .post('/sign-in', async ({ body, cookie: { session } }) => {
        return true
    }, {
        body: 'auth.Sign'
    })
```

---

## Error Handling Conventions

### Throwing from Services

Services throw HTTP status errors using the `status` function:

```typescript
import { status } from 'elysia'

if (!await Bun.password.verify(password, user.password))
    throw status(
        400,
        'Invalid username or password' satisfies AuthModel.signInInvalid
    )
```

### Response Validation with Error States

Controllers define multiple response codes for type-safe error handling:

```typescript
export const auth = new Elysia({ prefix: '/auth' })
    .get(
        '/sign-in',
        async ({ body, cookie: { session } }) => {
            const response = await Auth.signIn(body)
            session.value = response.token
            return response
        }, {
            body: AuthModel.signInBody,
            response: {
                200: AuthModel.signInResponse,
                400: AuthModel.signInInvalid
            }
        }
    )
```

---

## Type Inference Best Practices

### Single Source of Truth

Elysia's strength is prioritizing a single source of truth for both type and runtime validation. Always derive types from validation schemas.

### Extract Types from Validation Schemas

```typescript
const customBody = t.Object({
    username: t.String(),
    password: t.String()
})

type CustomBody = typeof customBody.static
```

### Avoid Context Type Annotations

Never manually type `Context` in controllers or handlers. Let Elysia infer it:

```typescript
// Don't do this
static root(context: Context) { ... }

// Do this instead - let Elysia infer
.get('/', ({ stuff }) => { ... })
```

### Benefits

- Automatic synchronization between validation and types
- Eliminates runtime/type mismatches
- OpenAPI schema generation from the same source
- IDE auto-completion through proper inference

---

## Complete Auth Module Example

### Controller (`auth/index.ts`)

```typescript
import { Elysia } from 'elysia'
import { Auth } from './service'
import { AuthModel } from './model'

export const auth = new Elysia({ prefix: '/auth' })
    .get(
        '/sign-in',
        async ({ body, cookie: { session } }) => {
            const response = await Auth.signIn(body)
            session.value = response.token
            return response
        }, {
            body: AuthModel.signInBody,
            response: {
                200: AuthModel.signInResponse,
                400: AuthModel.signInInvalid
            }
        }
    )
```

### Service (`auth/service.ts`)

```typescript
import { status } from 'elysia'
import type { AuthModel } from './model'

export abstract class Auth {
    static async signIn({ username, password }: AuthModel.signInBody) {
        const user = await sql`
            SELECT password FROM users
            WHERE username = ${username} LIMIT 1`

        if (!await Bun.password.verify(password, user.password))
            throw status(
                400,
                'Invalid username or password' satisfies AuthModel.signInInvalid
            )

        return {
            username,
            token: await generateAndSaveTokenToDB(user.id)
        }
    }
}
```

### Model (`auth/model.ts`)

```typescript
import { t } from 'elysia'

export namespace AuthModel {
    export const signInBody = t.Object({
        username: t.String(),
        password: t.String(),
    })

    export type signInBody = typeof signInBody.static

    export const signInResponse = t.Object({
        username: t.String(),
        token: t.String(),
    })

    export type signInResponse = typeof signInResponse.static

    export const signInInvalid = t.Literal('Invalid username or password')
    export type signInInvalid = typeof signInInvalid.static
}
```
