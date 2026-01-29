# Elysia v1.x Release Archives

Consolidated release notes for Elysia v1.0 through v1.4, extracted from the official blog. Each section covers key features, API changes, breaking changes, and migration notes.

---

## v1.4 - Supersymmetry

### Key Features

#### Standard Schema Support
Elysia now supports multiple validators through the Standard Schema specification, moving beyond exclusive TypeBox dependence. Supported validators include Zod, Valibot, Effect Schema, ArkType, and Joi.

```typescript
import { Elysia, t } from 'elysia'
import { z } from 'zod'
import * as v from 'valibot'

const app = new Elysia()
  .post(
    '/user/:id',
    ({ body, params }) => {
      body
      params
    },
    {
      params: z.object({
        id: z.coerce.number()
      }),
      body: v.object({
        name: v.literal('lilith')
      })
    })
```

Different validators can be mixed in a single route with proper type inference.

#### Standalone Validator
Validate single inputs using multiple schemas simultaneously. Each validator parses input segments separately; results merge into unified output.

```typescript
import { Elysia, t } from 'elysia'
import { z } from 'zod'
import * as v from 'valibot'

const app = new Elysia()
  .guard({
    schema: 'standalone',
    body: z.object({
      id: z.coerce.number()
    })
  })
  .post(
    '/user/:id',
    ({ body }) => body,
    {
      body: v.object({
        name: v.literal('lilith')
      })
    }
  )
```

#### OpenAPI Generation
- Native validator support via `mapJsonSchema` for custom OpenAPI mapping
- Zod's native OpenAPI schema integration with `describe` method
- OpenAPI Type Generation produces all possible output types including error responses
- Works with all Standard Schema-compatible validators

#### Macro Enhancements
- **Macro Schema**: Define custom validation directly within macros with automatic type inference. Supports schema stacking across multiple macros.
- **Macro Extension**: Extend existing macros with recursive extension and automatic deduplication. Circular dependency protection with a 16-level stack limit.
- **Macro Detail (OpenAPI)**: Define OpenAPI documentation directly in macros. Route details take precedence over macro details when merged.

#### Lifecycle Type Soundness
Complete type inference for all lifecycle events and macros. Refactored 3,000+ lines of pure types with type-level unit tests for all lifecycle APIs. Improved type inference performance by 9-11% and reduced type instantiation by 11.57%.

#### Group Standalone Schema
Groups now use standalone strategy (coexists with route schema) instead of the previous overwrite strategy. Define schemas in groups without manual schema replication.

### API Changes
- **HEAD Method**: Automatically added when GET routes are defined
- **NoValidate**: Now supports reference models
- **ObjectString/ArrayString**: No longer produce default values (security improvement)
- **Cookie parsing**: Dynamically parses when format appears JSON
- **Export**: `fileType` exported for external file type validation

### Breaking Changes
1. **Macro v1 removal** - Eliminated due to lack of type soundness
2. **`error` function removal** - Use `status` instead
3. **`response` deprecation** - In `mapResponse` and `afterResponse` lifecycle events; use `responseValue` instead

### Migration
- Update `error()` calls to `status()` API
- Replace `response` parameter with `responseValue` in response-related lifecycle hooks
- Remove deprecated macro v1 implementations
- No migration required for Standard Schema adoption -- existing TypeBox code continues functioning

---

## v1.3 - Scientific Witchery

### Key Features

#### Exact Mirror
Replacement for TypeBox's `Value.Clean` with ahead-of-time compilation for dramatically faster normalization. Small objects run ~500x faster, medium/large objects ~30x faster, with overall ~1.5x throughput improvement.

```typescript
import { Elysia } from 'elysia'

new Elysia({
    normalize: 'typebox' // Opt into TypeBox instead of Exact Mirror
})
```

#### Bun System Router
Dual router strategy using Bun's native router when possible, falling back to Elysia's router. Dynamic routes show 2-5% faster performance without code changes.

#### Standalone Validator
Allows combining schemas instead of overriding them in guards.

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .guard({
        schema: 'standalone',
        response: t.Object({
            title: t.String()
        })
    })
