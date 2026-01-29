# Patterns

> **Sources (6 pages consolidated):**
> - https://elysiajs.com/tutorial/patterns/cookie
> - https://elysiajs.com/tutorial/patterns/error-handling
> - https://elysiajs.com/tutorial/patterns/extends-context
> - https://elysiajs.com/tutorial/patterns/macro
> - https://elysiajs.com/tutorial/patterns/validation-error
> - https://elysiajs.com/tutorial/patterns/standalone-schema

---

## Cookie

Cookie management in Elysia is handled through the context's cookie object, which provides a reactive interface for reading and modifying cookies.

### Basic Usage

Access cookies via destructuring from the handler context:

```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/', ({ cookie: { visit } }) => {
    const total = +visit.value ?? 0
    visit.value++

    return `You have visited ${visit.value} times`
  })
  .listen(3000)
```

The cookie object is reactive -- modifications automatically reflect in the response.

### Value Handling with Schema

Elysia coerces cookie values to their specified types when type annotations are provided:

```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/', ({ cookie: { visit } }) => {
    visit.value ??= 0
    visit.value.total++

    return `You have visited ${visit.value.total} times`
  }, {
    cookie: t.Object({
      visit: t.Optional(
        t.Object({
          total: t.Number()
        })
      )
    })
  })
  .listen(3000)
```

Use the cookie schema for validation and parsing.

### Attributes

Set individual cookie attributes by property assignment or use `.set()` for bulk operations:

```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/', ({ cookie: { visit } }) => {
    visit.value ??= 0
    visit.value++

    visit.httpOnly = true
    visit.path = '/'

    visit.set({
      sameSite: 'lax',
      secure: true,
      maxAge: 60 * 60 * 24 * 7
    })

    return `You have visited ${visit.value} times`
  })
  .listen(3000)
```

### Removal

Delete cookies using the `.remove()` method:

```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/', ({ cookie: { visit } }) => {
    visit.remove()

    return `Cookie removed`
  })
  .listen(3000)
```

### Cookie Signatures

Prevent tampering by signing cookies through the Elysia constructor or per-cookie via `t.Cookie`:

```typescript
import { Elysia } from 'elysia'

new Elysia({
  cookie: {
    secret: 'Fischl von Luftschloss Narfidort',
  }
})
  .get('/', ({ cookie: { visit } }) => {
    visit.value ??= 0
    visit.value++

    return `You have visited ${visit.value} times`
  }, {
    cookie: t.Cookie({
      visit: t.Optional(t.Number())
    }, {
      secrets: 'Fischl von Luftschloss Narfidort',
      sign: ['visit']
    })
  })
  .listen(3000)
```

When multiple secrets exist, the first signs cookies while others verify them during rotation.

### Practice: Visit Counter with HTTP-Only

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
  .get('/', ({ cookie: { visit } }) => {
    visit.value ??= 0
    visit.value++

    visit.httpOnly = true

    return `You have visited ${visit.value} times`
  }, {
    cookie: t.Object({
      visit: t.Optional(t.Number())
    })
  })
  .listen(3000)
```

This approach increments a counter on each request and sets HTTP-only status to prevent client-side script access.

---

## Error Handling

The `onError` handler is triggered when an error is thrown. It receives context similar to a standard handler, plus two additional properties:

- **error** - the thrown error
- **code** - the error code

### Basic Error Handling

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.onError(({ code, status }) => {
		if(code === "NOT_FOUND")
			return 'uhe~ are you lost?'

		return status(418, "My bad! But I'm cute so you'll forgive me, right?")
	})
	.get('/', () => 'ok')
	.listen(3000)
```

You can override the default error status by returning a `status()` call.

### Custom Error Classes

Define custom errors with error codes for better type safety:

```typescript
import { Elysia } from 'elysia'

class NicheError extends Error {
	constructor(message: string) {
		super(message)
	}
}

new Elysia()
	.error({
		'NICHE': NicheError
	})
	.onError(({ error, code, status }) => {
		if(code === 'NICHE') {
			// Typed as NicheError
			console.log(error)

			return status(418, "We have no idea how you got here")
		}
	})
	.get('/', () => {
		throw new NicheError('Custom error message')
	})
	.listen(3000)
```

