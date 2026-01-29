# Elysia v0.x Release Archives

Consolidated release notes for Elysia v0.2 through v0.8, extracted from the official blog. Each section covers key features, API changes, breaking changes, and migration notes.

---

## v0.8 - Gate of Steiner

### Key Features

#### Macro API
Define custom fields to hook into and guard the lifecycle event stack with full type safety:

```typescript
const plugin = new Elysia({ name: 'plugin' }).macro(({ beforeHandle }) => {
    return {
        role(type: 'admin' | 'user') {
            beforeHandle(
                { insert: 'before' },
                async ({ cookie: { session } }) => {
                    const user = await validateSession(session.value)
                    await validateRole('admin', user)
                }
            )
        }
    }
})
```

#### Resolve Lifecycle
A "safe" version of derive, designed to append a new value to the context after validation:

```typescript
new Elysia()
    .guard(
        {
            headers: t.Object({
                authorization: t.TemplateLiteral('Bearer ${string}')
            })
        },
        (app) =>
            app
                .resolve(({ headers: { authorization } }) => {
                    return {
                        bearer: authorization.split(' ')[1]
                    }
                })
                .get('/', ({ bearer }) => bearer)
    )
    .listen(3000)
```

#### MapResponse Lifecycle
Executes after `afterHandle`; transforms primitive values into Web Standard Response objects:

```typescript
new Elysia()
    .mapResponse(({ response }) => {
        return new Response(
            gzipSync(
                typeof response === 'object'
                    ? JSON.stringify(response)
                    : response.toString()
            )
        )
    })
    .listen(3000)
```

#### Error Function
Explicit status code return alongside values for improved type inference:

```typescript
import { Elysia, error } from 'elysia'

new Elysia()
    .get('/', () => error(418, "I'm a teapot"))
    .listen(3000)
```

#### Static Content
Determines the response ahead of time for rarely-changed resources. Provides 20-25% performance improvement:

```typescript
new Elysia()
    .get('/', Bun.file('video/kyuukurarin.mp4'))
    .listen(3000)
```

#### Default Property (TypeBox 0.32)
Schema-level default values:

```typescript
new Elysia()
    .get('/', ({ query: { name } }) => name, {
        query: t.Object({
            name: t.String({
                default: 'Elysia'
            })
        })
    })
    .listen(3000)
```

#### Default Header
Set headers that apply to all requests without per-request overhead:

```typescript
new Elysia()
    .headers({
        'X-Powered-By': 'Elysia'
    })
```

### Performance
- Removal of bind: ~5% path lookup speedup
- Static Query Analysis: 15-20% speed-up by default
- Video Stream Support: automatic `content-range` header for File/Blob objects
- Validation errors now returned as JSON with detailed error information

### API Changes
- TypeBox updated to 0.32
- Validation response changed from text to JSON format
- Derive decorator now differentiated as `decorator['derive']` instead of `decorator['request']`

### Breaking Changes
- `afterHandle` no longer triggers early return
- `derive` no longer displays inferred type in `onRequest`
- Removed `headers`, `path`, and `derive` from `PreContext`

### Migration
- Use `error()` function instead of `set.status` for type-safe status codes
- Migrate CORS and cache header logic to `.headers()` for better performance
- Update error handling to expect JSON responses instead of text

---

## v0.7 - Stellar Stellar

### Key Features

#### Rewritten Type System
Entirely rewritten from the ground up, leveraging newer TypeScript features like const generics. Achieves up to 13x faster type inference while reducing the type codebase by over a thousand lines.

#### Trace (Declarative Telemetry)
Performance auditing and bottleneck identification using AoT compilation and Dynamic Code injection to eliminate overhead when unused.

#### Reactive Cookie Model
Modern signal-based approach merged into core:

```typescript
app.get('/', ({ cookie: { name } }) => {
    // Get
    name.value

    // Set
    name.value = "New Value"
})
```

Cookie jar automatically syncs with headers and only sends `Set-Cookie` when values change.

