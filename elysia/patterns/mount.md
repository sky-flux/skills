# Mount
WinterTC is a standard for building HTTP servers behind Cloudflare, Deno, Vercel, and others. It enables web servers to operate across different runtimes using standard `Request` and `Response` APIs.

Elysia conforms to WinterTC standards, optimized for Bun while supporting additional runtimes. This interoperability allows multiple frameworks to work together seamlessly.

## Supported Frameworks

Compatible frameworks include:
- Hono
- Nitro
- H3
- Next.js API Routes
- Nuxt API Routes
- SvelteKit API Routes

## Supported Runtimes

Deployment targets:
- Bun
- Deno
- Vercel Edge Runtime
- Cloudflare Worker
- Netlify Edge Function

## Basic Mount Pattern

Use `.mount()` to attach another framework's fetch handler at a specific path prefix:

```typescript
import { Elysia } from 'elysia'
import { Hono } from 'hono'

const hono = new Hono()
	.get('/', (c) => c.text('Hello from Hono!'))

const app = new Elysia()
    .get('/', () => 'Hello from Elysia')
    .mount('/hono', hono.fetch)
```

The `.mount()` method accepts a path and a `fetch` function conforming to the WinterTC standard (`(request: Request) => Response | Promise<Response>`).

## Nested Mounting

Frameworks can be nested arbitrarily deep:

```typescript
import { Elysia } from 'elysia'
import { Hono } from 'hono'

const elysia = new Elysia()
    .get('/', () => 'Hello from Elysia inside Hono inside Elysia')

const hono = new Hono()
    .get('/', (c) => c.text('Hello from Hono!'))
    .mount('/elysia', elysia.fetch)

const main = new Elysia()
    .get('/', () => 'Hello from Elysia')
    .mount('/hono', hono.fetch)
    .listen(3000)
```

This makes interoperable frameworks and runtimes a reality, allowing you to incrementally adopt Elysia or compose applications from multiple frameworks.
