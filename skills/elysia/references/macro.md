# Macro

Composable Elysia function for controlling lifecycle events, schema validation, and context with full type safety. Once defined, macros are activated via key-value labels on route handlers, providing reusable abstractions over hooks and middleware.

## Basic Pattern
```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
  .macro({
    hi: (word: string) => ({
      beforeHandle() { console.log(word) }
    })
  })
  .get('/', () => 'hi', { hi: 'Elysia' })
  // Logs "Elysia" before handling
```

A macro receives parameters from the route config and returns lifecycle hooks, schema definitions, or context resolvers.

## Property Shorthand

Since v1.2.10, macros support object shorthand. An object property is equivalent to a function that accepts a boolean and conditionally applies the lifecycle:

```typescript
.macro({
  // Object shorthand (recommended for simple on/off macros):
  isAuth: { resolve: () => ({ user: 'saltyaom' }) },

  // Equivalent function form:
  isAuth(enabled: boolean) {
    if (!enabled) return
    return { resolve() { return { user: 'saltyaom' } } }
  }
})

// Usage - both forms activate with:
.get('/profile', ({ user }) => user, { isAuth: true })
```

Object shorthand is best for macros that act as simple toggles. Use the function form when the macro needs a dynamic parameter (such as a role string or configuration object).

## Error Handling

Return `status()` instead of throwing errors. This ensures correct HTTP status code annotation for Eden clients and OpenAPI documentation:

```typescript
import { Elysia, status } from 'elysia'

const app = new Elysia()
  .macro({
    auth: {
      resolve({ headers }) {
        if (!headers.authorization)
          return status(401, 'Unauthorized')

        const token = headers.authorization.split(' ')[1]
        if (!token)
          return status(401, 'Missing token')

        // Decode/verify token here
        return { user: { id: 1, name: 'SaltyAom' } }
      }
    }
  })
  .get('/me', ({ user }) => user, { auth: true })
```

Key points for error handling in macros:
- Always use `return status(code, body)` rather than `throw new Error()`
- Returning `status()` annotates the correct HTTP code for Eden type inference
- Multiple error returns are supported; each gets proper type narrowing on the client

## Resolve - Add Context Props
```typescript
.macro({
  user: (enabled: true) => ({
    resolve: () => ({ user: 'Pardofelis' })
  })
})
.get('/', ({ user }) => user, { user: true })
// user is typed as string, available in handler context
```

The `resolve` function runs before the handler and injects its return value into the route context. This is the primary mechanism for dependency injection in Elysia macros.

### Named Macro for Type Inference

TypeScript cannot infer types from lifecycle functions when macros reference each other within the same `.macro()` call. Use named single-macro syntax as a workaround:

```typescript
const app = new Elysia()
  .macro('user', {
    resolve: () => ({ user: 'lilith' as const })
  })
  // Now 'user2' can reference the resolved 'user' with correct types
  .macro('user2', {
    user: true,
    resolve: ({ user }) => ({ greeting: `Hello ${user}` })
  })
  .get('/', ({ greeting }) => greeting, { user2: true })
```

Each `.macro('name', ...)` call creates an isolated type scope, enabling proper inference chains.

## Schema Composition

Macros can define validation schemas that auto-validate, infer types, and stack with other schemas:

```typescript
import { Elysia, t } from 'elysia'

const app = new Elysia()
  .macro({
    withFriends: {
      body: t.Object({
        friends: t.Tuple([
          t.Literal('Fouco'),
          t.Literal('Sartre')
        ])
      })
    }
  })
  .post('/party', ({ body }) => {
    // body.friends is typed as ['Fouco', 'Sartre']
    return `Invited: ${body.friends.join(', ')}`
  }, { withFriends: true })
```

Schema macros compose with route-level schemas. If both the macro and the route define `body`, Elysia merges them:

```typescript
.post('/party', ({ body }) => {
  // body has both 'friends' (from macro) and 'venue' (from route)
  return `${body.venue}: ${body.friends.join(', ')}`
}, {
  withFriends: true,
  body: t.Object({ venue: t.String() })
})
```

Use named single macro for lifecycle type inference within same macro.

## Extension

Macros can extend other macros, enabling compositional stacking:

