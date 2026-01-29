# Features

> **Sources (4 pages consolidated):**
> - https://elysiajs.com/tutorial/features/mount
> - https://elysiajs.com/tutorial/features/openapi
> - https://elysiajs.com/tutorial/features/end-to-end-type-safety
> - https://elysiajs.com/tutorial/features/unit-test

---

## Mount

Elysia provides a `.mount()` method to integrate with other Web Standard-compatible backend frameworks like Hono and H3. This enables gradual migration or multi-framework usage within a single application.

### Code Example

```typescript
import { Elysia, t } from 'elysia'
import { Hono } from 'hono'

const hono = new Hono()
	.get('/', (c) => c.text('Hello from Hono'))

new Elysia()
	.get('/', 'Hello from Elysia')
	.mount('/hono', hono.fetch)
	.listen(3000)
```

The mounting approach allows developers to:

- Gradually transition existing applications to Elysia
- Combine multiple frameworks in a single application instance
- Leverage existing framework-specific routes and middleware

Any framework built on Web Standards (with a `.fetch` handler) can be mounted into an Elysia application. The mounted framework handles all requests under the specified prefix path.

---

## OpenAPI

Elysia is built around OpenAPI and supports OpenAPI documentation out of the box. The framework provides built-in capabilities for generating API documentation automatically.

### Getting Started with OpenAPI

To enable OpenAPI documentation, use the dedicated plugin:

```typescript
import { Elysia, t } from 'elysia'
import { openapi } from '@elysiajs/openapi'

new Elysia()
	.use(openapi())
	.post(
		'/',
		({ body }) => body,
		{
			body: t.Object({
				age: t.Number()
			})
		}
	)
	.listen(3000)
```

Once configured, access your API documentation at the `/openapi` endpoint.

### Adding Details

Enhance documentation by including a `detail` field that adheres to the OpenAPI 3.0 specification with auto-completion support:

```typescript
import { Elysia, t } from 'elysia'
import { openapi } from '@elysiajs/openapi'

new Elysia()
	.use(openapi())
	.post(
		'/',
		({ body }) => body,
		{
			body: t.Object({
				age: t.Number()
			}),
			detail: {
				summary: 'Create a user',
				description: 'Create a user with age',
				tags: ['User'],
			}
		}
	)
	.listen(3000)
```

### Reference Models

Define reusable schemas for cleaner documentation:

```typescript
import { Elysia, t } from 'elysia'
import { openapi } from '@elysiajs/openapi'

new Elysia()
	.use(openapi())
	.model({
		age: t.Object({
			age: t.Number()
		})
	})
	.post(
		'/',
		({ body }) => body,
		{
			body: 'age',
			detail: {
				summary: 'Create a user',
				description: 'Create a user with age',
				tags: ['User'],
			}
		}
	)
	.listen(3000)
```

Reference models appear in the **Components** section of generated documentation.

### Type Generation

OpenAPI Type Gen can document your API without manual annotation by inferring types directly from TypeScript. This feature enables automatic schema inference from database queries and return types:

```typescript
import { Elysia } from 'elysia'
import { openapi, fromTypes } from '@elysiajs/openapi'

new Elysia()
	.use(openapi({
		references: fromTypes()
	}))
	.get('/', { hello: 'world' })
	.listen(3000)
```

**Note:** Type generation requires filesystem access and is unavailable in browser-based environments.

---

## End-to-End Type Safety

Elysia provides end-to-end type safety between backend and frontend without code generation, similar to tRPC, using Eden.

### Code Example

```typescript
import { Elysia } from 'elysia'
import { treaty } from '@elysiajs/eden'

// Backend
export const app = new Elysia()
	.get('/', 'Hello Elysia!')
	.listen(3000)

// Frontend
const client = treaty<typeof app>('localhost:3000')

const { data, error } = await client.get()

console.log(data) // Hello World
```

### How It Works

The type system bridges client and server by:

- Inferring types directly from Elysia instance definitions
- Providing type hints that ensure client requests match server contracts
- Eliminating the need for separate code generation steps

Eden is the client library that enables this type-safe communication. It uses TypeScript's type inference to ensure that API calls on the frontend match the exact shape of routes defined on the backend, including request bodies, query parameters, headers, and response types.

For detailed information on implementation, see the Eden Treaty documentation.

---

## Unit Test

Elysia provides a `Elysia.fetch` function to easily test your application. `Elysia.fetch` takes a Web Standard Request and returns a Response, similar to the browser's fetch API.

### Basic Usage

```typescript
import { Elysia } from 'elysia'

const app = new Elysia()
	.get('/', 'Hello World')

app.fetch(new Request('http://localhost/'))
	.then((res) => res.text())
	.then(console.log)
```

This runs a request like an actual request (not simulated).

### Bun Test

```typescript
import { describe, it, expect } from 'bun:test'

import { Elysia } from 'elysia'

describe('Elysia', () => {
	it('should return Hello World', async () => {
		const app = new Elysia().get('/', 'Hello World')

		const text = await app.fetch(new Request('http://localhost/'))
			.then(res => res.text())

		expect(text).toBe('Hello World')
	})
})
```

### Vitest

```typescript
import { describe, it, expect } from 'vitest'

import { Elysia } from 'elysia'

describe('Elysia', () => {
	it('should return Hello World', async () => {
		const app = new Elysia().get('/', 'Hello World')

		const text = await app.fetch(new Request('http://localhost/'))
			.then(res => res.text())

		expect(text).toBe('Hello World')
	})
})
```

### Jest

```typescript
import { describe, it, test } from '@jest/globals'

import { Elysia } from 'elysia'

describe('Elysia', () => {
	test('should return Hello World', async () => {
		const app = new Elysia().get('/', 'Hello World')

		const text = await app.fetch(new Request('http://localhost/'))
			.then(res => res.text())

		expect(text).toBe('Hello World')
	})
})
```

Testing with `Elysia.fetch` does not require running a server, making tests fast and portable. The same test patterns work across Bun Test, Vitest, and Jest -- pick whichever test runner fits your project.
