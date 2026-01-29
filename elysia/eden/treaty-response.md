# Eden Treaty Response

Once a fetch method is called, Eden Treaty returns a `Promise` containing an object with the following properties:

| Property | Type | Description |
|----------|------|-------------|
| `data` | Response type or `null` | Returned value of the response (2xx status) |
| `error` | Error type or `null` | Returned value from the response (>= 3xx status) |
| `response` | `Response` | Web Standard Response class |
| `status` | `number` | HTTP status code |
| `headers` | `FetchRequestInit['headers']` | Response headers |

## Error Handling and Type Narrowing

Error handling is required to unwrap response data; otherwise the value remains nullable. Elysia supplies an `error()` helper function, and Eden provides type narrowing for error values.

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .post('/user', ({ body: { name }, status }) => {
        if (name === 'Otto') return status(400)

        return name
    }, {
        body: t.Object({
            name: t.String()
        })
    })
    .listen(3000)

const api = treaty<typeof app>('localhost:3000')

const submit = async (name: string) => {
    const { data, error } = await api.user.post({
        name
    })

    // type: string | null
    console.log(data)

    if (error)
        switch (error.status) {
            case 400:
                // Error type will be narrowed down
                throw error.value

            default:
                throw error.value
        }

    // Once the error is handled, type will be unwrapped
    // type: string
    return data
}
```

> **Tip:** HTTP status >= 300 results in `data = null` and a populated `error`. Otherwise, the response populates `data`.

By default, Elysia infers `error` and `response` types automatically to TypeScript, and Eden provides auto-completion and type narrowing.

## Stream Response

Eden interprets stream responses or Server-Sent Events as `AsyncGenerator`, enabling `for await` loop consumption.

### Generator Stream

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

### Server-Sent Events (SSE)

```typescript
import { Elysia, sse } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .get('/ok', function* () {
        yield sse({
            event: 'message',
            data: 1
        })
        yield sse({
            event: 'message',
            data: 2
        })
        yield sse({
            event: 'end'
        })
    })

const { data, error } = await treaty(app).ok.get()
if (error) throw error

for await (const chunk of data)
    console.log(chunk)
```

## Utility Types

Eden Treaty provides utility types to extract `data` and `error` types from responses:

- `Treaty.Data<T>` - Extract the data type
- `Treaty.Error<T>` - Extract the error type

```typescript
import { Elysia, t } from 'elysia'
import { treaty, Treaty } from '@elysiajs/eden'

const app = new Elysia()
    .post('/user', ({ body: { name }, status }) => {
        if (name === 'Otto') return status(400)

        return name
    }, {
        body: t.Object({
            name: t.String()
        })
    })
    .listen(3000)

const api = treaty<typeof app>('localhost:3000')

// Extract type from the endpoint method
type UserData = Treaty.Data<typeof api.user.post>

// Alternatively extract from a response
const response = await api.user.post({
    name: 'Saltyaom'
})
type UserDataFromResponse = Treaty.Data<typeof response>

// Extract error type
type UserError = Treaty.Error<typeof api.user.post>
```