```typescript
.macro({
  sartre: { body: t.Object({ existentialism: t.Boolean() }) },
  fouco: { body: t.Object({ discipline: t.String() }) },
  lilith: {
    fouco: true,
    sartre: true,
    body: t.Object({ alliance: t.Literal('philosopher') })
  }
})
// Using 'lilith' activates sartre + fouco + its own schema
.post('/philosophers', ({ body }) => body, { lilith: true })
```

Extended macros inherit all lifecycle hooks and schemas from their dependencies.

## Deduplication

Elysia automatically deduplicates lifecycle events using the macro property value as a seed. Custom seed for fine-grained control:

```typescript
.macro({
  sartre: (role: string) => ({
    seed: role,
    beforeHandle() { /* runs once per unique role value */ }
  })
})
```

Max stack depth: 16 (prevents infinite loops from circular macro references).

## Real-World Examples

### Authentication Macro

```typescript
import { Elysia, status } from 'elysia'

const authPlugin = new Elysia({ name: 'auth' })
  .macro({
    requireAuth: {
      resolve({ headers, cookie }) {
        const token = headers.authorization?.split('Bearer ')[1]
        if (!token) return status(401, 'No token provided')

        try {
          const payload = verifyJWT(token)
          return { auth: { userId: payload.sub, role: payload.role } }
        } catch {
          return status(401, 'Invalid token')
        }
      }
    }
  })

const app = new Elysia()
  .use(authPlugin)
  .get('/dashboard', ({ auth }) => {
    return { message: `Welcome user ${auth.userId}` }
  }, { requireAuth: true })
```

### Role-Based Access Control (RBAC) Macro

```typescript
import { Elysia, status } from 'elysia'

const rbacPlugin = new Elysia({ name: 'rbac' })
  .macro('requireAuth', {
    resolve({ headers }) {
      const token = headers.authorization?.split('Bearer ')[1]
      if (!token) return status(401, 'Unauthorized')
      return { auth: { userId: '1', role: 'editor' as string } }
    }
  })
  .macro({
    requireRole: (role: string) => ({
      requireAuth: true,
      beforeHandle({ auth }) {
        if (auth.role !== role)
          return status(403, `Requires role: ${role}`)
      }
    })
  })

const app = new Elysia()
  .use(rbacPlugin)
  .get('/admin', () => 'Admin panel', { requireRole: 'admin' })
  .get('/edit', () => 'Editor page', { requireRole: 'editor' })
```

### Rate-Limiting Macro

```typescript
import { Elysia, status } from 'elysia'

const rateStore = new Map<string, { count: number; reset: number }>()

const rateLimitPlugin = new Elysia({ name: 'rate-limit' })
  .macro({
    rateLimit: (maxRequests: number) => ({
      seed: maxRequests,
      beforeHandle({ request }) {
        const ip = request.headers.get('x-forwarded-for') ?? 'unknown'
        const now = Date.now()
        const record = rateStore.get(ip)

        if (!record || now > record.reset) {
          rateStore.set(ip, { count: 1, reset: now + 60_000 })
          return
        }

        if (record.count >= maxRequests)
          return status(429, 'Too many requests')

        record.count++
      }
    })
  })

const app = new Elysia()
  .use(rateLimitPlugin)
  .get('/api/data', () => 'OK', { rateLimit: 100 })
  .post('/api/submit', () => 'Submitted', { rateLimit: 10 })
```

## Macro vs Guard: When to Use Which

| Feature | Macro | Guard |
|---------|-------|-------|
| **Scope** | Opt-in per route via label | Applies to all subsequent routes |
| **Parameters** | Accepts dynamic values (`{ role: 'admin' }`) | No parameters; static config |
| **Composability** | Macros can extend other macros | Guards apply hooks/schema in sequence |
| **Reusability** | Export as plugin, activate per route | Wraps groups of routes |
| **Type inference** | Full type narrowing from resolve | Standard hook type inference |
| **Best for** | Configurable cross-cutting concerns | Blanket policies for route groups |

**Use Macro when** you need per-route configuration (e.g., different roles, rate limits) or want to compose multiple concerns declaratively.

**Use Guard when** you want to apply the same hook or schema to every route in a group without per-route opt-in.
