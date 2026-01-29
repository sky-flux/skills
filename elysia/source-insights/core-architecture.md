# ElysiaJS Core Architecture

Source: `elysiajs/elysia` repository

## Source Directory Structure

```
src/
  adapter/           # Runtime adapters (Bun, Web Standard, Cloudflare Worker)
    bun/             # Bun-specific handler, native static handler, compose
    cloudflare-worker/
    web-standard/    # Web Standard fallback adapter
    types.ts         # ElysiaAdapter interface definition
    utils.ts         # Shared adapter utilities (tee, etc.)
  type-system/       # TypeBox type extensions (t.File, t.Numeric, etc.)
  universal/         # Cross-runtime abstractions (env, server, utils)
  ws/                # WebSocket types and handlers
  index.ts           # Main Elysia class (~8,300 lines)
  compose.ts         # JIT handler compiler (composeHandler, composeGeneralHandler, composeErrorHandler)
  sucrose.ts         # Static analysis engine for handler functions
  context.ts         # Request context type definitions
  trace.ts           # Lifecycle tracing system
  cookies.ts         # Cookie parsing and signing
  dynamic-handle.ts  # Non-AOT dynamic handler creation
  error.ts           # Error types (ValidationError, NotFoundError, ParseError, etc.)
  schema.ts          # Schema validation utilities (getSchemaValidator, getCookieValidator)
  types.ts           # Core TypeScript type definitions
  utils.ts           # Shared utilities (mergeHook, checksum, mergeLifeCycle, etc.)
  parse-query.ts     # Query string parsing
  replace-schema.ts  # Schema coercion (coercePrimitiveRoot, coerceFormData)
  formats.ts         # Custom format validators
  manifest.ts        # Build manifest support
```

## The Elysia Class

The main `Elysia` class in `src/index.ts` is the central API surface. It is generic over 7 type parameters that encode the full application state at the type level:

```typescript
export default class Elysia<
  const in out BasePath extends string = '',
  const in out Singleton extends SingletonBase = { decorator: {}, store: {}, derive: {}, resolve: {} },
  const in out Definitions extends DefinitionBase = { typebox: {}, error: {} },
  const in out Metadata extends MetadataBase = { schema: {}, macro: {}, macroFn: {}, parser: {}, response: {} },
  const in out Routes extends RouteBase = {},
  const in out Ephemeral extends EphemeralType = { derive: {}, resolve: {}, schema: {}, response: {} },
  const in out Volatile extends EphemeralType = { derive: {}, resolve: {}, schema: {}, response: {} }
>
```

### Key Properties

- **router**: Uses `Memoirist` trie-based router with three layers:
  - `http`: Main parametric/wildcard router (lazy-initialized)
  - `dynamic`: Non-AOT router (for dynamic route registration)
  - `static`: Object map for exact-match static routes
  - `response`: Native static response map (Bun `Response.clone()` optimization)
  - `history`: Array of all registered `InternalRoute` records

- **singleton**: Stores `decorator`, `store`, `derive`, and `resolve` values shared across requests
- **definitions**: TypeBox module registry and error type map
- **validator**: Three-layer validator (global, scoped, local) with `getCandidate()` merge
- **event**: Partial lifecycle store for registered hooks
- **inference**: Sucrose inference flags (body, cookie, headers, query, set, server, path, route, url)

### Constructor

The constructor merges user config with defaults:
- `aot`: Defaults to `true` unless `ELYSIA_AOT=false` env var
- `nativeStaticResponse`: `true` (enables Bun static response optimization)
- `normalize`: `true` (normalizes schema output)
- **Adapter selection**: Uses `BunAdapter` if `typeof Bun !== 'undefined'`, otherwise `WebStandardAdapter`

## Request Processing Pipeline

### Lifecycle Hooks (in order)

