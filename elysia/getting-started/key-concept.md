# Key Concept

> **Source**: https://elysiajs.com/key-concept

Core design principles and patterns that underpin how Elysia works. Understanding these concepts is essential for writing idiomatic Elysia code.

---

## 1. Encapsulation

Elysia lifecycle methods are encapsulated to their own instance only. Lifecycle hooks do not automatically propagate to other instances unless explicitly declared.

### Without Global Scope

```typescript
import { Elysia } from 'elysia'

const profile = new Elysia()
    .onBeforeHandle(({ cookie }) => {
        throwIfNotSignIn(cookie)
    })
    .get('/profile', () => 'Hi there!')

const app = new Elysia()
    .use(profile)
    // This will NOT have sign in check
    .patch('/rename', ({ body }) => updateProfile(body))
```

The `onBeforeHandle` hook only applies to routes within the `profile` instance. The `/rename` route in `app` is not affected.

### With Global Scope

Use `{ as: 'global' }` to export a lifecycle hook to every instance that uses this plugin:

```typescript
import { Elysia } from 'elysia'

const profile = new Elysia()
    .onBeforeHandle(
        { as: 'global' },
        ({ cookie }) => {
            throwIfNotSignIn(cookie)
        }
    )
    .get('/profile', () => 'Hi there!')

const app = new Elysia()
    .use(profile)
    // This WILL have sign in check
    .patch('/rename', ({ body }) => updateProfile(body))
```

---

## 2. Method Chaining

Elysia code should **always** use method chaining. This is critical for ensuring type safety.

Every Elysia method returns a new type reference. Without chaining, type information is lost.

### Correct: With Chaining

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .state('build', 1)
    // Store is strictly typed
    .get('/', ({ store: { build } }) => build)
    .listen(3000)
```

The `.state()` method returns a new `ElysiaInstance` type with a typed `build` property. Method chaining preserves this type through subsequent calls.

### Incorrect: Without Chaining

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()

app.state('build', 1)

app.get('/', ({ store: { build } }) => build)
// Error: Property 'build' does not exist on type '{}'.
app.listen(3000)
```

Without chaining, the new type from `.state()` is not captured, and type inference fails.

---

## 3. Explicit Dependencies

Elysia is composed of multiple mini Elysia apps which can run independently, like microservices that communicate with each other. Each instance is independent and must explicitly declare what it needs.

```typescript
import { Elysia } from 'elysia'

const auth = new Elysia()
    .decorate('Auth', Auth)
    .model(Auth.models)

const main = new Elysia()
    // 'auth' is missing - will error
    .get('/', ({ Auth }) => Auth.getProfile())
    // Error: Property 'Auth' does not exist on type...

    .use(auth) // Now auth is available
    .get('/profile', ({ Auth }) => Auth.getProfile())
```

This approach mirrors Dependency Injection, forcing explicit declaration of dependencies for better modularity and tracking.

---

## 4. Deduplication

By default, plugins re-execute every time they are applied to another instance, causing redundant operations. Elysia solves this through unique identifiers.

### Using Name for Deduplication

```typescript
import { Elysia } from 'elysia'

// `name` is a unique identifier
const ip = new Elysia({ name: 'ip' })
    .derive(
        { as: 'global' },
        ({ server, request }) => ({
            ip: server?.requestIP(request)
        })
    )
    .get('/ip', ({ ip }) => ip)

const router1 = new Elysia()
    .use(ip)
    .get('/ip-1', ({ ip }) => ip)

const router2 = new Elysia()
    .use(ip)
    .get('/ip-2', ({ ip }) => ip)

const server = new Elysia()
    .use(router1)
    .use(router2)
```

Adding `name` (and optional `seed`) creates a unique identifier that prevents duplicate execution across instances.

### When to Use Global vs. Explicit

**Global plugins** (use `{ as: 'global' }`) are appropriate for:
- Plugins that don't add types (cors, compress, helmet)
- Global lifecycle events (tracing, logging, OpenAPI, OpenTelemetry)

**Explicit dependencies** (use `.use()`) are appropriate for:
- Plugins that add types (macro, state, model)
- Business logic plugins (Auth, Database, ORM)
- Feature modules (Chat, Notification)

---

## 5. Order of Code Matters

The order of Elysia lifecycle code is critical. Events will only apply to routes registered **after** the event is defined.

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .onBeforeHandle(() => {
        console.log('1')
    })
    .get('/', () => 'hi')
    .onBeforeHandle(() => {
        console.log('2')
    })
    .listen(3000)
```

**Console output when `GET /` is called:**

```
1
```

The second `onBeforeHandle` does **not** execute for `GET /` because it is registered **after** the route. It would only apply to routes registered after it.

---

## 6. Type Inference

### Inline Functions

Always use inline functions for accurate type inference:

```typescript
import { Elysia, t } from 'elysia'

const app = new Elysia()
    .post('/', ({ body }) => body, {
        body: t.Object({
            name: t.String()
        })
    })
```

### MVC Controller Pattern

If using a controller pattern, destructure properties from the inline function to maintain type safety:

```typescript
import { Elysia, t } from 'elysia'

abstract class Controller {
    static greet({ name }: { name: string }) {
        return 'hello ' + name
    }
}

const app = new Elysia()
    .post('/', ({ body }) => Controller.greet(body), {
        body: t.Object({
            name: t.String()
        })
    })
```

### Extracting TypeScript Types

Use the `.static` property to extract TypeScript types from Elysia/TypeBox schemas:

```typescript
import { t } from 'elysia'

const MyType = t.Object({
    hello: t.Literal('Elysia')
})

type MyType = typeof MyType.static
// { hello: 'Elysia' }
```

---

## 7. Single Source of Truth

A single Elysia/TypeBox schema serves multiple purposes simultaneously:

- **Runtime validation** - validates incoming data at runtime
- **Data coercion** - automatically converts data types (e.g., string to number)
- **TypeScript type definitions** - provides compile-time types
- **OpenAPI schema generation** - generates API documentation

This eliminates duplicate schema declarations, making the schema a single source of truth for all type-related requirements. Elysia can infer and provide types automatically, reducing the need to declare duplicate schemas.

```typescript
import { Elysia, t } from 'elysia'

// This single schema provides:
// - Runtime validation
// - TypeScript types
// - OpenAPI documentation
// - Data coercion
new Elysia()
    .get('/user/:id', ({ params: { id } }) => id, {
        params: t.Object({
            id: t.Number()
        })
    })
    .listen(3000)
```
