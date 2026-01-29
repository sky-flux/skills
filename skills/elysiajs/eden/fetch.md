# Eden Fetch

Eden Fetch is a fetch-like alternative to Eden Treaty. With Eden Fetch, you can interact with an Elysia server in a type-safe manner using Fetch API syntax.

## Server Setup

```typescript
// server.ts
import { Elysia, t } from 'elysia'

const app = new Elysia()
    .get('/hi', () => 'Hi Elysia')
    .get('/id/:id', ({ params: { id } }) => id)
    .post('/mirror', ({ body }) => body, {
        body: t.Object({
            id: t.Number(),
            name: t.String()
        })
    })
    .listen(3000)

export type App = typeof app
```

## Basic Usage

```typescript
import { edenFetch } from '@elysiajs/eden'
import type { App } from './server'

const fetch = edenFetch<App>('http://localhost:3000')

// response type: 'Hi Elysia'
const pong = await fetch('/hi', {})

// response type: 1895
const id = await fetch('/id/:id', {
    params: {
        id: '1895'
    }
})

// response type: { id: 1895, name: 'Skadi' }
const nendoroid = await fetch('/mirror', {
    method: 'POST',
    body: {
        id: 1895,
        name: 'Skadi'
    }
})
```

## Error Handling

You can handle errors the same way as Eden Treaty:

```typescript
import { edenFetch } from '@elysiajs/eden'
import type { App } from './server'

const fetch = edenFetch<App>('http://localhost:3000')

const { data: nendoroid, error } = await fetch('/mirror', {
    method: 'POST',
    body: {
        id: 1895,
        name: 'Skadi'
    }
})

if (error) {
    switch (error.status) {
        case 400:
        case 401:
            throw error.value
            break

        case 500:
        case 502:
            throw error.value
            break

        default:
            throw error.value
            break
    }
}

const { id, name } = nendoroid
```

## When to Use Eden Fetch over Eden Treaty

Unlike Elysia < 1.0, Eden Fetch is **not** faster than Eden Treaty anymore.

The preference is based on you and your team agreement, however we recommend using Eden Treaty instead.

### Historical Context (Elysia < 1.0)

Using Eden Treaty required a lot of down-level iteration to map all possible types in a single go, while in contrast, Eden Fetch can be lazily executed until you pick a route.

With complex types and a lot of server routes, using Eden Treaty on a low-end development device could lead to slow type inference and auto-completion.

But as Elysia has tweaked and optimized types and inference, Eden Treaty now performs very well with a considerable amount of routes.

### Recommendation

If your single process contains **more than 500 routes**, and you need to consume all of the routes in a single frontend codebase, then you might want to use Eden Fetch as it has significantly better TypeScript performance than Eden Treaty.

| Criteria | Eden Treaty | Eden Fetch |
|----------|-------------|------------|
| Syntax style | Object-like | Fetch-like |
| WebSocket support | Yes | No |
| Performance (< 500 routes) | Equal | Equal |
| Performance (500+ routes) | Good | Better |
| Recommended | Yes | Only for very large route sets |
