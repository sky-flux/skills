# Eden Treaty WebSocket

Eden Treaty supports WebSocket connections using the `subscribe` method.

## Basic Usage

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .ws('/chat', {
        body: t.String(),
        response: t.String(),
        message(ws, message) {
            ws.send(message)
        }
    })
    .listen(3000)

const api = treaty<typeof app>('localhost:3000')

const chat = api.chat.subscribe()

chat.subscribe((message) => {
    console.log('got', message)
})

chat.on('open', () => {
    chat.send('hello from client')
})
```

## Parameters

`.subscribe()` accepts the same parameters as `get` and `head`:

```typescript
// With query parameters
const chat = api.chat.subscribe({
    query: {
        room: 'general'
    }
})

// With headers
const chat = api.chat.subscribe({
    headers: {
        authorization: 'Bearer 12345'
    }
})
```

## Response: EdenWS

`Eden.subscribe` returns `EdenWS` which extends the [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/WebSocket) class, resulting in identical syntax to the native WebSocket API.

### Available Methods

| Method | Description |
|--------|-------------|
| `chat.subscribe(callback)` | Listen for incoming messages |
| `chat.send(data)` | Send a message to the server |
| `chat.on(event, callback)` | Listen for WebSocket events (open, close, error, message) |
| `chat.close()` | Close the WebSocket connection |
| `chat.raw` | Access the native WebSocket instance |

### Event Listeners

```typescript
const chat = api.chat.subscribe()

// Listen for messages
chat.subscribe((message) => {
    console.log('got', message)
})

// Connection opened
chat.on('open', () => {
    chat.send('hello from client')
})

// Connection closed
chat.on('close', () => {
    console.log('disconnected')
})

// Error occurred
chat.on('error', (error) => {
    console.error('WebSocket error:', error)
})
```

### Raw WebSocket Access

If more control is needed, `EdenWebSocket.raw` can be accessed to interact with the native WebSocket API:

```typescript
const chat = api.chat.subscribe()

// Access native WebSocket
const nativeWs = chat.raw
```

## Complete Example

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

// Server
const app = new Elysia()
    .ws('/chat', {
        body: t.String(),
        response: t.String(),
        message(ws, message) {
            ws.send(message)
        }
    })
    .listen(3000)

// Client
const api = treaty<typeof app>('localhost:3000')

const chat = api.chat.subscribe()

chat.subscribe((message) => {
    console.log('got', message)
})

chat.on('open', () => {
    chat.send('hello from client')
})

chat.on('close', () => {
    console.log('disconnected')
})
```

> **Note:** Eden Fetch does not provide WebSocket support. Use Eden Treaty for WebSocket connections.
