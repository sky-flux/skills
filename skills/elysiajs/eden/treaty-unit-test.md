# Eden Treaty Unit Test

Eden Treaty can be used for unit testing Elysia servers with zero network overhead by passing an Elysia instance directly instead of a URL. This creates `Request` objects and passes them to `Elysia.handle` directly, without starting a server or creating network requests.

## Basic Unit Test

```typescript
// test/index.test.ts
import { describe, expect, it } from 'bun:test'
import { Elysia } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia().get('/hello', 'hi')
const api = treaty(app)

describe('Elysia', () => {
    it('returns a response', async () => {
        const { data } = await api.hello.get()

        expect(data).toBe('hi')
    })
})
```

Key points:
- Pass the Elysia instance directly to `treaty()` (no URL needed)
- No generic type parameter needed (Eden infers from the instance)
- No server needs to be started
- Full end-to-end type safety is preserved in tests

## Type Safety Test

To perform type safety testing, run `tsc` on test folders:

```bash
tsc --noEmit test/**/*.ts
```

This verifies type integrity for both client and server, which is particularly useful during migrations.

## Complete Test Example

```typescript
// test/api.test.ts
import { describe, expect, it } from 'bun:test'
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .get('/hello', 'hi')
    .get('/id/:id', ({ params: { id } }) => id)
    .post('/mirror', ({ body }) => body, {
        body: t.Object({
            id: t.Number(),
            name: t.String()
        })
    })

const api = treaty(app)

describe('Elysia API', () => {
    it('GET /hello returns hi', async () => {
        const { data } = await api.hello.get()
        expect(data).toBe('hi')
    })

    it('GET /id/:id returns the id', async () => {
        const { data } = await api.id({ id: '1895' }).get()
        expect(data).toBe('1895')
    })

    it('POST /mirror returns the body', async () => {
        const { data } = await api.mirror.post({
            id: 1895,
            name: 'Skadi'
        })
        expect(data).toEqual({
            id: 1895,
            name: 'Skadi'
        })
    })

    it('handles errors correctly', async () => {
        const { data, error, status } = await api.hello.get()

        if (error) {
            // Type narrowing works in tests too
            throw error.value
        }

        expect(data).toBe('hi')
    })
})
```

## Why Use Eden for Testing

| Benefit | Description |
|---------|-------------|
| Zero network overhead | Requests go directly to `Elysia.handle`, no HTTP involved |
| Type safety | Full end-to-end type checking in your tests |
| No server startup | No need to call `.listen()` or manage ports |
| Same API | Test code looks identical to client code |
| Migration safety | Run `tsc --noEmit` to catch type regressions |

## Running Tests

```bash
# Run unit tests
bun test

# Run type-checking on tests
tsc --noEmit test/**/*.ts
```
