# Plugin System Overview

Elysia adopts a modular plugin architecture. Instead of bundling everything, you compose only what you need via `.use()`.

Source: https://elysiajs.com/plugins/overview

## How Plugins Work

A plugin is simply an Elysia instance (or a function returning one). Register it with `.use()`:

```ts
import { Elysia } from 'elysia'
import { cors } from '@elysiajs/cors'

new Elysia()
	.use(cors())
	.listen(3000)
```

Plugins can add routes, hooks, state, decorators, and schemas to the parent instance. They compose together via chaining.

### Creating a Plugin

```ts
import { Elysia } from 'elysia'

// Instance-based plugin
const myPlugin = new Elysia()
	.state('pluginVersion', 1)
	.get('/plugin-route', () => 'from plugin')

// Function-based plugin (accepts config)
const configurable = (config: { prefix: string }) =>
	new Elysia({ prefix: config.prefix })
		.get('/', () => 'configurable')

new Elysia()
	.use(myPlugin)
	.use(configurable({ prefix: '/api' }))
	.listen(3000)
```

## Official Plugins

All official plugins are published under the `@elysiajs` npm scope.

| Plugin | Package | Purpose |
|--------|---------|---------|
| **Bearer** | `@elysiajs/bearer` | Retrieve Bearer authentication tokens |
| **CORS** | `@elysiajs/cors` | Cross-Origin Resource Sharing |
| **Cron** | `@elysiajs/cron` | Schedule and manage cron jobs |
| **Eden** | `@elysiajs/eden` | End-to-end type-safe client |
| **GraphQL Apollo** | `@elysiajs/apollo` | Run Apollo GraphQL server |
| **GraphQL Yoga** | `@elysiajs/graphql-yoga` | Run GraphQL Yoga server |
| **HTML** | `@elysiajs/html` | Handle HTML responses |
| **JWT** | `@elysiajs/jwt` | JSON Web Token authentication |
| **OpenAPI** | `@elysiajs/openapi` | Generate OpenAPI/Swagger documentation |
| **OpenTelemetry** | `@elysiajs/opentelemetry` | Observability and tracing |
| **Server Timing** | `@elysiajs/server-timing` | Performance bottleneck auditing |
| **Static** | `@elysiajs/static` | Serve static files and folders |

### Installation

Install any official plugin via Bun:

```bash
bun add @elysiajs/cors
bun add @elysiajs/jwt
bun add @elysiajs/openapi
# etc.
```

## Community Plugins

The community has built 100+ plugins across many categories:

### Authentication
- Lucia Auth, Clerk, OAuth 2.0, Basic Auth, OpenID Client

### Development
- Vite integration, Remix support, HMR HTML reloading

### Logging
- Logysia, Logestic, pino-based logger, LogTape

### Database
- Drizzle schema helpers, Prisma integration

### Security
- Helmet, CSRF protection, XSS sanitization, Rate limiting

### Utilities
- Compression, ETag generation, i18n, Request IDs, HTMX helpers

### Infrastructure
- Sentry error tracking, AWS Lambda deployment, Supabase integration

Community plugins are listed in the official Elysia documentation. Developers can contribute plugins by submitting to the docs repository on GitHub.

## Plugin Composition Example

Combine multiple plugins to build a full application stack:

```ts
import { Elysia } from 'elysia'
import { cors } from '@elysiajs/cors'
import { jwt } from '@elysiajs/jwt'
import { openapi } from '@elysiajs/openapi'
import { bearer } from '@elysiajs/bearer'

new Elysia()
	.use(cors())
	.use(
		jwt({
			name: 'jwt',
			secret: process.env.JWT_SECRET!
		})
	)
	.use(bearer())
	.use(openapi())
	.get('/protected', async ({ jwt, bearer, status }) => {
		const profile = await jwt.verify(bearer)
		if (!profile) return status(401, 'Unauthorized')
		return profile
	})
	.listen(3000)
```

## Plugin Scoping

Plugins can be scoped to limit how their hooks and state propagate:

```ts
import { Elysia } from 'elysia'

// Scoped plugin -- hooks only apply within this plugin
const scopedPlugin = new Elysia({ scoped: true })
	.onBeforeHandle(() => {
		console.log('Only runs for routes in this plugin')
	})
	.get('/scoped', () => 'scoped route')

new Elysia()
	.use(scopedPlugin)
	// This route is NOT affected by scopedPlugin's beforeHandle
	.get('/', () => 'main route')
	.listen(3000)
```

## Design Philosophy

Elysia follows a modular approach (similar to Arch Linux's philosophy): decisions are made on a case-by-case basis. This keeps applications lean -- you include only what you need, avoiding the overhead of batteries-included frameworks.