**Cookie Schema & Validation:**
```typescript
app.get('/', ({ cookie: { name } }) => {
    name.value = {
        id: 617,
        name: 'Summoning 101'
    }
}, {
    cookie: t.Cookie({
        value: t.Object({
            id: t.Numeric(),
            name: t.String()
        })
    })
})
```

**Cookie Signature with Secret Rotation:**
```typescript
new Elysia({
    cookie: {
        secrets: ['Vengeance will be mine', 'Fischl von Luftschloss Narfidort']
    }
})
```

Automatically signs with first secret, validates against all.

#### TypeBox 0.31 - Decode/Encode Support
New `t.ObjectString` for multipart/formdata:

```typescript
new Elysia()
    .post('/', ({ body: { data: { name } } }) => name, {
        body: t.Object({
            image: t.File(),
            data: t.ObjectString({
                name: t.String()
            })
        })
    })
```

#### Rewritten WebSocket
- Strictly validates schema
- Type inference synced automatically
- Removes need for `.use(ws())` in plugins
- Performance near native Bun WebSocket

#### Definitions Remap & Affix
Prevent name collision when composing plugins:

```typescript
// Remap: rename properties during plugin composition
new Elysia()
    .use(
        plugin.decorate(({ logger, ...rest }) => ({
            pluginLogger: logger,
            ...rest
        }))
    )

// Affix: bulk prefix/suffix
const app = new Elysia()
    .use(
        setup.prefix('decorator', 'setup')
    )
    .get('/', ({ setupCarbon }) => setupCarbon)
```

#### True Encapsulation Scope
Scoped instances truly encapsulate at runtime and type-level:

```typescript
const plugin = new Elysia({ scoped: true, prefix: '/hello' })
    .onRequest(() => {
        console.log('In Scoped')
    })
    .get('/', () => 'hello')

const app = new Elysia()
    .use(plugin)
    // 'In Scoped' will NOT log on main instance
    .get('/', () => 'Hello World')
```

#### Text-Based HTTP Status Codes
```typescript
return { status: 'I\'m a teapot' }  // Resolves to 418
```

Includes 64 standard HTTP status codes with IDE autocompletion.

### API Changes
- `onRequest` accepts async functions
- `onError` receives `Context` parameter
- Lifecycle hooks accept array of functions
- `t.File` and `t.Files` changed from `Blob` to `File` type
- Dynamic routes split into single pipeline (reduced memory usage)

### Breaking Changes
1. Removed `ws` plugin -- WebSocket functionality migrated to core
2. Renamed `addError` to `error`
3. Removed array routes (caused TypeScript issues)
4. `Type.ElysiaMeta` rewrite -- now uses TypeBox.Transform

---

## v0.6 - This Game

### Key Features

#### New Plugin Model
Elysia instances can now be directly used as plugins:

```typescript
// Old callback pattern
const plugin = (app: Elysia) => app.get('/', () => 'hello')

// New instance pattern
const plugin = new Elysia()
    .get('/', () => 'hello')

// Nested groups simplified
const group = new Elysia({ prefix: '/v1' })
    .get('/hello', () => 'Hello World')
```

#### Plugin Checksum
Automatically deduplicates plugins registered multiple times:

```typescript
const plugin = new Elysia({
    name: 'plugin'
})

// With configuration
const plugin = (config) => new Elysia({
    name: 'plugin',
    seed: config
})
```

#### Mount & WinterCG Compliance
Run multiple WinterCG-compliant frameworks in one codebase:

```typescript
const app = new Elysia()
    .get('/', () => 'Hello from Elysia')
    .mount('/hono', hono.fetch)

// Reuse multiple projects
import A from 'project-a/elysia'
import B from 'project-b/elysia'
new Elysia()
    .mount(A)
    .mount(B)
```

#### Dynamic Mode
JIT compilation for environments like Cloudflare Workers:

```typescript
new Elysia({
    aot: false
})
```

Provides up to 6x faster startup times but disables AOT-dependent features like `t.Numeric` auto-parsing.

#### Declarative Custom Error
Type-safe custom error handling with auto-completion and type narrowing:

