---
name: elysiajs
description: Create backend with ElysiaJS, a type-safe, high-performance framework.
---

# ElysiaJS Development Skill

Always consult [elysiajs.com/llms.txt](https://elysiajs.com/llms.txt) for code examples and latest API.

## Overview

ElysiaJS is a TypeScript framework for building Bun-first (but not limited to Bun) type-safe, high-performance backend servers. This skill provides comprehensive guidance for developing with Elysia, including routing, validation, authentication, plugins, integrations, and deployment.

## When to Use This Skill

Trigger this skill when the user asks to:
- Create or modify ElysiaJS routes, handlers, or servers
- Setup validation with TypeBox or other schema libraries (Zod, Valibot)
- Implement authentication (JWT, session-based, macros, guards)
- Add plugins (CORS, OpenAPI, Static files, JWT)
- Integrate with external services (Drizzle ORM, Better Auth, Next.js, Eden Treaty)
- Setup WebSocket endpoints for real-time features
- Create unit tests for Elysia instances
- Deploy Elysia servers to production
- Migrate from Express, Fastify, Hono, or tRPC to Elysia
- Configure advanced server options (TLS, adapters, performance tuning)
- Extend context with state, decorate, derive, resolve
- Monitor performance with .trace() lifecycle instrumentation

## Quick Start
Quick scaffold:
```bash
bun create elysia app
```

### Basic Server
```typescript
import { Elysia, t, status } from 'elysia'

const app = new Elysia()
  	.get('/', () => 'Hello World')
   	.post('/user', ({ body }) => body, {
    	body: t.Object({
      		name: t.String(),
        	age: t.Number()
     	})
    })
    .get('/id/:id', ({ params: { id } }) => {
   		if(id > 1_000_000) return status(404, 'Not Found')
     
     	return id
    }, {
    	params: t.Object({
     		id: t.Number({
       			minimum: 1
       		})
     	}),
     	response: {
      		200: t.Number(),
        	404: t.Literal('Not Found')
      	}
    })
    .listen(3000)
```

## Basic Usage

### HTTP Methods
```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/', 'GET')
  .post('/', 'POST')
  .put('/', 'PUT')
  .patch('/', 'PATCH')
  .delete('/', 'DELETE')
  .options('/', 'OPTIONS')
  .head('/', 'HEAD')
```

### Path Parameters
```typescript
.get('/user/:id', ({ params: { id } }) => id)
.get('/post/:id/:slug', ({ params }) => params)
```

### Query Parameters
```typescript
.get('/search', ({ query }) => query.q)
// GET /search?q=elysia → "elysia"
```

### Request Body
```typescript
.post('/user', ({ body }) => body)
```

### Headers
```typescript
.get('/', ({ headers }) => headers.authorization)
```

## TypeBox Validation

### Basic Types
```typescript
import { Elysia, t } from 'elysia'

.post('/user', ({ body }) => body, {
  body: t.Object({
    name: t.String(),
    age: t.Number(),
    email: t.String({ format: 'email' }),
    website: t.Optional(t.String({ format: 'uri' }))
  })
})
```

### Nested Objects
```typescript
body: t.Object({
  user: t.Object({
    name: t.String(),
    address: t.Object({
      street: t.String(),
      city: t.String()
    })
  })
})
```

### Arrays
```typescript
body: t.Object({
  tags: t.Array(t.String()),
  users: t.Array(t.Object({
    id: t.String(),
    name: t.String()
  }))
})
```

### File Upload
```typescript
.post('/upload', ({ body }) => body.file, {
  body: t.Object({
    file: t.File({
      type: 'image',              // image/* mime types
      maxSize: '5m'               // 5 megabytes
    }),
    files: t.Files({              // Multiple files
      type: ['image/png', 'image/jpeg']
    })
  })
})
```

### Response Validation
```typescript
.get('/user/:id', ({ params: { id } }) => ({
  id,
  name: 'John',
  email: 'john@example.com'
}), {
  params: t.Object({
    id: t.Number()
  }),
  response: {
    200: t.Object({
      id: t.Number(),
      name: t.String(),
      email: t.String()
    }),
    404: t.String()
  }
})
```

## Standard Schema (Zod, Valibot, ArkType)

### Zod
```typescript
import { z } from 'zod'

.post('/user', ({ body }) => body, {
  body: z.object({
    name: z.string(),
    age: z.number().min(0),
    email: z.string().email()
  })
})
```

### Valibot
```typescript
// Valibot
import * as v from 'valibot'

.post('/user', ({ body }) => body, {
  body: v.object({
    name: v.string(),
    age: v.pipe(v.number(), v.minValue(0)),
    email: v.pipe(v.string(), v.email())
  })
})
```

## Error Handling

```typescript
.get('/user/:id', ({ params: { id }, status }) => {
  const user = findUser(id)
  
  if (!user) {
    return status(404, 'User not found')
  }
  
  return user
})
```

## Streaming & Server-Sent Events

### Stream Response
```typescript
.get('/stream', function* () {
  yield 'Hello '
  yield 'World'
})
```

### Server-Sent Events (SSE)
```typescript
.get('/sse', async function* () {
  while (true) {
    yield { data: JSON.stringify({ time: Date.now() }) }
    await Bun.sleep(1000)
  }
})
```

## Guards (Apply to Multiple Routes)

```typescript
.guard({
  params: t.Object({
    id: t.Number()
  })
}, app => app
  .get('/user/:id', ({ params: { id } }) => id)
  .delete('/user/:id', ({ params: { id } }) => id)
)
```

## Macro

```typescript
.macro({
  hi: (word: string) => ({
    beforeHandle() { console.log(word) }
  })
})
.get('/', () => 'hi', { hi: 'Elysia' })
```

### Authentication Macro
```typescript
// Authentication macro
.macro({
  isAuth: (enabled: boolean) => enabled ? {
    resolve: async ({ cookie: { token }, status }) => {
      const user = await verifyToken(token.value)
      if (!user) return status(401, 'Unauthorized')
      return { user }
    }
  } : {}
})
.get('/profile', ({ user }) => user, { isAuth: true })
```

See `references/macro.md` for complete macro patterns including RBAC and rate-limiting.

### Project Structure (Recommended)
Elysia takes an unopinionated approach but based on user request. But without any specific preference, we recommend a feature-based and domain driven folder structure where each feature has its own folder containing controllers, services, and models.

```
src/
├── index.ts              # Main server entry
├── modules/
│   ├── auth/
│   │   ├── index.ts      # Auth routes (Elysia instance)
│   │   ├── service.ts    # Business logic
│   │   └── model.ts      # TypeBox schemas/DTOs
│   └── user/
│       ├── index.ts
│       ├── service.ts
│       └── model.ts
└── plugins/
    └── custom.ts

public/                   # Static files (if using static plugin)
test/                     # Unit tests
```

Each file has its own responsibility as follows:
- **Controller (index.ts)**: Handle HTTP routing, request validation, and cookie.
- **Service (service.ts)**: Handle business logic, decoupled from Elysia controller if possible.
- **Model (model.ts)**: Define the data structure and validation for the request and response.

## Best Practice
Elysia is unopinionated on design pattern, but if not provided, we can relies on MVC pattern pair with feature based folder structure.

- Controller:
	- Prefers Elysia as a controller for HTTP dependant controller
	- For non HTTP dependent, prefers service instead unless explicitly asked
	- Use `onError` to handle local custom errors
	- Register Model to Elysia instance via `Elysia.models({ ...models })` and prefix model by namespace `Elysia.prefix('model', 'Namespace.')
	- Prefers Reference Model by name provided by Elysia instead of using an actual `Model.name`
- Service:
	- Prefers class (or abstract class if possible)
	- Prefers interface/type derive from `Model`
	- Return `status` (`import { status } from 'elysia'`) for error
	- Prefers `return Error` instead of `throw Error`
- Models:
	- Always export validation model and type of validation model
	- Custom Error should be in contains in Model

## Elysia Key Concept
Elysia has a every important concepts/rules to understand before use.

## Encapsulation - Isolates by Default

Lifecycles (hooks, middleware) **don't leak** between instances unless scoped.

**Scope levels:**
- `local` (default) - current instance + descendants
- `scoped` - parent + current + descendants  
- `global` - all instances

```ts
.onBeforeHandle(() => {}) // only local instance
.onBeforeHandle({ as: 'global' }, () => {}) // exports to all
```

## Method Chaining - Required for Types

**Must chain**. Each method returns new type reference.

❌ Don't:
```ts
const app = new Elysia()
app.state('build', 1) // loses type
app.get('/', ({ store }) => store.build) // build doesn't exists
```

✅ Do:
```ts
new Elysia()
  .state('build', 1)
  .get('/', ({ store }) => store.build)
```

## Explicit Dependencies

Each instance independent. **Declare what you use.**

```ts
const auth = new Elysia()
	.decorate('Auth', Auth)
	.model(Auth.models)

new Elysia()
  .get('/', ({ Auth }) => Auth.getProfile()) // Auth doesn't exists

new Elysia()
  .use(auth) // must declare
  .get('/', ({ Auth }) => Auth.getProfile())
```

**Global scope when:**
- No types added (cors, helmet)
- Global lifecycle (logging, tracing)

**Explicit when:**
- Adds types (state, models)
- Business logic (auth, db)

## Deduplication

Plugins re-execute unless named:

```ts
new Elysia() // rerun on `.use`
new Elysia({ name: 'ip' }) // runs once across all instances
```

## Order Matters

Events apply to routes **registered after** them.

```ts
.onBeforeHandle(() => console.log('1'))
.get('/', () => 'hi') // has hook
.onBeforeHandle(() => console.log('2')) // doesn't affect '/'
```

## Type Inference

**Inline functions only** for accurate types.

For controllers, destructure in inline wrapper:

```ts
.post('/', ({ body }) => Controller.greet(body), {
  body: t.Object({ name: t.String() })
})
```

Get type from schema:
```ts
type MyType = typeof MyType.static
```

## Reference Model
Model can be reference by name, especially great for documenting an API
```ts
new Elysia()
	.model({
		book: t.Object({
			name: t.String()
		})
	})
	.post('/', ({ body }) => body.name, {
		body: 'book'
	})
```

Model can be renamed by using `.prefix` / `.suffix`
```ts
new Elysia()
	.model({
		book: t.Object({
			name: t.String()
		})
	})
	.prefix('model', 'Namespace')
	.post('/', ({ body }) => body.name, {
		body: 'Namespace.Book'
	})
```

Once `prefix`, model name will be capitalized by default.

## Technical Terms
The following are technical terms that is use for Elysia:
- `OpenAPI Type Gen` - function name `fromTypes` from `@elysiajs/openapi` for generating OpenAPI from types, see `plugins/openapi.md`
- `Eden`, `Eden Treaty` - e2e type safe RPC client for share type from backend to frontend

## Advanced Patterns (from source analysis)

These patterns are derived from analyzing the `elysiajs/elysia` core repository source code.

### Adapter Architecture

Elysia uses an `ElysiaAdapter` interface (`src/adapter/types.ts`) to abstract runtime differences. Each adapter implements `listen`, `stop`, and handler mapping (mapResponse, mapEarlyResponse, mapCompactResponse, createStaticHandler). The three built-in adapters are:

- **BunAdapter** (`src/adapter/bun/`) - Default, optimized for Bun with native static handler support
- **WebStandardAdapter** (`src/adapter/web-standard/`) - WinterTC-compliant for Deno and Node.js
- **Cloudflare Worker** (`src/adapter/cloudflare-worker/`) - Edge runtime adapter

Select an adapter via:
```ts
import { node } from '@elysiajs/node'
new Elysia({ adapter: node() })
```

### Lifecycle Hook Execution Order

The handler compiler (`src/compose.ts`) builds optimized handler functions that execute lifecycle hooks in this exact order:

1. **onRequest** - Before anything, raw request access
2. **parse** - Body parsing (JSON, text, urlencoded, formdata, arrayBuffer)
3. **transform** - Mutate context before validation
4. **beforeHandle** - Pre-handler logic (auth, guards); can short-circuit with early return
5. **handle** - The main route handler
6. **afterHandle** - Post-handler processing; can modify the response
7. **mapResponse** - Transform the final response object
8. **afterResponse** - Cleanup after response is sent (logging, metrics)
9. **onError** - Catches errors from any phase above

Each hook can be `async` or a generator. The compiler detects this and wraps appropriately.

### Sucrose: Static Analysis Engine

Elysia's `Sucrose` module (`src/sucrose.ts`) performs static analysis on handler function source code at compile time. It parses the stringified function body to detect which Context properties are actually used (query, headers, body, cookie, set, server, route, url, path). This enables:

- **Dead code elimination** - Only inject what the handler needs
- **Faster cold starts** - Skip parsing body if handler never accesses `body`
- **Automatic optimization** - No manual configuration needed

This is why Elysia requires inline handler functions for best performance: it analyzes the function text.

### Compiled Handler Generation

The `composeHandler` function in `src/compose.ts` generates optimized JavaScript code as string literals (`fnLiteral`) then evaluates them. This JIT-style compilation means:

- Each route gets a custom-tailored handler function
- Validation, parsing, and hooks are inlined where possible
- No runtime branching for features the route does not use

### Trace System Internals

The trace system (`src/trace.ts`) defines `TraceEvent` types matching every lifecycle phase: `request`, `parse`, `transform`, `beforeHandle`, `handle`, `afterHandle`, `mapResponse`, `afterResponse`, `error`. Each trace event provides:

- `begin` / `end` timestamps (from server start)
- `elapsed` duration
- `error` if thrown in that phase
- Child resolution for nested hooks via `resolveChild`

## Type Soundness

Elysia provides **sound types** — the TypeScript types accurately reflect all possible runtime outcomes.

A single schema definition serves as **Single Source of Truth** for:
- **Runtime validation** - request/response data checked at runtime
- **Data coercion** - automatic type conversion (string to number)
- **TypeScript types** - compile-time type inference
- **OpenAPI schema** - auto-generated API documentation

## Resources
Use the following references as needed.

It's recommended to checkout `route.md` for as it contains the most important foundation building blocks with examples.

`plugin.md` and `validation.md` is important as well but can be check as needed.

### Recommended Reading Order

**Tier 1 - Foundation (start here):**
1. `references/route.md` - Routing, Handler, Context (core building blocks)
2. `references/validation.md` - Input/output validation rules
3. `references/lifecycle.md` - Request lifecycle pipeline
4. `references/plugin.md` - Plugin system and modularity

**Tier 2 - Core Patterns:**
5. `patterns/extends-context.md` - Context extension APIs (state, decorate, derive, resolve)
6. `patterns/error-handling.md` - Error management and custom error classes
7. `references/eden.md` - End-to-end type-safe client
8. `patterns/mvc.md` - Project architecture patterns

**Tier 3 - Advanced:**
9. `references/macro.md` - Composable schema/lifecycle patterns
10. `patterns/configuration.md` - Server configuration (25+ options)
11. `patterns/trace.md` - Performance monitoring
12. `references/cheat-sheet.md` - Quick reference by example

### references/
Detailed documentation split by topic:
- `bun-fullstack-dev-server.md` - Bun Fullstack Dev Server with HMR. React without bundler.
- `cookie.md` - Detailed documentation on cookie
- `deployment.md` - Production deployment guide / Docker
- `eden.md` - e2e type safe RPC client for share type from backend to frontend
- `guard.md` - Setting validation/lifecycle all at once
- `macro.md` - Compose multiple schema/lifecycle as a reusable Elysia via key-value (recommended for complex setup, eg. authentication, authorization, Role-based Access Check)
- `plugin.md` - Decouple part of Elysia into a standalone component
- `route.md` - Elysia foundation building block: Routing, Handler and Context
- `testing.md` - Unit tests with examples
- `validation.md` - Setup input/output validation and list of all custom validation rules
- `websocket.md` - Real-time features
- `cheat-sheet.md` - Elysia by example quick reference

### plugins/
Detailed documentation, usage and configuration reference for official Elysia plugin:
- `overview.md` - Plugin system overview and official plugin list
- `bearer.md` - Add bearer capability to Elysia (`@elysiajs/bearer`)
- `cors.md` - Out of box configuration for CORS (`@elysiajs/cors`)
- `cron.md` - Run cron job with access to Elysia context (`@elysiajs/cron`)
- `graphql-apollo.md` - Integration GraphQL Apollo (`@elysiajs/graphql-apollo`)
- `graphql-yoga.md` - Integration with GraphQL Yoga (`@elysiajs/graphql-yoga`)
- `html.md` - HTML and JSX plugin setup and usage (`@elysiajs/html`)
- `jwt.md` - JWT / JWK plugin (`@elysiajs/jwt`)
- `openapi.md` - OpenAPI documentation and OpenAPI Type Gen / OpenAPI from types (`@elysiajs/openapi`)
- `opentelemetry.md` - OpenTelemetry, instrumentation, and record span utilities (`@elysiajs/opentelemetry`)
- `server-timing.md` - Server Timing metric for debug (`@elysiajs/server-timing`) 
- `static.md` - Serve static files/folders for Elysia Server (`@elysiajs/static`)

### integrations/
Guide to integrate Elysia with external library/runtime:
- `ai-sdk.md` - Using Vercel AI SDK with Elysia
- `astro.md` - Elysia in Astro API route
- `better-auth.md` - Integrate Elysia with better-auth
- `cloudflare-worker.md` - Elysia on Cloudflare Worker adapter
- `deno.md` - Elysia on Deno
- `drizzle.md` - Integrate Elysia with Drizzle ORM
- `expo.md` - Elysia in Expo API route
- `nextjs.md` - Elysia in Nextjs API route
- `nodejs.md` - Run Elysia on Node.js
- `nuxt.md` - Elysia on API route
- `prisma.md` - Integrate Elysia with Prisma
- `react-email.md` - Create and Send Email with React and Elysia
- `sveltekit.md` - Run Elysia on Svelte Kit API route
- `tanstack-start.md` - Run Elysia on Tanstack Start / React Query
- `netlify.md` - Elysia on Netlify Edge Functions
- `vercel.md` - Deploy Elysia to Vercel

### eden/
Comprehensive Eden client documentation:
- `eden/overview.md` - Eden ecosystem overview (Treaty vs Fetch)
- `eden/installation.md` - Installation, type export, gotchas
- `eden/fetch.md` - Eden Fetch low-level API
- `eden/treaty-overview.md` - Treaty initialization and syntax
- `eden/treaty-parameters.md` - Body, headers, query parameters
- `eden/treaty-response.md` - Response handling and type narrowing
- `eden/treaty-websocket.md` - WebSocket with Treaty
- `eden/treaty-config.md` - Configuration, hooks, custom fetch
- `eden/treaty-unit-test.md` - Zero-overhead testing with Treaty

### examples/ (optional)
- `basic.ts` - Basic Elysia example
- `body-parser.ts` - Custom body parser example via `.onParse`
- `complex.ts` - Comprehensive usage of Elysia server
- `cookie.ts` - Setting cookie
- `error.ts` - Error handling
- `file.ts` - Returning local file from server
- `guard.ts` - Setting mulitple validation schema and lifecycle
- `map-response.ts` - Custom response mapper
- `redirect.ts` - Redirect response
- `rename.ts` - Rename context's property 
- `schema.ts` - Setup validation
- `state.ts` - Setup global state
- `upload-file.ts` - File upload with validation
- `websocket.ts` - Web Socket for realtime communication

### patterns/
- `patterns/mvc.md` - Detail guideline for using Elysia with MVC patterns
- `patterns/configuration.md` - Elysia constructor configuration options (25+ options including serve, TLS, adapter)
- `patterns/extends-context.md` - Core APIs for extending Context: state, decorate, derive, resolve, affix
- `patterns/error-handling.md` - Advanced error handling: custom error classes, validation messages, production safety
- `patterns/trace.md` - Performance monitoring with .trace(), lifecycle event injection
- `patterns/typebox.md` - Complete TypeBox type reference including Elysia-specific types (File, Cookie, Nullable, Form, Numeric)
- `patterns/typescript.md` - TypeScript performance optimization, type inference, schema-to-type conversion
- `patterns/mount.md` - WinterTC framework interop, mounting Hono/Next.js/Nuxt/SvelteKit
- `patterns/standalone-schema.md` - Standalone schema definition and cross-route reuse

### migrations/
Guide to migrate from other frameworks to Elysia:
- `migrations/from-express.md` - Migrate from Express to Elysia (15+ topic comparisons)
- `migrations/from-fastify.md` - Migrate from Fastify to Elysia
- `migrations/from-hono.md` - Migrate from Hono to Elysia
- `migrations/from-trpc.md` - Migrate from tRPC to Elysia