```

#### Enhanced Type System
Reduced type instantiation by 50% in most cases, with up to 60% improvement in inference speed. Changed `decorate` behavior to use intersection instead of recursive loops.

#### Validation DX Improvements

**encodeSchema** - Now enabled by default. Enables `t.Transform` for custom response mapping.

**Sanitize Option** - Intercepts every `t.String` for SQL injection/XSS prevention.

**t.Form Type** - New type for FormData validation at compile time, replacing `t.Object` in response schemas.

```typescript
response: t.Form({
    title: t.String()
})
```

**File Type Validation** - Uses `file-type` library to validate by magic number (listed as peerDependency).

```typescript
t.File({ type: ['image/png'] })
```

**Elysia.Ref** - Reference models with auto-completion inside schemas.

**t.NoValidate** - Skip runtime validation while preserving TypeScript types and OpenAPI schema.

```typescript
response: t.NoValidate(t.Object({
    data: t.String()
}))
```

#### Performance Optimizations
- Route registration: 5.6x reduced memory usage, 2.7x faster registration time
- Instance creation: 10x reduced memory usage, 3x faster plugin creation
- Sucrose cache: checksum-based caching for compiled routes
- Up to 40% faster request processing speed

### API Changes

**Status Instead of Error** - `error` function deprecated; replaced with `status`:

```typescript
// Old
error(code, data)

// New
status(code, data)
```

**Removed ".index" from Treaty** - Direct method calls replace `.index` for root paths:

```typescript
// Old
treaty.index.get()

// New
treaty.get()
```

### Breaking Changes
1. Remove `as('plugin')` in favor of `as('scoped')`
2. Root `index` removed from Eden Treaty
3. Remove `websocket` from `ElysiaAdapter`
4. Remove `inference.request`

### Migration
- Rename `as('plugin')` to `as('scoped')`
- Bulk find-and-replace `.index` removal in Eden Treaty usage
- `error()` remains supported for ~6 months, migrate to `status()` at your pace

---

## v1.2 - You and Me

### Key Features

#### Adapter System
Run Elysia across multiple runtimes with a consistent API. Supports Bun (primary), Web Standard/WinterCG (Deno, Browser), and Node.js (beta).

```typescript
import { node } from '@elysiajs/node'

new Elysia({ adapter: node() })
    .get('/', 'Hello Node')
    .listen(3000)
```

#### Universal Runtime API
Consistent utility functions across runtimes:

```typescript
import { Elysia, file } from 'elysia'

new Elysia()
    .get('/', () => file('./public/index.html'))
```

- `file()` - Return file responses
- `form()` - Return FormData responses
- `server` - Type declaration port of Bun's Server

#### Macro with Resolve
Object-based macro syntax supporting `resolve` lifecycle:

```typescript
new Elysia()
    .macro({
        user: (enabled: true) => ({
            resolve: ({ cookie: { session } }) => ({
                user: session.value!
            })
        })
    })
    .get('/', ({ user }) => user, {
        user: true
    })
```

Note: macro's `resolve` only works with the new object syntax due to TypeScript limitations.

#### Named Parser
Custom-named parsers with explicit selection per route:

```typescript
new Elysia()
    .parser('custom', ({ contentType }) => {
        if(contentType === "application/kivotos")
            return 'nagisa'
    })
    .post('/', ({ body }) => body, {
        parse: 'custom'
    })
```

Multiple parsers can be chained: `parse: ['custom', 'json']`

#### WebSocket Rewrite
Updated API matching Bun's latest WebSocket specification:

```typescript
new Elysia()
    .ws('/ws', {
        ping: (message) => message,
        pong: (message) => message
    })
```

#### TypeBox 0.34 Support
Enables circular recursive types via `t.Module`:

```typescript
new Elysia()
    .model({
        a: t.Object({
            a: t.Optional(t.Ref('a'))
        })
    })
    .post('/recursive', ({ body }) => body, {
        body: 'a'
    })