Registering custom errors enables Elysia to narrow down type inference.

### Custom Status Codes

Add a `status` property to define the HTTP response code:

```typescript
class NicheError extends Error {
	status = 418

	constructor(message: string) {
		super(message)
	}
}
```

### Custom Error Responses

Implement a `toResponse()` method for custom response formatting:

```typescript
class NicheError extends Error {
	status = 418

	constructor(message: string) {
		super(message)
	}

	toResponse() {
		return { message: this.message }
	}
}
```

Elysia will use this response when the error is thrown.

---

## Extends Context

Elysia provides a context system with utilities to enhance your application. The framework offers four primary methods to extend context:

1. **Decorate** - Singleton and immutable properties
2. **State** - Mutable references shared across requests
3. **Resolve** - Per-request values (after validation)
4. **Derive** - Per-request values (before validation)

### Decorate

Singleton and immutable properties shared across all requests:

```typescript
import { Elysia } from 'elysia'

class Logger {
    log(value: string) {
        console.log(value)
    }
}

new Elysia()
    .decorate('logger', new Logger())
    .get('/', ({ logger }) => {
        logger.log('hi')
        return 'hi'
    })
```

Decorated values appear in the context as read-only properties.

### State

Mutable references shared across all requests:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .state('count', 0)
    .get('/', ({ store }) => {
        store.count++
        return store.count
    })
```

State is accessible via `context.store` and persists across every request.

### Resolve and Derive

Unlike decorators (singletons), resolve and derive abstract context values per request:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .derive(({ headers: { authorization } }) => ({
        authorization
    }))
    .get('/', ({ authorization }) => authorization)
```

Returned values become available in context.

**Key Differences:**
- **Derive**: Based on the transform lifecycle (data not yet validated)
- **Resolve**: Based on the before-handle lifecycle (validates data first)

### Scope Comparison

| Method | Scope | Behavior |
|--------|-------|----------|
| State / Decorate | All requests and instances | Shared globally |
| Resolve / Derive | Per request | Encapsulated per lifecycle |

### Plugin Access with Scoped Derive

For plugin access to resolved or derived values, declare scoped handling:

```typescript
import { Elysia } from 'elysia'

const plugin = new Elysia()
    .derive(
        { as: 'scoped' },
        ({ headers: { authorization } }) => ({
            authorization
        })
    )

new Elysia()
    .use(plugin)
    .get('/', ({ authorization }) => authorization)
    .listen(3000)
```

### Practice: Context Extension

Extract `query.age`, validate it exists (return 401 if missing), then use it in a handler:

```typescript
import { Elysia, t } from 'elysia'

class Logger {
    log(info: string) {
        console.log(info)
    }
}

new Elysia()
    .decorate('logger', new Logger())
    .onRequest(({ request, logger }) => {
        logger.log(`Request to ${request.url}`)
    })
    .guard({
        query: t.Optional(
            t.Object({
                age: t.Number({ min: 15 })
            })
        )
    })
    .resolve(({ query: { age }, status }) => {
        if(!age) return status(401)
        return { age }
    })
    .get('/profile', ({ age }) => age)
    .listen(3000)
```

---

## Macro

A macro is a reusable route options mechanism. Rather than repeating identical route configurations across multiple endpoints, you can define a macro once and apply it wherever needed. This approach maintains type safety while reducing code duplication.

### Problem: Repeated Route Options

Consider an authentication check implemented on a single route:

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.post('/user', ({ body }) => body, {
		cookie: t.Object({
			session: t.String()
		}),
		beforeHandle({ cookie: { session } }) {
			if(!session.value) throw 'Unauthorized'
		}
	})
	.listen(3000)
```

When multiple routes require identical authentication logic, you must duplicate these options on each route.

### Solution: Using Macros

Define a macro to encapsulate reusable route configuration:

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.macro('auth', {
		cookie: t.Object({
			session: t.String()
		}),
		beforeHandle({ cookie: { session }, status }) {
			if(!session.value) return status(401)
		}
	})
	.post('/user', ({ body }) => body, {
		auth: true
	})
	.listen(3000)
```

