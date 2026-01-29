# Eden Treaty Overview

Eden Treaty is an object representation to interact with an Elysia server, featuring type safety, auto-completion, and error handling.

## Setup

### Server

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

### Client

```typescript
// client.ts
import { treaty } from '@elysiajs/eden'
import type { App } from './server'

const app = treaty<App>('localhost:3000')

// response type: 'Hi Elysia'
const { data, error } = await app.hi.get()
```

## Tree-Like Syntax

HTTP Path is a resource indicator for a file system tree. Each level is separated by `/` (slash). In JavaScript, instead of using `/` we use `.` (dot) to access deeper resources.

### Path to Treaty Mapping

| Path | Treaty |
|------|--------|
| `/` | `/` |
| `/hi` | `.hi` |
| `/deep/nested` | `.deep.nested` |

### HTTP Method Mapping

| Path | Method | Treaty |
|------|--------|--------|
| `/` | GET | `.get()` |
| `/hi` | GET | `.hi.get()` |
| `/deep/nested` | GET | `.deep.nested.get()` |
| `/deep/nested` | POST | `.deep.nested.post()` |

## Dynamic Path Parameters

Dynamic path parameters cannot be expressed using dot notation directly. To handle this, specify a dynamic path using a function with a key-value pair.

Incorrect:
```typescript
// Unclear what the value is supposed to represent
treaty.item['skadi'].get()
```

Correct:
```typescript
// Clear that the dynamic path parameter is 'name'
treaty.item({ name: 'Skadi' }).get()
```

### Dynamic Path Reference

| Path | Treaty |
|------|--------|
| `/item` | `.item` |
| `/item/:name` | `.item({ name: 'Skadi' })` |
| `/item/:name/id` | `.item({ name: 'Skadi' }).id` |

## Complete Example

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .get('/', () => 'Hello')
    .get('/hi', () => 'Hi Elysia')
    .get('/deep/nested', () => 'deep')
    .get('/item/:name', ({ params: { name } }) => name)
    .get('/item/:name/id', ({ params: { name } }) => `${name}-id`)
    .post('/mirror', ({ body }) => body, {
        body: t.Object({
            id: t.Number(),
            name: t.String()
        })
    })
    .listen(3000)

export type App = typeof app

// Client usage
const api = treaty<App>('localhost:3000')

// GET /
const { data: root } = await api.get()

// GET /hi
const { data: hi } = await api.hi.get()

// GET /deep/nested
const { data: nested } = await api.deep.nested.get()

// GET /item/:name
const { data: item } = await api.item({ name: 'Skadi' }).get()

// GET /item/:name/id
const { data: itemId } = await api.item({ name: 'Skadi' }).id.get()

// POST /mirror
const { data: mirror } = await api.mirror.post({
    id: 1895,
    name: 'Skadi'
})
```