```

#### Memory Optimization
Up to 2x memory reduction from v1.1 through refactored Sucrose code generation.

### API Changes
- Eden validation errors: automatic `422` status code inference
- Router deduplication via checksum hash map
- Event listeners auto-infer path parameters based on scope
- Cookie updated to 1.0.1, TypeBox to 0.33
- `content-length` accepts number type
- Production builds disable minify for better debugging

### Breaking Changes
1. **Parse type consolidation** - `type` merged into `parse` parameter:
   ```typescript
   // Old: type: 'json'
   // New: parse: 'json'
   ```
2. **FormData response** - Must explicitly return `form()`:
   ```typescript
   import { form, file } from 'elysia'
   new Elysia()
       .post('/', ({ file }) => form({
           a: file('./public/kyuukurarin.mp4')
       }))
   ```
3. **WebSocket method chaining removed** - Methods return values instead of WebSocket instance
4. **Constructor `scoped` removed** - Use mounting instead

### Migration
- Replace `type:` with `parse:` in route options
- Wrap FormData responses in `form()` explicitly
- Remove WebSocket method chaining (call methods separately)
- Replace `new Elysia({ scoped: false })` with `mount()` pattern

---

## v1.1 - Grown-up's Paradise

### Key Features

#### OpenTelemetry Support
First-party OpenTelemetry integration without monkey patching:

```typescript
import { Elysia } from 'elysia'
import { opentelemetry } from '@elysiajs/opentelemetry'
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-node'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-proto'

new Elysia()
    .use(
        opentelemetry({
            spanProcessors: [
                new BatchSpanProcessor(
                    new OTLPTraceExporter()
                )
            ]
        })
    )
```

Custom span recording:

```typescript
import { record } from '@elysiajs/opentelemetry'

export const plugin = new Elysia()
    .get('', () => {
        return record('database.query', () => {
            return db.query('SELECT * FROM users')
        })
    })
```

Use named functions instead of arrow functions for better trace readability.

#### Trace v2
Complete rewrite with synchronous behavior and microsecond accuracy via ahead-of-time compilation:

```typescript
new Elysia()
    .trace(({ onBeforeHandle, set }) => {
        onBeforeHandle(({ onEvent }) => {
            onEvent(({ onStop, name }) => {
                onStop(({ elapsed }) => {
                    console.log(name, 'took', elapsed, 'ms')
                    set.headers['x-trace'] = 'true'
                })
            })
        })
    })
```

#### Data Normalization
Ensures data consistency by coercing input to schema shape, removing extra fields, and filtering response fields:

```typescript
const app = new Elysia()
    .post('/', ({ body }) => body, {
        body: t.Object({
            name: t.String(),
            point: t.Number()
        }),
        response: t.Object({
            name: t.String()
        })
    })

// Extra 'title' field removed from input, 'point' filtered from response
// Result: { name: 'SaltyAom' }
```

#### Automatic Data Type Coercion
Replaces explicit `t.Numeric` with automatic coercion for `t.Number`, `t.Boolean`, `t.Object`, and `t.Array`:

```typescript
// Before (v1.0): t.Numeric() required
// After (v1.1): t.Number() auto-coerces strings
const app = new Elysia()
    .get('/', ({ query }) => query, {
        query: t.Object({
            page: t.Number()  // auto-coerces from string
        })
    })
```

#### Guard `as` Property
Apply guards as `scoped` or `global`:

```typescript
const plugin = new Elysia()
    .guard({
        as: 'scoped',
        beforeHandle() {
            console.log('called')
        }
    })
    .get('/plugin', () => 'ok')
```

#### Bulk `as` Casting
Lift all hooks and schemas from one scope level to parent:

```typescript
// v1.0 - explicit as on each hook
const from = new Elysia()
    .guard({ response: t.String() })
    .onBeforeHandle({ as: 'scoped' }, () => { console.log('called') })
    .onAfterHandle({ as: 'scoped' }, () => { console.log('called') })

// v1.1 - bulk cast
const to = new Elysia()
    .guard({ response: t.String() })
    .onBeforeHandle(() => { console.log('called') })
    .onAfterHandle(() => { console.log('called') })
    .as('plugin')
```

#### Response Status Reconciliation
Merges response schemas across scopes by status code instead of preferring one scope's schema.

#### Optional Path Parameters
Support for optional segments using `?` suffix:

```typescript
new Elysia()
    .get('/ok/:id?', ({ params: { id } }) => id)
// /ok/1 returns 1, /ok returns undefined

// With schema default:
new Elysia()
    .get('/ok/:id?', ({ params: { id } }) => id, {
        params: t.Object({
            id: t.Number({ default: 1 })
        })
    })
```

#### Generator Response Streaming
Native streaming via generator functions with Eden type inference and automatic cleanup on cancel:

```typescript
const app = new Elysia()
    .get('/ok', function* () {
        yield 1
        yield 2
        yield 3
    })

