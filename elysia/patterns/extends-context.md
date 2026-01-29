# Extends Context
ElysiaJS provides mechanisms to extend the Context object for application-specific needs. The framework offers four primary APIs: `state`, `decorate`, `derive`, and `resolve`.

## When to Extend Context

Extension should occur when:
- A property represents shared global mutable state via `state`
- A property associates with requests/responses via `decorate`
- A property derives from existing properties via `derive`/`resolve`

Otherwise, define values separately for better separation of concerns.

## State

Global mutable object shared across the Elysia app, assigned once at call time.

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .state('version', 1)
    .get('/a', ({ store: { version } }) => version)
    .get('/b', ({ store }) => store)
    .listen(3000)
```

**When to use:**
- Sharing primitive mutable values across routes
- For non-primitive wrapper values/classes, use `decorate` instead

**Key points:**
- `store` represents single-source-of-truth global mutable object
- Assign values before using in handlers
- Access via reference to mutate properly

**Reference gotcha:** Destructuring primitives from objects loses the reference link. Use `store.counter++` rather than extracting `counter` separately.

## Decorate

Assigns additional properties directly to Context at call time.

```typescript
import { Elysia } from 'elysia'

class Logger {
    log(value: string) {
        console.log(value)
    }
}

new Elysia()
    .decorate('logger', new Logger())
    .get('/', ({ logger }) => {
        logger.log('hi')
        return 'hi'
    })
```

**When to use:**
- Constant/readonly value objects
- Non-primitive values or classes with internal state
- Additional functions, singletons, immutable properties

**Key points:**
- Should not be mutated (though technically possible)
- Assign before using in handlers

## Derive

Creates new properties from existing Context properties without type validation. Assigned at the **transform** lifecycle (before validation).

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .derive(({ headers }) => {
        const auth = headers['authorization']
        return {
            bearer: auth?.startsWith('Bearer ') ? auth.slice(7) : null
        }
    })
    .get('/', ({ bearer }) => bearer)
```

**When to use:**
- Creating properties from existing ones without validation
- Accessing request properties like headers, query, body

**Key points:**
- Assigned at transform lifecycle (before validation)
- Can access request properties but they are typed as `unknown`
- Use `resolve` for type-safe alternatives

## Resolve

Similar to `derive` but ensures type integrity by executing after validation. Runs at the **beforeHandle** lifecycle.

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
    .guard({
        headers: t.Object({
            bearer: t.String({
                pattern: '^Bearer .+$'
            })
        })
    })
    .resolve(({ headers }) => {
        return {
            bearer: headers.bearer.slice(7)
        }
    })
    .get('/', ({ bearer }) => bearer)
```

**When to use:**
- Creating properties with type checking
- Accessing validated request properties

**Key points:**
- Executes at beforeHandle lifecycle (after validation)
- Request properties are properly typed

## Error Handling in Resolve/Derive

Both can return errors, causing early exit:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .derive(({ headers, status }) => {
        const auth = headers['authorization']
        if(!auth) return status(400)
        return {
            bearer: auth?.startsWith('Bearer ') ? auth.slice(7) : null
        }
    })
    .get('/', ({ bearer }) => bearer)
```

## Assignment Patterns

### Key-value Pattern

```typescript
new Elysia()
    .state('counter', 0)
    .decorate('logger', new Logger())
```

### Object Pattern

```typescript
new Elysia()
    .decorate({
        logger: new Logger(),
        trace: new Trace(),
        telemetry: new Telemetry()
    })
```

### Remap Pattern

Function-based reassignment allowing property transformation:

```typescript
new Elysia()
    .state('counter', 0)
    .state('version', 1)
    .state(({ version, ...store }) => ({
        ...store,
        elysiaVersion: 1
    }))
    .get('/elysia-version', ({ store }) => store.elysiaVersion)
```

**Note:** Remap only assigns initial values. Elysia will treat a returned object as new property, removing missing properties.

## Affix

`prefix` and `suffix` functions enable bulk remapping of plugin properties to avoid naming conflicts:

```typescript
import { Elysia } from 'elysia'

const setup = new Elysia({ name: 'setup' })
    .decorate({
        argon: 'a',
        boron: 'b',
        carbon: 'c'
    })

const app = new Elysia()
    .use(setup)
    .prefix('decorator', 'setup')
    .get('/', ({ setupCarbon }) => setupCarbon)
```

Alternately, remap all properties at once:

```typescript
const app = new Elysia()
    .use(setup)
    .prefix('all', 'setup')
```

Properties are remapped to camelCase by default, handling both runtime and type-level code automatically.