```typescript
class CustomError extends Error {
    constructor(public message: string) {
        super(message)
    }
}

new Elysia()
    .addError({
        MyError: CustomError
    })
    .onError(({ code, error }) => {
        switch(code) {
            case 'MyError':
                return error  // typed as CustomError
        }
    })
```

#### Loose Path Matching
Paths now match with or without trailing slashes by default.

#### onResponse Lifecycle Hook
Fires for all responses including errors (unlike `onAfterHandle` which only fires on success).

### Performance
- OpenAPI schema compilation deferred to `@elysiajs/swagger`, improving startup ~35%
- Startup time ~78ms for 10,000 routes
- TypeBox upgraded to 0.30 with utility types: `t.Awaited`, `t.Uppercase`, `t.Capitlized`
- Bun build targeting improves performance 5-10%

### Breaking Changes
- Removed Elysia Symbol (internal)
- Refactored `getSchemaValidator` and `getResponseSchemaValidator` to named parameters
- Moved `registerSchemaPath` to `@elysiajs/swagger`

### Migration
- Convert callback-based plugins to Elysia instances for checksum benefits
- Install `@elysiajs/swagger` for OpenAPI schema registration
- Verify routes with new loose trailing slash matching
- Migrate logging from `onAfterHandle` to `onResponse` for complete coverage

---

## v0.5 - Radiant

### Key Features

#### Static Code Analysis
Reads function handlers and schemas to optimize compilation ahead of time. Detects which properties are actually used and skips parsing for unused ones.

Performance improvements: overall ~15%, static router ~33%, empty query parsing ~50%, strict type body parsing ~100%, empty body parsing ~150%.

```typescript
// Body parsing skipped since only params.id is used
app.post('/id/:id', ({ params: { id } }) => id, {
    body: t.Object({
        username: t.String(),
        password: t.String()
    })
})
```

#### New Router: Memoirist
Replaces "Raikiri" router with stable Radix Tree algorithm based on Medley Router, with Ahead of Time compilation for static routes.

#### TypeBox 0.28 - Template Literals
```typescript
new Elysia()
    .model(
        'name',
        Type.TemplateLiteral([
            Type.Literal('Elysia '),
            Type.Union([
                Type.Literal('The Blessing'),
                Type.Literal('Radiant')
            ])
        ])
    )
```

#### Numeric Type
Automatically parses numeric strings at runtime and type level:

```typescript
// v0.4: required manual transform
// v0.5: automatic
app.get('/id/:id', ({ params: { id } }) => id, {
    params: t.Object({
        id: t.Numeric()
    })
})
```

Usable on params, query, headers, body, response.

#### Inline Schema Syntax
Schema definitions moved from nested `schema` property to inline:

```typescript
// Old
app.get('/', handler, {
    schema: {
        params: t.Object({ id: t.Number() })
    }
})

// New
app.get('/', handler, {
    params: t.Object({ id: t.Number() })
})
```

#### Unified API for state, decorate, model
All three support single or multiple value setting:

```typescript
const app = new Elysia()
    .model('string', t.String())
    .model({
        number: t.Number()
    })
    .state('visitor', 1)
    .state({
        multiple: 'value',
        are: 'now supported!'
    })
    .decorate('visitor', 1)
    .decorate({
        name: 'world',
        number: 2
    })
```

#### Enhanced Group with Guard
Optional second parameter adds guard scope to `.group()`:

```typescript
app.group(
    '/v1', {
        body: t.Literal('Rikuhachima Aru')
    },
    app => app.get('/student', () => 'Rikuhachima Aru')
)
```

### Breaking Changes
1. `innerHandle` renamed to `fetch`
2. `setModel` renamed to `model`
3. Remove `hook.schema` wrapper -- move schema properties to hook level
4. Removed `mapPathnameRegex` (internal)

### Migration
- Rename `.innerHandle` to `.fetch`
- Rename `setModel` to `model`
- Move schema properties out of the `schema` wrapper object

---

## v0.4 - Moonlit Night Concert

### Key Features

#### Ahead of Time Compilation (AOT)
Replaces runtime conditional checking with compile-time analysis. Generates optimized functions per route, analyzing whether async is needed to reduce overhead.

