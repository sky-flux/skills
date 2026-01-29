# Handler

> **Source**: https://elysiajs.com/essential/handler

Handlers accept HTTP requests and return responses. They are the core building block of every Elysia route.

---

## Handler Patterns

### Inline Value (Static Response)

You can return a static value directly without a function. Elysia can compile these responses ahead of time for optimization:

```typescript
new Elysia()
    .get('/', 'Hello Elysia')
    .get('/video', file('kyuukurarin.mp4'))
    .listen(3000)
```

Providing an inline value is not a cache. Static resource values, headers, and status can be mutated dynamically using lifecycle hooks.

### Function Handler

Function handlers receive a `Context` object and return a response:

```typescript
new Elysia()
    .get('/', () => 'hello world')
    .listen(3000)
```

---

## Context API

Context represents request information unique to each request. It is not shared between requests except for `store` (global mutable state).

```typescript
new Elysia()
    .get('/', (context) => context.path)
```

### Context Properties

| Property | Type | Description |
|----------|------|-------------|
| `body` | Varies | HTTP message body, form data, or file upload |
| `query` | Object | Query string parameters (extracted after `?`) |
| `params` | Object | Path parameters parsed from the URL |
| `headers` | Object | HTTP headers (User-Agent, Content-Type, etc.) |
| `cookie` | Object | Mutable signal store for cookie get/set operations |
| `store` | Object | Global mutable store for the Elysia instance |
| `path` | String | Pathname of the request |
| `request` | Request | Web Standard Request object |
| `server` | Server | Bun server instance (port, requestIP, etc.) |

### Utility Functions

| Function | Description |
|----------|-------------|
| `status()` | Return response with custom status code |
| `redirect()` | Redirect to another resource |
| `set` | Mutable object for forming the response |

---

## status()

Returns a custom status code with type narrowing. This is the recommended approach for returning errors because it enables TypeScript to check return types against the response schema, provides autocompletion for type narrowing, and supports end-to-end type safety with Eden.

```typescript
new Elysia()
    .get('/', ({ status }) => status(418, 'Kirifuji Nagisa'))
    .listen(3000)
```

It is recommended to use the never-throw approach -- return `status` instead of throwing -- as it:
- Allows TypeScript to check if the return value correctly matches the response schema
- Provides autocompletion for type narrowing based on status code
- Enables type narrowing for error handling using Eden

---

## set

A mutable property for forming responses via `Context.set`.

### Setting Headers and Status

```typescript
new Elysia()
    .get('/', ({ set, status }) => {
        set.headers = { 'X-Teapot': 'true' }
        return status(418, 'I am a teapot')
    })
    .listen(3000)
```

### set.headers

Append or delete response headers as an object. Elysia provides auto-completion for lowercase headers for case-sensitivity consistency (e.g., use `set-cookie` rather than `Set-Cookie`):

```typescript
new Elysia()
    .get('/', ({ set }) => {
        set.headers['x-powered-by'] = 'Elysia'
        return 'a mimir'
    })
    .listen(3000)
```

### set.status (Legacy)

Sets a default status code if not provided. This is a legacy approach -- it cannot infer the return value type, so it cannot check if the return value correctly matches the response schema:

```typescript
new Elysia()
    .onBeforeHandle(({ set }) => {
        set.status = 418
        return 'Kirifuji Nagisa'
    })
    .get('/', () => 'hi')
    .listen(3000)
```

---

## redirect()

Redirect a request to another resource. When using redirect, the returned value is not required and will be ignored, as the response comes from another resource:

```typescript
new Elysia()
    .get('/', ({ redirect }) => {
        return redirect('https://youtu.be/whpVWVWBW4U?&t=8')
    })
    .get('/custom-status', ({ redirect }) => {
        // Redirect with custom status code
        return redirect('https://youtu.be/whpVWVWBW4U?&t=8', 302)
    })
    .listen(3000)
```

---

## Cookie Handling

Cookies use a mutable signal store pattern without explicit get/set methods:

```typescript
new Elysia()
    .get('/set', ({ cookie: { name } }) => {
        // Get cookie value
        name.value

        // Set cookie value
        name.value = 'New Value'
    })
```

---

## form() - FormData Response

Return FormData using the `form()` utility function:

```typescript
import { Elysia, form, file } from 'elysia'

new Elysia()
    .get('/', () => form({
        name: 'Tea Party',
        images: [file('nagi.webp'), file('mika.webp')]
    }))
    .listen(3000)
```

---

## file() - File Response

Return a single file without wrapping in FormData:

```typescript
import { Elysia, file } from 'elysia'

new Elysia()
    .get('/', file('nagi.webp'))
    .listen(3000)
```

---

## Stream

Elysia supports response streaming using generator functions.

### Basic Generator Stream

```typescript
const app = new Elysia()
    .get('/ok', function* () {
        yield 1
        yield 2
        yield 3
    })
```

### Server-Sent Events (SSE)

Wrap values in `sse()` to automatically set response headers to `text/event-stream` and format data as SSE events:

```typescript
import { Elysia, sse } from 'elysia'

new Elysia()
    .get('/sse', function* () {
        yield sse('hello world')
        yield sse({
            event: 'message',
            data: {
                message: 'This is a message',
                timestamp: new Date().toISOString()
            },
        })
    })
```

### Headers in Streams

Headers must be set **before** the first yield. Once the first chunk is yielded, Elysia sends headers to the client, so mutating headers after that point has no effect:

```typescript
const app = new Elysia()
    .get('/ok', function* ({ set }) {
        set.headers['x-name'] = 'Elysia'
        yield 1
        yield 2
        // This will do nothing - headers already sent
        set.headers['x-id'] = '1'
        yield 3
    })
```

### Conditional Stream

If a response is returned without yield, Elysia automatically converts the stream to a normal response:

```typescript
const app = new Elysia()
    .get('/ok', function* () {
        if (Math.random() > 0.5) return 'ok'
        yield 1
        yield 2
        yield 3
    })
```

### Automatic Cancellation

If the user cancels the request before response streaming completes, Elysia automatically stops the generator function.

### Stream with Eden

```typescript
import { Elysia } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .get('/ok', function* () {
        yield 1
        yield 2
        yield 3
    })

const { data, error } = await treaty(app).ok.get()
if (error) throw error

for await (const chunk of data)
    console.log(chunk)
```

---

## request

The Web Standard `Request` object, providing access to low-level request information:

```typescript
new Elysia()
    .get('/user-agent', ({ request }) => {
        return request.headers.get('user-agent')
    })
    .listen(3000)
```

---

## server (Bun Only)

Access the Bun server instance. The server is only available when the HTTP server is running with `listen`:

```typescript
new Elysia()
    .get('/port', ({ server }) => {
        return server?.port
    })
    .listen(3000)
```

### Request IP

```typescript
new Elysia()
    .get('/ip', ({ server, request }) => {
        return server?.requestIP(request)
    })
    .listen(3000)
```
