# ElysiaJS Plugin Ecosystem

Source: 14 official plugin repositories under `elysiajs/` organization

## Common Plugin Structure Pattern

All official Elysia plugins follow a consistent pattern:

### Standard File Layout

```
src/
  index.ts          # Main plugin export
  types.ts          # TypeScript type definitions (optional)
  utils.ts          # Helper functions (optional)
package.json        # name: @elysiajs/<plugin-name>
tsconfig.json
```

### Plugin Factory Pattern

Every plugin is either:

**A) A function returning an Elysia instance** (most common):

```typescript
export const pluginName = (config: PluginConfig = {}) =>
    new Elysia({
        name: '@elysiajs/plugin-name',
        seed: config                    // Enables deduplication
    })
    .decorate(/* ... */)               // Add decorators
    .derive(/* ... */)                 // Add derived properties
    .onBeforeHandle(/* ... */)         // Add lifecycle hooks
```

**B) A function taking an Elysia instance** (legacy pattern, used by `elysia-cron`):

```typescript
export const cron = (config: CronConfig) => (app: Elysia) => {
    return app.state(/* ... */)
}
```

### Key Conventions

1. **`name` property**: Always set to `'@elysiajs/<name>'` for deduplication
2. **`seed` property**: Passes config to enable multiple instances with different configs
3. **Scoping with `as`**: Plugins use `{ as: 'global' }` or `{ as: 'scoped' }` to control hook propagation
4. **Type-safe config**: Config interfaces are exported for user extension
5. **Default values**: All config options have sensible defaults

## Plugin-by-Plugin Analysis

### `@elysiajs/cors`

**Purpose**: Cross-Origin Resource Sharing headers

**How it hooks in**:
- Uses `onRequest` hook to intercept preflight `OPTIONS` requests
- Sets `Access-Control-Allow-*` headers on every response
- Handles origin matching with string, RegExp, or function predicates

**Config highlights**:
- `origin`: String, boolean, RegExp, or function matcher
- `methods`: Allowed HTTP methods (defaults to all)
- `credentials`, `allowedHeaders`, `exposedHeaders`, `maxAge`
- `aot`: Controls AOT compilation (default `true`)

**Implementation pattern**: The origin check evaluates at request time. If origin is `true`, sets `*`. If function, calls it with the request. RegExp tests against `Origin` header.

---

### `@elysiajs/jwt`

**Purpose**: JSON Web Token creation and verification

**How it hooks in**:
- Uses `decorate` to add `jwt.sign()` and `jwt.verify()` methods to context
- Built on the `jose` library (standards-compliant JWT implementation)

