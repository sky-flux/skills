# Eden Treaty Config

Eden Treaty accepts 2 parameters:

1. **urlOrInstance** - URL endpoint (string) or Elysia instance
2. **options** (optional) - Customize fetch behavior

## urlOrInstance

### URL Endpoint (string)

If a URL endpoint is passed, Eden Treaty will use `fetch` or `config.fetcher` to create a network request.

```typescript
import { treaty } from '@elysiajs/eden'
import type { App } from './server'

const api = treaty<App>('localhost:3000')
```

You may or may not specify a protocol. Elysia appends the protocol automatically:

1. If protocol is specified, use the URL directly
2. If the URL is localhost and ENV is not production, use `http`
3. Otherwise use `https`

This also applies to WebSocket for determining between `ws://` and `wss://`.

### Elysia Instance (direct)

If an Elysia instance is passed, Eden Treaty creates a `Request` class and passes it to `Elysia.handle` directly without creating a network request. This allows interaction with the Elysia server without request overhead or the need to start a server.

```typescript
import { Elysia } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .get('/hi', 'Hi Elysia')
    .listen(3000)

const api = treaty(app)
```

When an instance is passed, the generic type parameter is not needed as Eden Treaty infers the type from the parameter directly.

This pattern is recommended for:
- Unit testing
- Type-safe reverse proxy servers
- Micro-services

## Options

The optional second parameter customizes fetch behavior:

| Option | Description |
|--------|-------------|
| `fetch` | Default parameters for fetch initialization (RequestInit) |
| `headers` | Define default headers |
| `fetcher` | Custom fetch function (e.g., Axios, unfetch) |
| `onRequest` | Intercept and modify fetch request before firing |
| `onResponse` | Intercept and modify fetch response |

### fetch

Default parameters appended to the 2nd parameter of fetch, extending `Fetch.RequestInit`:

```typescript
treaty<App>('localhost:3000', {
    fetch: {
        credentials: 'include'
    }
})
```

Equivalent to:
```typescript
fetch('http://localhost:3000', {
    credentials: 'include'
})
```

### headers

Provide additional default headers. This is a shorthand for `options.fetch.headers`.

#### Headers as Object

```typescript
treaty<App>('localhost:3000', {
    headers: {
        'X-Custom': 'Griseo'
    }
})
```

#### Headers as Function

Return custom headers based on conditions:

```typescript
treaty<App>('localhost:3000', {
    headers(path, options) {
        if (path.startsWith('user'))
            return {
                authorization: 'Bearer 12345'
            }
    }
})
```

The function accepts 2 parameters:
- `path` (string) - the path being requested (hostname excluded, e.g. `/user/griseo`)
- `options` (RequestInit) - parameters passed through the 2nd parameter of fetch

#### Headers as Array

Define multiple header functions:

```typescript
treaty<App>('localhost:3000', {
    headers: [
        (path, options) => {
            if (path.startsWith('user'))
                return {
                    authorization: 'Bearer 12345'
                }
        }
    ]
})
```

Eden Treaty will run all functions even if a value is already returned.

### Headers Priority

Eden Treaty prioritizes headers in this order (highest to lowest):

1. **Inline method** - Passed in the method function directly
2. **headers** - Passed in `config.headers` (if array, later items take priority)
3. **fetch** - Passed in `config.fetch.headers`

Example:

```typescript
const api = treaty<App>('localhost:3000', {
    headers: {
        authorization: 'Bearer Aponia'
    }
})

api.profile.get({
    headers: {
        authorization: 'Bearer Griseo'
    }
})
```

Result: `authorization` will be `'Bearer Griseo'` (inline takes priority).

### fetcher

Provide a custom fetch function instead of the environment's default:

```typescript
treaty<App>('localhost:3000', {
    fetcher(url, options) {
        return fetch(url, options)
    }
})
```

Recommended when using a client other than fetch (e.g., Axios, unfetch).

### onRequest

Intercept and modify the fetch request before firing. Return an object to append values to `RequestInit`:

```typescript
treaty<App>('localhost:3000', {
    onRequest(path, options) {
        if (path.startsWith('user'))
            return {
                headers: {
                    authorization: 'Bearer 12345'
                }
            }
    }
})
```

If a value is returned, Eden Treaty performs a shallow merge for the returned value and `value.headers`.

Parameters:
- `path` (string) - the path being requested (hostname excluded)
- `options` (RequestInit) - parameters passed through the 2nd parameter of fetch

#### onRequest as Array

```typescript
treaty<App>('localhost:3000', {
    onRequest: [
        (path, options) => {
            if (path.startsWith('user'))
                return {
                    headers: {
                        authorization: 'Bearer 12345'
                    }
                }
        }
    ]
})
```

Eden Treaty will run all functions even if a value is already returned.

### onResponse

Intercept and modify the fetch response, or return a new value:

```typescript
treaty<App>('localhost:3000', {
    onResponse(response) {
        if (response.ok)
            return response.json()
    }
})
```

Parameters:
- `response` (Response) - Web Standard Response normally returned from `fetch`

#### onResponse as Array

```typescript
treaty<App>('localhost:3000', {
    onResponse: [
        (response) => {
            if (response.ok)
                return response.json()
        }
    ]
})
```

Unlike `headers` and `onRequest`, Eden Treaty will loop through functions until a returned value is found or an error is thrown. The returned value will be used as the new response.