1. **request** - Runs before anything else, receives raw request
2. **parse** - Body parsing (JSON, text, urlencoded, formdata, arrayBuffer, custom parsers)
3. **transform** - Transform request context before validation
4. **beforeHandle** - Guard logic, authentication checks (can short-circuit with early return)
5. **handle** - Main route handler
6. **afterHandle** - Post-handler transformation of response
7. **mapResponse** - Maps handler return value to a Response object
8. **afterResponse** - Runs after response is sent (cleanup, logging)
9. **error** - Error handler (catches errors from any prior step)

### Route Registration Flow (`add()` method)

1. Apply macros to local hooks via `applyMacro(localHook)`
2. Merge validator layers (global + scoped + local)
3. Check `shouldPrecompile` flag to decide AOT vs lazy compilation
4. Register route in `router.http` trie and `router.static` map
5. For static values (non-function handlers), attempt native static handler via adapter
6. Create lazy `compile()` closure that calls `composeHandler()` on first invocation
7. Store route in `router.history` for introspection

### `compile()` Method

Called before `listen()` or when the app needs to finalize its routing:

```typescript
compile() {
    this['~adapter'].beforeCompile?.(this)
    if (this['~adapter'].isWebStandard) {
        this._handle = this.config.aot
            ? composeGeneralHandler(this)
            : createDynamicHandler(this)
        // Sets this.fetch to the compiled handler
    }
    return this
}
```

### `fetch` Property

The main entry point for handling requests. Lazily compiled on first access:

```typescript
get fetch(): (request: Request) => MaybePromise<Response> {
    const fetch = this.config.aot
        ? composeGeneralHandler(this)    // JIT-compiled handler
        : createDynamicHandler(this)      // Interpreted fallback
    Object.defineProperty(this, 'fetch', { value: fetch, configurable: true, writable: true })
    return fetch
}
```

### `listen()` Method

Delegates to the adapter's listen implementation:

```typescript
listen = (options, callback) => {
    this['~adapter'].listen(this)(options, callback)
}
```

## Sucrose Static Analysis Engine

`src/sucrose.ts` implements a custom static analysis engine that inspects handler function source code at compile time to determine which context properties are actually used.

### Purpose

Avoid unnecessary work. If a handler does not destructure `body`, Elysia skips body parsing entirely. If `headers` is not accessed, header parsing is skipped.

### Inference Flags

```typescript
export namespace Sucrose {
    export interface Inference {
        query: boolean
        headers: boolean
        body: boolean
        cookie: boolean
        set: boolean
        server: boolean
        route: boolean
        url: boolean
        path: boolean
    }
}
```

### How It Works

1. **`separateFunction(code)`** - Takes a stringified function and splits it into `[parameters, body, { isArrowReturn }]`. Handles arrow functions, regular functions, method declarations, and both JSC and V8 engine formats.

2. **`retrieveRootParameters(parameter)`** - Extracts top-level destructured parameter names from the function signature. For `({ body, query })`, it returns `['body', 'query']`.

3. **`findParameterReference(parameter, inference)`** - Checks which context properties appear in the parameter destructuring and sets inference flags accordingly.

4. **`findAlias(type, body, depth)`** - Searches the function body for variable assignments that alias context properties (e.g., `const b = body`), following up to 5 levels of alias depth.

5. **`bracketPairRange(parameter)`** - Finds matching `{}` bracket pairs to correctly parse nested destructuring.

The inference results are used by the JIT compiler to generate minimal handler code.

## JIT Handler Compilation (`compose.ts`)

The compose module generates optimized JavaScript handler functions as strings, then evaluates them using `new Function()`. This is the core of Elysia's performance.

### Three Compiled Functions

1. **`composeHandler()`** - Per-route handler. Generates an optimized function for a specific route that includes only the validation, parsing, and lifecycle hooks that route actually needs.

2. **`composeGeneralHandler()`** - The top-level request dispatcher. Routes incoming requests to the correct handler via the trie router. Handles static routes, parametric routes, and WebSocket upgrades.

3. **`composeErrorHandler()`** - Centralized error handling function. Generated once per application.

### Compilation Strategy

The compiler builds a function literal string (`fnLiteral`) incrementally:

