# Eden Internals

Source: `elysiajs/eden` repository

## Source Directory Structure

```
src/
  treaty/          # Legacy Treaty v1 (deprecated)
  treaty2/         # Current Treaty implementation
    index.ts       # Proxy-based client (~641 lines)
    types.ts       # Type inference engine
    ws.ts          # WebSocket client wrapper
  fetch/           # Low-level fetch-based client
    index.ts       # edenFetch implementation
    types.ts       # Fetch type definitions
  utils/           # Shared parsing utilities
  errors.ts        # EdenFetchError class
  types.ts         # Shared type utilities (IsNever, MaybeEmptyObject, Prettify, etc.)
  index.ts         # Package entry point
```

## Treaty Proxy Architecture

Treaty is Eden's primary API. It creates a type-safe client from an Elysia server definition using JavaScript `Proxy` objects.

### `treaty()` Entry Point

```typescript
export const treaty = <App extends Elysia<any, any, any, any, any, any, any>>(
    domain: string | App,
    config: Treaty.Config = {}
): Treaty.Create<App>
```

Accepts either:
- A URL string (for remote server access)
- An Elysia instance directly (for in-process testing, e.g., `treaty(app)` calls `app.handle()` directly)

When a string is passed, the function normalizes the domain (adds protocol if missing, detects localhost, strips trailing slash) and creates a proxy chain.

### Proxy Chain Mechanism

The `createProxy()` function builds a recursive `Proxy` that converts property access into URL path segments:

```typescript
const createProxy = (domain, config, paths = [], elysia?) =>
    new Proxy(() => {}, {
        get(_, param) {
            // Property access appends to path segments
            // Special case: 'index' is ignored (root path)
            return createProxy(domain, config,
                param === 'index' ? paths : [...paths, param], elysia)
        },
        apply(_, __, [body, options]) {
            // Function call triggers the HTTP request
            // Last path segment becomes the HTTP method
            const methodPaths = [...paths]
            const method = methodPaths.pop()
            const path = '/' + methodPaths.join('/')
            // ... builds and executes fetch request
        }
    })
```

**Example flow:**
```typescript
const client = treaty<App>('localhost:3000')
client.api.users.get()
// get -> paths = ['api', 'users']
// apply -> method = 'get', path = '/api/users'
```

### Request Construction

When the proxy's `apply` trap fires (i.e., when a method like `.get()`, `.post()` is called):

1. **Method extraction**: The last path segment becomes the HTTP method
2. **Query handling**: For GET/HEAD, the first argument contains `{ query }`. For others, the second argument optionally has `{ query }`
3. **Header processing**: `processHeaders()` resolves headers from multiple possible formats (function, object, Headers instance, array of key-value pairs)
4. **WebSocket**: If method is `subscribe`, creates an `EdenWS` instance instead of HTTP fetch
5. **File detection**: `hasFile()` scans the body for `File`, `Blob`, or `FileList` instances
6. **Body serialization**:
   - If files detected: builds `FormData` (handles arrays, nested objects, `FileList`)
   - If object: `JSON.stringify()` with `application/json` content-type
   - Otherwise: sends as `text/plain`
7. **onRequest hooks**: Runs interceptors that can modify the fetch init before sending
8. **Fetch execution**: Either `elysia.handle(new Request(...))` for in-process or `fetcher(url, init)` for remote

### Response Handling

The response is processed based on `Content-Type`:

| Content-Type | Handling |
|---|---|
| `text/event-stream` | `streamResponse()` - async generator yielding parsed SSE events |
| `application/json` | `JSON.parse()` with date revival via `parseStringifiedDate()` |
| `application/octet-stream` | `response.arrayBuffer()` |
| `multipart/form-data` | `response.formData()` converted to object |
| Other | `response.text()` with `parseStringifiedValue()` |

The return shape is always:
```typescript
{ data, error, response, status, headers }
```

Where `error` is an `EdenFetchError` if status >= 300 or < 200.

### SSE Streaming Support

`streamResponse()` is an async generator that parses Server-Sent Events:

1. Reads the response body as a stream via `body.getReader()`
2. Decodes chunks with `TextDecoder('utf-8')`
3. Buffers partial data and extracts complete events (delimited by `\n\n`)
4. Parses each event block into `{ event, data, retry, id }` fields per SSE spec
5. Yields parsed event objects

### onRequest / onResponse Hooks

