# WebSocket
WebSocket patterns in ElysiaJS — real-time bidirectional communication, validation, and connection management.

## Overview

Unlike HTTP's request-response cycle, WebSocket establishes a persistent connection for direct bidirectional messaging between client and server.

## Basic Implementation

Use the `.ws()` method to create a WebSocket endpoint:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .ws('/ws', {
        message(ws, message) {
            ws.send(message)
        }
    })
    .listen(3000)
```

## Handlers

| Handler         | Description                                       |
| --------------- | ------------------------------------------------- |
| `open`          | Called when a new connection is established        |
| `message`       | Called when a message is received                  |
| `close`         | Called when the connection is terminated           |
| `drain`         | Called when the server is ready to accept data     |

Middleware hooks are also available: `parse`, `beforeHandle`, `transform`.

## Validation

WebSocket routes support schema-based validation, similar to HTTP routes. Validated fields include:

- `message` (incoming data)
- `query` parameters
- `params` (path parameters)
- `headers`
- `cookie`
- `response`

Stringified JSON messages are automatically parsed before validation.

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
    .ws('/ws', {
        message(ws, message) {
            ws.send(message)
        },
        body: t.Object({
            text: t.String()
        })
    })
    .listen(3000)
```

## Configuration Options

| Option                    | Default  | Description                                  |
| ------------------------- | -------- | -------------------------------------------- |
| `perMessageDeflate`       | `false`  | Enable per-message compression               |
| `maxPayloadLength`        | —        | Maximum allowed message size                  |
| `idleTimeout`             | `120`    | Seconds before closing idle connections       |
| `backpressureLimit`       | `16 MB`  | Buffer capacity per connection                |
| `closeOnBackpressureLimit`| `false`  | Auto-close when buffer limit is exceeded      |

The underlying implementation uses uWebSocket, which Bun supports natively.
