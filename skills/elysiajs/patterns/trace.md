# Trace
Performance monitoring for Elysia. The trace feature helps identify performance bottlenecks by injecting code before and after each lifecycle event, enabling measurement of execution times and interaction with function execution.

**Important limitation:** Trace requires static functions known at compile time and does not work with dynamic mode (`aot: false`), as it would significantly impact performance.

## Trace Method

Use the `trace` method on an Elysia instance, passing a callback function executed for each lifecycle event. Listen to specific lifecycles by adding an `on` prefix followed by the lifecycle name (e.g., `onHandle`):

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    .trace(async ({ onHandle }) => {
        onHandle(({ begin, onStop }) => {
            onStop(({ end }) => {
                console.log('handle took', end - begin, 'ms')
            })
        })
    })
    .get('/', () => 'Hi')
    .listen(3000)
```

## Children

Every lifecycle event except `handle` contains child events (arrays of functions). Use `onEvent` to listen to each child in order:

```typescript
import { Elysia } from 'elysia'

const sleep = (time = 1000) =>
    new Promise((resolve) => setTimeout(resolve, time))

const app = new Elysia()
    .trace(async ({ onBeforeHandle }) => {
        onBeforeHandle(({ total, onEvent }) => {
            console.log('total children:', total)

            onEvent(({ onStop }) => {
                onStop(({ elapsed }) => {
                    console.log('child took', elapsed, 'ms')
                })
            })
        })
    })
    .get('/', () => 'Hi', {
        beforeHandle: [
            function setup() {},
            async function delay() {
                await sleep()
            }
        ]
    })
    .listen(3000)
```

In this example, `total children` equals `2` because two functions exist in the `beforeHandle` event. Each child duration prints via `onEvent`.

## Trace Parameter

Access trace parameters via the callback:

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    .trace((parameter) => {
        // access parameter properties here
    })
    .get('/', () => 'Hi')
    .listen(3000)
```

### Trace Parameter Properties

- **id** (`number`) - Randomly generated unique identifier per request
- **context** (`Context`) - Elysia's Context object containing `set`, `store`, `query`, `params`
- **set** (`Context.set`) - Shortcut to set headers or status
- **store** (`Singleton.store`) - Shortcut to access context data
- **time** (`number`) - Request timestamp

### Available Lifecycle Events

- **onRequest** - Notified of every new request
- **onParse** - Array of functions parsing the body
- **onTransform** - Transform request and context before validation
- **onBeforeHandle** - Custom requirements checked before main handler
- **onHandle** - Function assigned to the path
- **onAfterHandle** - Interact with response before client delivery
- **onMapResponse** - Map returned value into Web Standard Response
- **onError** - Handle errors during request processing
- **onAfterResponse** - Cleanup after response delivery

## Trace Listener

Each lifecycle listener receives a parameter object:

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    .trace(({ onBeforeHandle }) => {
        onBeforeHandle((parameter) => {
            // access listener properties here
        })
    })
    .get('/', () => 'Hi')
    .listen(3000)
```

### Trace Listener Properties

- **name** (`string`) - Function name (or `anonymous` if unnamed)
- **begin** (`number`) - Function start time
- **end** (`Promise<number>`) - Function end time (resolved when complete)
- **error** (`Promise<Error | null>`) - Thrown error during lifecycle
- **onStop** (`callback?: (detail: TraceEndDetail) => any`) - Callback executing when lifecycle ends

### Using onStop

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
    .trace(({ onBeforeHandle, set }) => {
        onBeforeHandle(({ onStop }) => {
            onStop(({ elapsed }) => {
                set.headers['X-Elapsed'] = elapsed.toString()
            })
        })
    })
    .get('/', () => 'Hi')
    .listen(3000)
```

It is recommended to mutate context in the `onStop` function as there is a lock mechanism to ensure the context is mutated successfully before moving on to the next lifecycle event.

## TraceEndDetail

Parameters passed to the `onStop` callback:

- **end** (`number`) - Function end time
- **error** (`Error | null`) - Thrown error during lifecycle
- **elapsed** (`number`) - Elapsed time (calculated as `end - begin`)