#### TypeBox 0.26
- `Not` type support
- `Convert` for coercion values
- `Error.First()` method reducing error iteration overhead

#### Per-Status Response Validation
Responses validated strictly per HTTP status code:

```typescript
app.post('/strict-status', process, {
    schema: {
        response: {
            200: t.String(),
            400: t.Number()
        }
    }
})
```

#### Conditional Routes with `.if()`
Declarative conditional route/plugin registration:

```typescript
const isProduction = process.env.NODE_ENV === 'production'
const app = new Elysia().if(!isProduction, (app) =>
    app.use(swagger())
)
```

#### Custom Validation Error Handling
Access TypeBox error properties for programmatic error responses:

```typescript
new Elysia()
    .onError(({ code, error, set }) => {
        if (code === 'VALIDATION') {
            set.status = 400
            return {
                fields: error.all()
            }
        }
    })
```

### Breaking Changes
**Separation of Elysia Fn** - Must explicitly install `@elysiajs/fn`. The superjson dependency represented 38% of Elysia's bundle size. No code changes required beyond the separate installation.

---

## v0.3 - Edge of Ground

### Key Features

#### Elysia Fn (RPC-like)
Frontend calls to backend functions with full type-safety, autocompletion, original code comments, and click-to-definition. Uses JavaScript Proxy to capture object properties and batch requests. Performance: 1.2 million operations/second (M1 Max). Includes permission system with scope limiting and authorization.

#### Type System Rework
6.5-9x faster type checking. 80% of Elysia and Eden types rewritten. Type declaration size reduced 50-99%. Routes compile to literal objects instead of TypeBox references. 350 routes with complex types compiles in only 0.22 seconds.

#### File Upload Support
`Elysia.t` extends TypeBox with `File` and `Files` validators. Supports validation for file type, min/max file size, and total files per field.

#### OpenAPI 3.0.x Migration
Updated from OpenAPI 2.x specification.

#### Eden Rework
Three export variants:
- **Eden Treaty** (`eden/treaty`): Original syntax
- **Eden Fn** (`eden/fn`): Elysia Fn access
- **Eden Fetch** (`eden/fetch`): Fetch-like syntax for 1,000+ route applications

### Breaking Changes
1. `inject` renamed to `derive`
2. `derive` function removed
3. `ElysiaRoute` changed to inline compilation
4. `context.store[SYMBOL]` moved to `meta[SYMBOL]`
5. OpenAPI version upgrade from 2.x to 3.0.3

---

## v0.2 - The Blessing

### Key Features

#### Deferred/Lazy Loading Modules
Async plugin registration and module lazy-loading for serverless environments:

```typescript
const plugin = async (app: Elysia) => {
    const stuff = await doSomeHeavyWork()
    return app.get('/heavy', stuff)
}
app.use(plugin)

// Lazy loading
app.use(import('./some-heavy-module'))
```

Full type inference available with deferred plugins.

#### Reference Model System
Memorize schemas via `setModel()` and reference them by name:

```typescript
const app = new Elysia()
    .setModel({
        sign: t.Object({
            username: t.String(),
            password: t.String()
        })
    })
    .post('/sign', ({ body }) => body, {
        schema: {
            body: 'sign',
            response: 'sign'
        }
    })
```

#### OpenAPI Detail Field
New `schema.detail` field for customizing route documentation following OpenAPI Schema V2.

#### Union Response Types
Define multiple response statuses with different schemas:

```typescript
app.post('/json/:id', ({ body, params: { id } }) => ({...body, id}), {
    schema: {
        body: 'sign',
        response: {
            200: t.Object({
                username: t.String(),
                password: t.String(),
                id: t.String()
            }),
            400: t.Object({ error: t.String() })
        }
    }
})
```

### Notable Improvements
- `onRequest` and `onParse` now access `PreContext`
- Default support for `application/x-www-form-urlencoded`
- Body parser handles `content-type` with extra attributes
- URI path parameters are decoded

### Breaking Changes
**`onParse` Signature Change:**
- Old: `(request: Request, contentType: string)`
- New: `(context: PreContext, contentType: string)`
- Migration: Add `.request` to context to access the Request object