- Checks Sucrose inference to skip unused context properties
- Inlines validation code (TypeBox `Check()` calls) directly into the handler
- Generates tracing instrumentation if `trace` hooks are registered
- Handles async vs sync detection via `isAsync()` / `isGenerator()`
- Supports runtime-specific code paths via adapter `composeHandler` hooks

### Trace Integration

If trace handlers are registered, the compiler weaves `performance.now()` timing calls and trace event reporting directly into the generated function body, using the `createReport()` helper.

### AOT vs Dynamic Mode

- **AOT (default)**: `composeGeneralHandler()` pre-compiles all routes at startup. Fastest runtime performance.
- **Dynamic**: `createDynamicHandler()` interprets routes at request time. Supports runtime route addition (e.g., with `.use()` after `listen()`).

## Adapter Pattern

The `ElysiaAdapter` interface (`src/adapter/types.ts`) defines how Elysia interfaces with different JavaScript runtimes.

### Interface

```typescript
export interface ElysiaAdapter {
    name: string
    listen(app: AnyElysia): (options, callback) => void
    stop?(app: AnyElysia, closeActiveConnections?: boolean): Promise<void>
    isWebStandard?: boolean
    handler: {
        mapResponse(response, set, ...params): unknown
        mapEarlyResponse(response, set, ...params): unknown
        mapCompactResponse(response, ...params): unknown
        createStaticHandler?(handle, hooks, setHeaders, ...params): (() => unknown) | undefined
        createNativeStaticHandler?(handle, hooks, set): (() => MaybePromise<Response>) | undefined
    }
    composeHandler: {
        mapResponseContext?: string
        declare?(inference: Sucrose.Inference): string | undefined
        inject?: Record<string, unknown>
        preferWebstandardHeaders?: boolean
        // ... additional code generation hooks
    }
    composeGeneralHandler: { /* dispatch code generation */ }
    composeError: { /* error handler code generation */ }
    ws?: { /* WebSocket adapter hooks */ }
}
```

### Built-in Adapters

1. **BunAdapter** (`src/adapter/bun/`): Bun-native optimizations including `Response.clone()` for static routes, native static handler support, and Bun's native WebSocket integration.

2. **WebStandardAdapter** (`src/adapter/web-standard/`): Fallback adapter using standard Web APIs (`Request`, `Response`, `fetch`). Works on any runtime supporting the WinterCG standard.

3. **Cloudflare Worker** (`src/adapter/cloudflare-worker/`): Detection utility for Cloudflare Workers environment.

External adapters (e.g., `@elysiajs/node`) extend `WebStandardAdapter` and override response mapping for Node.js `IncomingMessage`/`ServerResponse`.

## Type System Design

Elysia's type system is built on several layers:

### 1. Generic Type Accumulation

Every chainable method returns a new `Elysia<...>` with updated generic parameters. For example, `.state('count', 0)` updates the `Singleton` generic to include `{ store: { count: number } }`. This enables full type inference through the entire plugin chain.

### 2. Three Scope Levels

- **Global** (Singleton): Shared across all routes and plugins
- **Scoped** (Ephemeral): Shared with child plugins via `.use()`
- **Local** (Volatile): Only available in the current instance

### 3. Route Schema Types

Route definitions encode their full type schema in the `Routes` generic, enabling Eden to extract and reconstruct types on the client side without any code generation.

### 4. TypeBox Integration

Elysia extends TypeBox with custom types:
- `t.File` / `t.Files` - File upload validation
- `t.Numeric` / `t.NumericString` - String-to-number coercion
- `t.Cookie` - Cookie schema with signing support
- Custom formats registered via `t.Format()`

### 5. Validator Layers

Schema validators are organized in three layers (global, scoped, local) and merged via `mergeSchemaValidator()` at compile time. Each layer can define validation for `body`, `headers`, `params`, `query`, `cookie`, and `response`.

## Key Dependencies

- **memoirist**: Trie-based HTTP router with parameter decoding
- **@sinclair/typebox**: Runtime type validation and JSON Schema generation
- **fast-decode-uri-component**: Optimized URI component decoder
- **cookie-signature**: Cookie signing/unsigning