The macro automatically inlines both the cookie schema and beforeHandle lifecycle hook into the route configuration.

### Practice: Fibonacci Validation Macro

Create a macro that validates whether a request body contains a Fibonacci number:

```typescript
import { Elysia, t } from 'elysia'

function isPerfectSquare(x: number) {
	const s = Math.floor(Math.sqrt(x))
	return s * s === x
}

function isFibonacci(n: number) {
	if (n < 0) return false
	return isPerfectSquare(5 * n * n + 4) || isPerfectSquare(5 * n * n - 4)
}

new Elysia()
	.macro('isFibonacci', {
		body: t.Number(),
		beforeHandle({ body, status }) {
			if(!isFibonacci(body)) return status(418)
		}
	})
	.post('/', ({ body }) => body, {
		isFibonacci: true
	})
	.listen(3000)
```

This macro enforces a numeric body schema and validates that the number belongs to the Fibonacci sequence, returning status 418 if validation fails.

---

## Validation Error

When implementing validation with `Elysia.t`, developers can specify custom error messages that correspond to fields failing validation checks.

### Basic Implementation

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.post(
		'/',
		({ body }) => body,
		{
			body: t.Object({
				age: t.Number({
					error: 'Age must be a number'
				})
			}, {
				error: 'Body must be an object'
			})
		}
	)
	.listen(3000)
```

Elysia replaces default error messaging with custom alternatives provided through the configuration.

### Default Validation Details

By default, Elysia includes detailed validation information explaining what failed:

```json
{
	"type": "validation",
	"on": "params",
	"value": { "id": "string" },
	"property": "/id",
	"message": "id must be a number",
	"summary": "Property 'id' should be one of: 'numeric', 'number'",
	"found": { "id": "string" },
	"expected": { "id": 0 },
	"errors": [
		{
			"type": 62,
			"schema": {
				"anyOf": [
					{ "format": "numeric", "default": 0, "type": "string" },
					{ "type": "number" }
				]
			},
			"path": "/id",
			"value": "string",
			"message": "Expected union value"
		}
	]
}
```

### Preserving Validation Details

Custom error messages completely override validation details. To preserve them, wrap the custom message using `validationDetail()`:

```typescript
import { Elysia, t, validationDetail } from 'elysia'

new Elysia()
	.post(
		'/',
		({ body }) => body,
		{
			body: t.Object({
				age: t.Number({
					error: validationDetail('Age must be a number')
				})
			}, {
				error: validationDetail('Body must be an object')
			})
		}
	)
	.listen(3000)
```

Using `validationDetail()` allows you to provide a custom message while still retaining the detailed validation information in the response.

---

## Standalone Schema

When defining schemas with Guard, route-level schemas will override the guard schema by default. To make schemas coexist, use the standalone schema feature.

### Default Behavior (Override)

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.guard({
		body: t.Object({
			age: t.Number()
		})
	})
	.post(
		'/user',
		({ body }) => body,
		{
			// This will override the guard schema
			body: t.Object({
				name: t.String()
			})
		}
	)
	.listen(3000)
```

### Standalone Schema (Coexistence)

To enable schema coexistence, add `schema: 'standalone'` to the guard configuration:

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.guard({
		schema: 'standalone',
		body: t.Object({
			age: t.Number()
		})
	})
	.post(
		'/user',
		// body will have both age and name property
		({ body }) => body,
		{
			body: t.Object({
				name: t.String()
			})
		}
	)
	.listen(3000)
```

### Schema Library Interoperability

Standalone schemas support mixing validation libraries. You can define standalone schemas using one library (e.g., Zod) and route schemas using another (e.g., Elysia.t), and they work together seamlessly.

### Practice: Mixed Libraries with Standalone Schema

Modify the POST `/user` endpoint to accept both `name` (string) and `age` (number) using standalone schema with Zod:

```typescript
import { Elysia, t } from 'elysia'
import { z } from 'zod'

new Elysia()
	.guard({
		schema: 'standalone',
		body: z.object({
			age: z.number()
		})
	})
	.post(
		'/user',
		({ body }) => body,
		{
			body: t.Object({
				name: t.String()
			})
		}
	)
	.listen(3000)
```