Treaty supports interceptor hooks:

```typescript
treaty<App>('localhost:3000', {
    onRequest: [(path, init) => { /* modify init */ }],
    onResponse: [(response) => { /* transform response */ }]
})
```

- `onRequest` can return a modified `RequestInit` to merge
- `onResponse` can return transformed data to short-circuit default parsing

## EdenWS - WebSocket Client

`src/treaty2/ws.ts` wraps the native `WebSocket` with type-safe methods:

```typescript
export class EdenWS<in out Schema extends InputSchema<any> = {}> {
    ws: WebSocket
    constructor(public url: string) { this.ws = new WebSocket(url) }

    send(data: Schema['body'] | Schema['body'][]): this
    on<K extends keyof WebSocketEventMap>(type, listener, options?): this
    off<K extends keyof WebSocketEventMap>(type, listener, options?): this
    subscribe(onMessage, options?): this
    close(): this
}
```

Key features:
- **Type-safe send**: Body type is inferred from the server's WebSocket schema
- **Type-safe receive**: Message events are typed as `Schema['response'][200]`
- **Auto-parsing**: Message events are automatically parsed via `parseMessageEvent()`
- **Chainable API**: All methods return `this` for fluent chaining
- **Protocol detection**: URL protocol is converted from `http://` to `ws://` or `https://` to `wss://`

## edenFetch - Low-Level Client

`src/fetch/index.ts` provides a simpler, function-based client:

```typescript
export const edenFetch = <App extends Elysia<any, any, any, any, any, any, any>>(
    server: string,
    config?: EdenFetch.Config
): EdenFetch.Create<App>
```

Returns a function that takes `(endpoint, options)` where:
- `endpoint` is a typed path string with params replaced at runtime
- `options` includes `{ query, params, body, ...fetchOptions }`

Response parsing follows the same content-type dispatch as Treaty.

### edenFetch vs Treaty

| Feature | edenFetch | Treaty |
|---|---|---|
| API Style | Function call with path string | Proxy chain mimicking URL structure |
| Type Safety | Path string literal types | Property access chain types |
| WebSocket | Not supported | Full WebSocket support via `.subscribe()` |
| SSE Streaming | Not supported | Async generator support |
| Request hooks | Not supported | `onRequest` / `onResponse` hooks |
| Use Case | Simple REST calls | Full-featured type-safe client |

## Type Propagation System

### `Treaty.Create<App>`

The root type extracts the `~Routes` internal property from an Elysia instance and maps it to a proxy interface:

```typescript
export type Create<App extends Elysia<any, any, any, any, any, any, any>> =
    App extends { '~Routes': infer Schema extends Record<any, any> }
        ? Prettify<Sign<Schema>> & CreateParams<Schema>
        : 'Please install Elysia before using Eden'
```

### `Treaty.Sign<Route>`

Converts route records into proxy-accessible properties:
- Skips dynamic parameter segments (`:param`) at the type level
- Maps HTTP methods to function signatures with correct body/response types
- Handles `subscribe` method separately for WebSocket routes

### Response Typing

Response types use discriminated unions based on status codes:

```typescript
type ReplaceGeneratorWithAsyncGenerator<RecordType>
```

This utility type converts server-side `Generator` return types to client-side `AsyncGenerator` types, enabling type-safe SSE streaming consumption.

### Error Typing

`EdenFetchError` carries the status code and response data:
- Success responses (200-299): `{ data: T, error: null }`
- Error responses: `{ data: null, error: EdenFetchError<Status, ErrorBody> }`

The union type ensures TypeScript requires narrowing before accessing `.data`.

## Date Revival

Eden automatically revives ISO date strings in JSON responses using `parseStringifiedDate()`. The parser detects ISO 8601 format strings and converts them back to `Date` objects during `JSON.parse()` reviver.

## File Upload Handling

Treaty handles file uploads by:
1. Detecting `File`, `Blob`, or `FileList` in the body via `hasFile()`
2. Building `FormData` with correct handling for:
   - Single files: appended directly
   - File arrays (`FileList`): each file appended separately under the same key
   - Mixed arrays with non-file objects: stringified via `JSON.stringify()`
   - Nested objects: stringified
3. Not setting `Content-Type` manually (lets browser set multipart boundary)
4. On server-side (no `FileList`): creates new `File` instances from `Blob` via `FileReader`
