# Eden Overview

Eden is Elysia's end-to-end type-safe RPC-like client, enabling you to connect client and server with full type safety using only TypeScript's type inference -- no code generation required. Changing a type on the server is instantly reflected on the client, providing auto-completion and type enforcement. Eden weighs less than 2KB.

## End-to-End Type Safety

End-to-end type safety means every piece of your client-server communication fits together like puzzle pieces. Elysia provides this out of the box with Eden. Other frameworks that support e2e type safety include tRPC, Remix, SvelteKit, Nuxt, and TS-Rest.

## Eden Modules

Eden consists of two modules:

| Module | Description | Recommended |
|--------|-------------|-------------|
| **Eden Treaty** | Object-like representation of an Elysia server with full type support, auto-completion, error handling with type narrowing | Yes |
| **Eden Fetch** | Fetch-like client with type safety, similar to standard fetch API syntax | No (use Treaty) |

## Eden Treaty (Recommended)

Eden Treaty is an object-like representation of an Elysia server providing end-to-end type safety and a significantly improved developer experience.

With Eden Treaty you can:
- Interact with an Elysia server with full-type support and auto-completion
- Handle errors with type narrowing
- Create type-safe unit tests

```typescript
import { treaty } from '@elysiajs/eden'
import type { App } from './server'

const app = treaty<App>('localhost:3000')

// Call [GET] at '/'
const { data } = await app.get()

// Call [PUT] at '/nendoroid/:id'
const { data: nendoroid, error } = await app.nendoroid({ id: 1895 }).put({
    name: 'Skadi',
    from: 'Arknights'
})
```

## Eden Fetch

A fetch-like alternative to Eden Treaty for developers that prefer fetch syntax.

```typescript
import { edenFetch } from '@elysiajs/eden'
import type { App } from './server'

const fetch = edenFetch<App>('http://localhost:3000')

const { data } = await fetch('/name/:name', {
    method: 'POST',
    params: {
        name: 'Saori'
    },
    body: {
        branch: 'Arius',
        type: 'Striker'
    }
})
```

> **Note:** Unlike Eden Treaty, Eden Fetch does not provide WebSocket implementation for Elysia server.

## When to Use Which

| Criteria | Eden Treaty | Eden Fetch |
|----------|-------------|------------|
| Syntax | Object-like (`api.user.get()`) | Fetch-like (`fetch('/user', {})`) |
| WebSocket support | Yes | No |
| Recommended | Yes | Only for 500+ routes |
| TypeScript performance | Optimized since Elysia 1.0 | Better for very large route sets |

For most projects, use Eden Treaty. Eden Fetch is only recommended if your single process contains more than 500 routes and you need to consume all routes in a single frontend codebase, where it has significantly better TypeScript performance.
