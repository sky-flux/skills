# Eden Treaty Legacy (v1)

Eden Treaty v1 (`edenTreaty`) is the original object-like client for consuming Elysia servers with end-to-end type safety. It has been superseded by Eden Treaty v2 (`treaty`). New projects should use v2 instead.

Source: https://elysiajs.com/eden/treaty/legacy

## Setup

### Server

Export the Elysia app type for client consumption:

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

Import `edenTreaty` (v1) and instantiate with the server type:

```typescript
// client.ts
import { edenTreaty } from '@elysiajs/eden'
import type { App } from './server'

const app = edenTreaty<App>('http://localhost:3000')

const { data, error } = await app.hi.get()
```

## Path and Parameter Mapping

Routes are transformed into chainable object properties:

| Path | Treaty v1 |
|------|-----------|
| `/path` | `.path` |
| `/nested/path` | `.nested.path` |
| `/id/:id` | `.id['<value>']` |

Dynamic path parameters are auto-mapped by name. For example, `/id/:id` becomes `.id.<value>`.

## Query and Fetch Options

Two special properties extend request functionality:

- **`$query`** -- Append query parameters to the request
- **`$fetch`** -- Pass standard Fetch API options (headers, credentials, etc.)

```typescript
const { data } = await app.items.get({
    $query: { page: 1, limit: 10 },
    $fetch: {
        headers: {
            'Authorization': 'Bearer token'
        }
    }
})
```

## Response Handling

Responses use a discriminated union pattern. Both `data` and `error` are nullable and fully typed:

```typescript
const { data, error } = await app.endpoint.post({
    id: 1,
    name: 'example'
})

if (error) {
    // error includes status code and typed value
    console.log(error.status)
    console.log(error.value)
} else {
    // data is fully typed based on server response
    console.log(data)
}
```

When response types are explicitly defined on the Elysia server, error types narrow by status code automatically.

## WebSocket Support

WebSocket routes use the same path syntax but call `.subscribe()`:

```typescript
const chat = app.chat.subscribe()

chat.subscribe((message) => {
    console.log('Received:', message)
})

chat.send('Hello')
```

Returns `EdenWebSocket`, which extends the native WebSocket class with type safety.

## File Upload

File uploads accept `File`, `FileList`, or `Blob` objects. Content type is automatically set to `multipart/form-data`:

```typescript
const { data } = await app.upload.post({
    file: fileInput.files[0]
})
```

## Migration to Treaty v2

Eden Treaty v2 (`treaty`) replaces v1 (`edenTreaty`) with enhanced functionality.

### Key Differences

| Feature | v1 (`edenTreaty`) | v2 (`treaty`) |
|---------|-------------------|---------------|
| Import | `import { edenTreaty }` | `import { treaty }` |
| Instantiation | `edenTreaty<App>(url)` | `treaty<App>(url)` |
| Dynamic paths | `.id['value']` | `.id({ id: 'value' })` |
| Response pattern | `{ data, error }` | `{ data, error }` (same) |

### Migration Steps

1. Update the import from `edenTreaty` to `treaty`:
```typescript
// Before (v1)
import { edenTreaty } from '@elysiajs/eden'
const app = edenTreaty<App>('http://localhost:3000')

// After (v2)
import { treaty } from '@elysiajs/eden'
const app = treaty<App>('http://localhost:3000')
```

2. Update dynamic path parameter syntax to use function calls:
```typescript
// Before (v1)
app.item['skadi'].get()

// After (v2)
app.item({ name: 'Skadi' }).get()
```

3. The response pattern (`{ data, error }`) remains the same in v2.

See also:
- `eden/treaty-overview.md` -- Eden Treaty v2 overview
- `eden/treaty-parameters.md` -- v2 parameter handling
- `eden/treaty-response.md` -- v2 response handling
- `eden/treaty-config.md` -- v2 configuration
