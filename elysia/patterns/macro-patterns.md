# Macro Patterns
Pattern-level guide for using macros in ElysiaJS. Macros provide control over lifecycle events, schemas, and context with full type safety. See also `references/macro.md` for the core API reference.

## Basic Implementation

Define a macro inside a plugin with `.macro()`, then activate it via property assignment on a route:

```typescript
import { Elysia } from 'elysia'

const plugin = new Elysia({ name: 'plugin' })
    .macro({
        hi: (word: string) => ({
            beforeHandle() {
                console.log(word)
            }
        })
    })

const app = new Elysia()
    .use(plugin)
    .get('/', () => 'hi', {
        hi: 'Elysia'
    })
```

## Property Shorthand (v1.2.10+)

Macro properties can be either a function or an object. Object syntax translates to a boolean parameter — the macro executes when set to `true`:

```typescript
export const auth = new Elysia()
    .macro({
        isAuth: {
            resolve: () => ({
                user: 'saltyaom'
            })
        }
    })
```

## Error Handling

Return HTTP status codes with the `status` function instead of throwing errors. This preserves proper type inference for Eden and OpenAPI:

```typescript
new Elysia()
    .macro({
        auth: {
            resolve({ headers }) {
                if (!headers.authorization)
                    return status(401, 'Unauthorized')

                return { user: 'SaltyAom' }
            }
        }
    })
    .get('/', ({ user }) => `Hello ${user}`, {
        auth: true
    })
```

## Resolve Pattern

Add computed properties to the handler context by returning a `resolve` function:

```typescript
new Elysia()
    .macro({
        user: (enabled: true) => ({
            resolve: () => ({
                user: 'Pardofelis'
            })
        })
    })
    .get('/', ({ user }) => user, {
        user: true
    })
```

Use cases: authentication, database queries, and injecting derived context values.

### Named Single Macro

For proper TypeScript inference when extending macros with resolve, use named syntax:

```typescript
new Elysia()
    .macro('user', {
        resolve: () => ({
            user: 'lilith' as const
        })
    })
    .macro('user2', {
        user: true,
        resolve: ({ user }) => {
        }
    })
```

## Schema Definition

Macros can declare custom validation schemas:

```typescript
new Elysia()
    .macro({
        withFriends: {
            body: t.Object({
                friends: t.Tuple([t.Literal('Fouco'), t.Literal('Sartre')])
            })
        }
    })
    .post('/', ({ body }) => body.friends, {
        body: t.Object({
            name: t.Literal('Lilith')
        }),
        withFriends: true
    })
```

Multiple macro schemas stack seamlessly alongside standard validation.

### Lifecycle in Named Macros

Named single macros support lifecycle type inference:

```typescript
new Elysia()
    .macro('withFriends', {
        body: t.Object({
            friends: t.Tuple([t.Literal('Fouco'), t.Literal('Sartre')])
        }),
        beforeHandle({ body: { friends } }) {
        }
    })
```

## Extension (Macro Composition)

Macros can reference other macros to build composite functionality:

```typescript
new Elysia()
    .macro({
        sartre: {
            body: t.Object({
                sartre: t.Literal('Sartre')
            })
        },
        fouco: {
            body: t.Object({
                fouco: t.Literal('Fouco')
            })
        },
        lilith: {
            fouco: true,
            sartre: true,
            body: t.Object({
                lilith: t.Literal('Lilith')
            })
        }
    })
    .post('/', ({ body }) => body, {
        lilith: true
    })
```

## Deduplication

Elysia prevents duplicate lifecycle execution automatically. Property values seed deduplication by default, but custom seeds are supported:

```typescript
.macro({
    sartre: (role: string) => ({
        seed: role,
        body: t.Object({
            sartre: t.Literal('Sartre')
        })
    })
})
```

The framework enforces a 16-stack limit to prevent circular dependencies in both runtime and type inference.