// Eden client with type inference:
const { data, error } = await treaty(app).ok.get()
if (error) throw error
for await (const chunk of data)
    console.log(chunk)
```

### API Changes
- `onResponse` renamed to `onAfterResponse`
- Query values parse as string for all validators unless explicitly specified
- Added auto-complete for `set.headers`
- `server` property added to context
- `mapResponse` now called in error event
- `onError` supports array of functions
- Added `route` to context
- ~36% memory reduction for route registration

### Breaking Changes
1. **Trace v2** - Complete replacement of Trace v1 API
2. **`onResponse` renamed to `onAfterResponse`**
3. **Query string parsing** - All validators parse as string by default
4. **Removed**: `$passthrough` (use `toResponse`), static query analysis

### Migration
- Switch from Trace v1 event-based to Trace v2 callback pattern
- Rename `onResponse` to `onAfterResponse`
- Replace `@elysiajs/stream` with native generator functions:
  ```typescript
  // Old: .get('/ok', stream(async function*() { ... }))
  // New: .get('/ok', function*() { ... })
  ```
- Simplify `t.Numeric()` to `t.Number()` (auto-coercion now applied)

---

## v1.0 - Lament of the Fallen

### Key Features

#### Sucrose - Pattern Matching Static Analysis
Rewrote the static analysis engine from RegEx-based to hybrid AST/pattern-matching approach. Achieves up to 37% faster inference time with significantly reduced memory usage.

#### Improved Startup Time
Lazy evaluation of compilation phase on first route match with caching. Results in 6.5-14x faster startup time in medium-sized applications.

#### Removed ~40 Routes/Instance TypeScript Limit
Previously hit TypeScript's type instantiation depth error around 40 routes. Now supports up to ~558 routes per instance.

#### Type Inference Performance
- Up to ~82% improvement in most servers
- Up to 13x faster for Eden Treaty
- Overall Elysia + Eden Treaty: up to ~3.9x faster
- Stress test (450 routes): 0.8 took ~1500ms, v1.0 took ~400ms

#### Treaty 2
End-to-end type safety redesign with more ergonomic syntax (no "$" prefix), unit test support, and interceptors:

```typescript
import { Elysia } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia().get('/hello', () => 'hi')
const api = treaty(app)

describe('Elysia', () => {
    it('return a response', async () => {
        const { data } = await api.hello.get()
        expect(data).toBe('hi')
    })
})
```

#### Hook Type System
Lifecycle hooks now support scope specification with `{ as: hookType }`:

```typescript
const plugin = new Elysia()
    .onBeforeHandle({ as: 'global' }, () => {
        console.log('hi')
    })
    .get('/child', () => 'log hi')
```

Three hook types:
| Type | child | current | parent | main |
|------|-------|---------|--------|------|
| `'local'` (default) | yes | yes | no | no |
| `'scoped'` | yes | yes | yes | no |
| `'global'` | yes | yes | yes | yes |

#### Inline Error Function
Fine-grained type narrowing for error responses:

```typescript
new Elysia()
    .get('/hello', ({ error }) => {
        if(Math.random() > 0.5) return error(418, 'Nagisa')
        return 'Azusa'
    }, {
        response: t.Object({
            200: t.Literal('Azusa'),
            418: t.Literal('Nagisa')
        })
    })
```

### API Changes
- `Elysia.routes` moved to `Elysia.router.history`
- Validation errors return JSON instead of string
- Unknown responses returned as-is instead of `JSON.stringify()`
- Fine-grained reactive cookies
- Added `mapResolve` utility
- Added ephemeral type for scope narrowing
- `Elysia._types` utility for type inference
- Macro support for WebSocket
- `t.Date` accepts stringified dates

### Breaking Changes
Hooks changed from global-by-default to local-by-default:

```typescript
// Elysia 0.8 (global by default)
new Elysia()
    .onBeforeHandle(() => "A")

// Elysia 1.0 (local by default, explicit global)
new Elysia()
    .onBeforeHandle({ as: 'global' }, () => "A")
```

### Migration
- Add `{ as: 'global' }` to hooks that need global scope
- Migration typically takes 5-15 minutes
- Update `Elysia.routes` references to `Elysia.router.history`