**Config highlights**:
- `name`: Custom decorator name (default `'jwt'`)
- `secret`: Required signing secret (string, CryptoKey, JWK, or KeyObject)
- `schema`: Optional TypeBox schema for payload validation
- Standard JWT options: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`
- All `JWTVerifyOptions` from jose

**Implementation pattern**: `sign()` creates a `SignJWT` instance, sets claims, and signs. `verify()` calls `jwtVerify()` and optionally validates against the TypeBox schema.

**Type safety**: When a `schema` is provided, the `sign()` and `verify()` return types are inferred from the schema, not generic `JWTPayload`.

---

### `@elysiajs/bearer`

**Purpose**: Extract Bearer tokens from requests (RFC 6750)

**How it hooks in**:
- Uses `derive` with `{ as: 'global' }` to add a `bearer` getter to every request context

**Implementation**: Extracts token from three sources:
1. `Authorization` header (default prefix: `Bearer`)
2. Query parameter (default: `access_token`)
3. Request body field (default: `access_token`)

**Config**: `extract.body`, `extract.query`, `extract.header` for customizing field names.

The `bearer` property is a getter (lazy evaluation), so it only parses when accessed.

---

### `@elysiajs/static`

**Purpose**: Serve static files from a directory

**How it hooks in**:
- Registers GET routes for each file in the assets directory
- Uses `onRequest` for dynamic file serving when static limit is exceeded
- Supports ETag caching and conditional requests

**Config highlights**:
- `assets`: Directory path (default: `'public'`)
- `prefix`: URL prefix (default: `'/public'`)
- `staticLimit`: Max files for static route registration (default: 1024)
- `alwaysStatic`: Force all files as static routes (default in production)
- `etag`: Enable ETag generation (default: `true`)
- `maxAge`: Cache-Control max-age in seconds (default: 86400)
- `indexHTML`: Serve `index.html` for directory paths (default: `true`)
- `ignorePatterns`: File patterns to skip (default: `.DS_Store`, `.git`, `.env`)

**Implementation details**:
- Uses an LRU cache for response objects
- Generates ETags via file content hashing
- Handles `If-None-Match` for 304 responses
- Uses `process.getBuiltinModule` for Node.js fs/path access (runtime-agnostic)

---

### `@elysiajs/cron`

**Purpose**: Scheduled task execution

**How it hooks in**:
- Uses `state` to register `Cron` instances on `store.cron`
- Built on the `croner` library

**Config**:
- `pattern`: Cron expression (second optional)
- `name`: Registered name in store
- `run`: Function executed on schedule (receives Cron instance)
- All `croner` `CronOptions` (timezone, maxRuns, protect, etc.)

**Usage pattern**: Access running crons via `store.cron.jobName` for programmatic control (pause, resume, stop).

---

### `@elysiajs/html`

**Purpose**: JSX/HTML response support using `@kitajs/html`

**How it hooks in**:
- Re-exports `@kitajs/html` for JSX compilation
- Provides `html()` plugin for automatic HTML content-type headers
- Includes `ErrorBoundary` component

**Implementation**: Wraps KitaJS HTML (a compile-time JSX-to-string library). No virtual DOM - JSX compiles directly to string concatenation for maximum performance.

---

### `@elysiajs/graphql-yoga`

**Purpose**: GraphQL endpoint via `graphql-yoga`

**How it hooks in**:
- Registers a route (default: `/graphql`) using `yoga.handle()`
- Supports both schema-first and code-first approaches

**Config options**:
- `path`: GraphQL endpoint (default: `'/graphql'`)
- `typeDefs` + `resolvers`: Schema-first approach
- `schema`: Pre-built GraphQL schema
- `context`: Context factory function
- Integrates with `graphql-mobius` for type-safe resolver definitions

---

### `@elysiajs/apollo`

**Purpose**: GraphQL endpoint via Apollo Server

**How it hooks in**:
- Extends `ApolloServer` as `ElysiaApolloServer`
- `createHandler()` registers GET (playground) and POST (query execution) routes
- Handles query parsing, variable extraction, and Apollo landing page

**Config**: Standard `ApolloServerOptions` plus `path`, `enablePlayground`, and `context` factory.

---

### `@elysiajs/opentelemetry`

**Purpose**: OpenTelemetry distributed tracing

**How it hooks in**:
- Uses Elysia's built-in `trace` system to instrument all lifecycle events
- Creates OpenTelemetry spans for each lifecycle phase (request, parse, transform, beforeHandle, handle, afterHandle, mapResponse, afterResponse)
- Propagates trace context via W3C trace headers

**Config**: Extends `NodeSDK` options with optional `contextManager`.

**Implementation**: Initializes the OpenTelemetry SDK, creates a tracer, and registers trace hooks that:
1. Extract propagated context from incoming request headers
2. Create root span with HTTP attributes (method, route, status)
3. Create child spans for each lifecycle event
4. Record errors and set span status
5. Export spans via configured exporter

---

### `@elysiajs/server-timing`

**Purpose**: Server-Timing HTTP header for performance debugging

**How it hooks in**:
- Uses Elysia's `trace` system to measure lifecycle durations
- Adds `Server-Timing` header to responses with timing data

**Config**: Granular control over which lifecycle events to trace (request, parse, transform, beforeHandle, handle, afterHandle, error).

**Implementation**: Collects `performance.now()` timings during each lifecycle phase and formats them as the `Server-Timing` header value (e.g., `parse;dur=0.5, handle;dur=2.3`).

---

### `@elysiajs/openapi` (formerly elysia-swagger)

**Purpose**: Auto-generated OpenAPI documentation page

**How it hooks in**:
- Registers routes for the documentation UI and JSON spec
- Introspects all registered routes via `app.routes` to build OpenAPI schema
- Supports both Swagger UI and Scalar UI renderers

**Config**:
- `path`: Documentation URL (default: `'/openapi'`)
- `provider`: `'scalar'` or `'swagger-ui'`
- `documentation`: OpenAPI document overrides
- `exclude`: Route patterns to hide
- `mapJsonSchema`: Custom schema transformer

---

### `@elysiajs/stream`

**Purpose**: Server-Sent Events helper (legacy)

**Note**: Modern Elysia supports generators natively for SSE. This plugin provides the legacy `Stream` class.

**Implementation**: The `Stream` class wraps a `ReadableStream` with:
- `send(data)`: Encodes data as SSE format (`data: ...\n\n`)
- `close()`: Closes the stream
- `event` / `retry`: SSE event type and reconnect interval
- Auto-generates unique stream IDs via `nanoid`

---

### `@elysiajs/cookie` (legacy)

**Purpose**: Cookie management (now built into Elysia core)

**How it hooks in**:
- Uses `derive` to add `cookie`, `setCookie`, `removeCookie` to context
- Uses `decorate` to add `unsignCookie` utility

**Implementation**: Built on `cookie` (parse/serialize) and `cookie-signature` (sign/unsign). Supports key rotation for signing secrets.

**Note**: Cookie handling is now native in Elysia. This plugin exists for backward compatibility.

---

### `@elysiajs/lucia` (legacy)

**Purpose**: Authentication via the Lucia library

**How it hooks in**:
- Wraps Lucia auth with Elysia-specific session management
- Provides OAuth provider shortcuts (GitHub, Google, Discord, etc. via `@lucia-auth/oauth/providers`)
- Manages session cookies via Elysia's cookie system

**Note**: Lucia v3 deprecated its own framework integrations. For modern auth, use `better-auth` or handle sessions manually.

## How Plugins Use Elysia Hooks

### Hook Methods Used by Plugins

| Hook | Purpose | Plugins Using It |
|---|---|---|
| `decorate` | Add utilities to context | jwt, cookie |
| `derive` | Add computed properties | bearer, cookie |
| `state` | Add to global store | cron |
| `onRequest` | Intercept before routing | cors, static |
| `onBeforeHandle` | Guard/validation | cors (preflight) |
| `onAfterHandle` | Transform response | html (content-type) |
| `trace` | Performance instrumentation | opentelemetry, server-timing |
| `route/get/post` | Register endpoints | graphql-yoga, apollo, openapi, static |

### Scope Propagation

Plugins choose their scope carefully:
- **`{ as: 'global' }`**: bearer, cors (must apply to all routes)
- **`{ as: 'scoped' }`**: Most plugins (applies to parent and sibling plugins)
- **Default (local)**: Only applies within the plugin's own routes

## Plugin Development Guide

### Minimal Plugin Template

```typescript
import { Elysia } from 'elysia'

export interface MyPluginConfig {
    option1?: string
    option2?: number
}

export const myPlugin = (config: MyPluginConfig = {}) =>
    new Elysia({
        name: 'my-plugin',          // Required for deduplication
        seed: config                 // Different configs = different instances
    })
    // Add functionality via hooks:
    .decorate('myUtil', () => { /* ... */ })
    .derive({ as: 'scoped' }, ({ request }) => ({
        myProperty: request.headers.get('x-custom')
    }))
    .onBeforeHandle({ as: 'scoped' }, ({ myProperty }) => {
        if (!myProperty) return new Response('Unauthorized', { status: 401 })
    })
```

### Best Practices from Official Plugins

1. **Always set `name`**: Prevents duplicate plugin registration
2. **Use `seed` for config**: Allows multiple instances with different configs
3. **Export config types**: Let users extend and customize
4. **Provide defaults**: Every option should have a sensible default
5. **Choose scope carefully**: Use `global` only when truly necessary
6. **Lazy evaluation**: Use getters (like bearer's `get bearer()`) for properties that are expensive to compute
7. **Guard with `onBeforeHandle`**: Not `onRequest`, so route matching still applies
8. **Type augmentation**: Return types should flow through to the handler context automatically
