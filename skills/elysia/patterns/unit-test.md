# Unit Test
Unit testing patterns for ElysiaJS using Bun's built-in test runner and Eden Treaty.

## Basic Setup

Elysia follows the Web Standard, using `Request` and `Response` classes. The `handle` method simulates HTTP requests without starting a server:

```typescript
// test/index.test.ts
import { describe, expect, it } from 'bun:test'
import { Elysia } from 'elysia'

describe('Elysia', () => {
    it('returns a response', async () => {
        const app = new Elysia().get('/', () => 'hi')

        const response = await app
            .handle(new Request('http://localhost/'))
            .then((res) => res.text())

        expect(response).toBe('hi')
    })
})
```

### Running Tests

```bash
bun test
```

Bun includes a built-in test runner with a Jest-like API via the `bun:test` module. Alternative frameworks like Jest are also supported.

## URL Requirement

Requests passed to `handle` must use a fully valid URL, not a partial path.

| Format                   | Valid |
| ------------------------ | ----- |
| `http://localhost/user`  | Yes   |
| `/user`                  | No    |

## Eden Treaty Testing

For end-to-end type-safe testing, use Eden Treaty. It provides typed request/response without manually constructing `Request` objects:

```typescript
// test/index.test.ts
import { describe, expect, it } from 'bun:test'
import { Elysia } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia().get('/hello', 'hi')
const api = treaty(app)

describe('Elysia', () => {
    it('returns a response', async () => {
        const { data, error } = await api.hello.get()
        expect(data).toBe('hi')
    })
})
```

Eden Treaty wraps the Elysia instance directly — no running server needed. See the Eden Treaty unit test documentation for additional setup details.
