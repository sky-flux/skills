# Getting Started

> **Sources (8 pages consolidated):**
> - https://elysiajs.com/tutorial/getting-started/your-first-route
> - https://elysiajs.com/tutorial/getting-started/handler-and-context
> - https://elysiajs.com/tutorial/getting-started/validation
> - https://elysiajs.com/tutorial/getting-started/plugin
> - https://elysiajs.com/tutorial/getting-started/life-cycle
> - https://elysiajs.com/tutorial/getting-started/encapsulation
> - https://elysiajs.com/tutorial/getting-started/guard
> - https://elysiajs.com/tutorial/getting-started/status-and-headers

---

## Your First Route

When accessing a website, two key pieces of information determine what resource to display:

1. **Path** (e.g., `/`, `/about`, `/contact`)
2. **HTTP Method** (e.g., `GET`, `POST`, `DELETE`)

This combination is called a **route**. In Elysia, define routes by calling a method named after the HTTP verb, with the path as the first argument and handler as the second.

### Basic Example

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/', 'Hello World!')
	.listen(3000)
```

### Routing Types

Elysia supports three path categories:

1. **Static paths** - hardcoded strings
2. **Dynamic paths** - segments capturing variable values
3. **Wildcards** - capturing remaining path segments

### Static Path

Define fixed resource locations:

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/hello', 'hello')
	.get('/hi', 'hi')
	.listen(3000)
```

### Dynamic Path

Use a colon (`:`) prefix to capture segment values:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/id/:id', ({ params: { id } }) => id)
    .listen(3000)
```

This matches `/id/1`, `/id/123`, `/id/anything`, etc.

#### Optional Parameters

Add a question mark (`?`) to make parameters optional:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/id/:id?', ({ params: { id } }) => `id ${id}`)
    .listen(3000)
```

### Wildcards

Use an asterisk (`*`) to capture the entire remaining path:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/id/*', ({ params }) => params['*'])
    .listen(3000)
```

### Practice: Multiple Route Types

Create three routes demonstrating different path types:

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/elysia', 'Hello Elysia!')
	.get('/friends/:name?', ({ params: { name } }) => `Hello ${name}!`)
	.get('/flame-chasers/*', ({ params }) => params['*'])
	.listen(3000)
```

---

## Handler and Context

### Handler

A **handler** is a route function that sends data back to the client. It can be either a function or a literal value.

#### Function Handler

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/', () => 'hello world')
    .listen(3000)
```

#### Literal Value Handler

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/', 'hello world')
    .listen(3000)
```

Using inline values is particularly useful for serving static resources like files.

### Context

Context provides information about each incoming request and is passed as the sole argument to a handler function.

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/', (context) => context.path)
```

### Context Properties

Context stores request information including:

- **body** - data sent from client to server (form data, JSON payload)
- **query** - query string parsed as an object (extracted from URL after `?`)
- **params** - path parameters parsed as an object
- **headers** - HTTP headers with additional request information (e.g., "Content-Type")

### Practice: Extract Context Parameters

Create a POST endpoint that extracts and returns body, query, and headers:

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.post('/', ({ body, query, headers }) => {
		return {
			query,
			body,
			headers
		}
	})
	.listen(3000)
```

This demonstrates destructuring context properties directly from the handler parameter.

---

## Validation

Elysia provides built-in data validation capabilities. Using `Elysia.t`, developers can define schemas to ensure incoming data matches expected structures.

### Basic Schema Definition

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.post(
		'/user',
		({ body: { name } }) => `Hello ${name}!`,
		{
			body: t.Object({
				name: t.String(),
				age: t.Number()
			})
		}
	)
	.listen(3000)
```

When schema validation fails, the framework returns a **422 Unprocessable Entity** error response.

### Alternative Schema Libraries

Elysia supports Standard Schema, enabling use of third-party libraries like Zod, Yup, or Valibot:

```typescript
import { Elysia } from 'elysia'
import { z } from 'zod'

new Elysia()
	.post(
		'/user',
		({ body: { name } }) => `Hello ${name}!`,
		{
			body: z.object({
				name: z.string(),
				age: z.number()
			})
		}
	)
	.listen(3000)
```

### Validation Types

You can validate these properties:

- `body`
- `query`
- `params`
- `headers`
- `cookie`
- `response`

Elysia automatically infers TypeScript types from defined schemas.

### Response Validation

When defining response schemas, Elysia validates responses before sending and provides type checking:

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.get(
		'/user',
		() => `Hello Elysia!`,
		{
			response: {
				200: t.Literal('Hello Elysia!'),
				418: t.Object({
					message: t.Literal("I'm a teapot")
				})
			}
		}
	)
	.listen(3000)
```

### Practice: Validate a POST Endpoint

Define a POST `/user` endpoint accepting an object with a `name` string property:

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.post(
		'/user',
		({ body: { name } }) => `Hello ${name}!`,
		{
			body: t.Object({
				name: t.String()
			})
		}
	)
	.listen(3000)
```

---

## Plugin

Every Elysia instance supports plug-and-play integration with other instances through the `use` method.

### Basic Plugin Usage

```typescript
import { Elysia } from 'elysia'

const user = new Elysia()
	.get('/profile', 'User Profile')
	.get('/settings', 'User Settings')

new Elysia()
	.use(user)
	.get('/', 'Home')
	.listen(3000)
```

Once applied, all routes from the `user` instance become available in the main application instance.

### Plugin Configuration

You can create plugins that accept arguments and return an Elysia instance for dynamic functionality:

```typescript
import { Elysia } from 'elysia'

const user = ({ log = false }) => new Elysia()
	.onBeforeHandle(({ request }) => {
		if (log) console.log(request)
	})
	.get('/profile', 'User Profile')
	.get('/settings', 'User Settings')

new Elysia()
	.use(user({ log: true }))
	.get('/', 'Home')
	.listen(3000)
```

Plugins can accept configuration options, enabling dynamic behavior based on the options passed.

---

## Life Cycle

Lifecycle hooks are functions that execute at specific points during the request-response cycle. They enable custom logic at these events:

- **request** - when a request is received
- **beforeHandle** - before executing a handler
- **afterResponse** - after a response is sent
- **error** - when an error occurs

Common use cases include logging, authentication, and request validation.

### Registering Lifecycle Hooks

Pass hooks as the third argument to route methods:

```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/1', () => 'Hello Elysia!')
  .get('/auth', () => {
    console.log('This is executed after "beforeHandle"')
    return 'Oh you are lucky!'
  }, {
    beforeHandle({ request, status }) {
      console.log('This is executed before handler')
      if(Math.random() <= 0.5)
        return status(418)
    }
  })
  .get('/2', () => 'Hello Elysia!')
```

When `beforeHandle` returns a value, it skips the handler and returns that value instead. This is useful for authentication checks.

### Local Hook

Executes on a specific route only. Defined inline within route configuration:

```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/1', () => 'Hello Elysia!')
  .get('/auth', () => {
    console.log('Run after "beforeHandle"')
    return 'Oh you are lucky!'
  }, {
    beforeHandle({ request, status }) {
      console.log('Run before handler')
      if(Math.random() <= 0.5)
        return status(418)
    }
  })
  .get('/2', () => 'Hello Elysia!')
```

### Interceptor Hook

Interceptor hooks register into every handler that comes after the hook is called, for the current instance only. Use the `.on` prefix followed by the lifecycle event:

```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/1', () => 'Hello Elysia!')
  .onBeforeHandle(({ request, status }) => {
    console.log('This is executed before handler')
    if(Math.random() <= 0.5)
      return status(418)
  })
  .get('/auth', () => {
    console.log('This is executed after "beforeHandle"')
    return 'Oh you are lucky!'
  })
  .get('/2', () => 'Hello Elysia!')
```

Interceptor hooks apply to all subsequent routes registered after the hook declaration.

### Practice: Authentication Check

```typescript
import { Elysia } from 'elysia'

new Elysia()
  .onBeforeHandle(({ query: { name }, status }) => {
    if(!name) return status(401)
  })
  .get('/auth', ({ query: { name = 'anon' } }) => {
    return `Hello ${name}!`
  })
  .get('/profile', ({ query: { name = 'anon' } }) => {
    return `Hello ${name}!`
  })
  .listen(3000)
```

This example uses an interceptor hook to require a `name` query parameter, eliminating code duplication across authenticated endpoints.

---

## Encapsulation

Elysia hooks are encapsulated to their own instance only. When you create a new Elysia instance, it will not automatically share hooks with other instances unless explicitly configured.

### Basic Example

```typescript
import { Elysia } from 'elysia'

const profile = new Elysia()
	.onBeforeHandle(
		({ query: { name }, status }) => {
			if(!name)
				return status(401)
		}
	)
	.get('/profile', () => 'Hi!')

new Elysia()
	.use(profile)
	.patch('/rename', () => 'Ok! XD')
	.listen(3000)
```

The `/rename` endpoint will not have the name validation check applied because lifecycle hooks are isolated by default.

### Scope Levels

To share lifecycle behavior across instances, you must specify a scope. Three options exist:

1. **local** (default) - applies only to current instance and its descendants
2. **scoped** - applies to parent, current instance, and descendants
3. **global** - applies to all instances using the plugin

### Scoped Example

```typescript
import { Elysia } from 'elysia'

const profile = new Elysia()
	.onBeforeHandle(
		{ as: 'scoped' },
		({ cookie }) => {
			throwIfNotSignIn(cookie)
		}
	)
	.get('/profile', () => 'Hi there!')

const app = new Elysia()
	.use(profile)
	.patch('/rename', ({ body }) => updateProfile(body))
```

Using `'scoped'` extends the lifecycle to the parent instance, so both endpoints receive the authentication check.

### Guard Encapsulation

Similar to lifecycle, schemas are also encapsulated to their own instance. Guards can specify scope identically to lifecycle hooks:

```typescript
import { Elysia } from 'elysia'

const user = new Elysia()
	.guard({
		as: 'scoped',
		query: t.Object({
			age: t.Number(),
			name: t.Optional(t.String())
		}),
		beforeHandle({ query: { age }, status }) {
			if(age < 18) return status(403)
		}
	})
	.get('/profile', () => 'Hi!')
	.get('/settings', () => 'Settings')
```

Every hook affects all routes declared after its initialization.

---

## Guard

The `guard` feature allows you to apply multiple hooks to your application without repeating them. Instead of chaining individual hook declarations, you can bulk add hooks using the guard method.

### Without Guard (Repetitive)

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
  .onBeforeHandle(({ query: { name }, status }) => {
    if(!name) return status(401)
  })
  .onBeforeHandle(({ query: { name } }) => {
    console.log(name)
  })
  .onAfterResponse(({ responseValue }) => {
    console.log(responseValue)
  })
  .get('/auth', ({ query: { name = 'anon' } }) => `Hello ${name}!`)
  .get('/profile', ({ query: { name = 'anon' } }) => `Hello ${name}!`)
  .listen(3000)
```

### With Guard (Consolidated)

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
  .guard({
    beforeHandle: [
      ({ query: { name }, status }) => {
        if(!name) return status(401)
      },
      ({ query: { name } }) => {
        console.log(name)
      }
    ],
    afterResponse({ responseValue }) {
      console.log(responseValue)
    }
  })
  .get('/auth', ({ query: { name = 'anon' } }) => `Hello ${name}!`)
  .get('/profile', ({ query: { name = 'anon' } }) => `Hello ${name}!`)
  .listen(3000)
```

### Applying Schemas with Guard

Guard can apply validation schemas to multiple routes simultaneously:

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
  .guard({
    beforeHandle: [
      ({ query: { name }, status }) => {
        if(!name) return status(401)
      },
      ({ query: { name } }) => {
        console.log(name)
      }
    ],
    afterResponse({ responseValue }) {
      console.log(responseValue)
    },
    query: t.Object({
      name: t.String()
    })
  })
  .get('/auth', ({ query: { name = 'anon' } }) => `Hello ${name}!`)
  .get('/profile', ({ query: { name = 'anon' } }) => `Hello ${name}!`)
  .listen(3000)
```

Guard applies hooks and schema to every route after `.guard` is called in the same instance.

---

## Status and Headers

### Status

A status code communicates how the server processes a request. Elysia defaults to returning **200 OK** for successful requests but provides numerous other codes:

- 400 Bad Request
- 422 Unprocessable Entity
- 500 Internal Server Error

Return status codes using the `status` function:

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/', ({ status }) => status(418, "I'm a teapot"))
	.listen(3000)
```

Status can be specified as either a number or string name, and both approaches work equivalently:

```typescript
status(418, "I'm a teapot")
status("I'm a teapot", "I'm a teapot")
```

String status names enable TypeScript autocompletion for valid HTTP statuses.

### Redirect

Redirect requests to alternative URLs using the `redirect` function:

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/', ({ redirect }) => redirect('https://elysiajs.com'))
	.listen(3000)
```

### Headers

Unlike status codes and redirects (returned directly), headers often require multiple assignments throughout applications. Elysia provides `set.headers` for response header management:

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/', ({ set }) => {
		set.headers['x-powered-by'] = 'Elysia'

		return 'Hello World'
	})
	.listen(3000)
```

The framework distinguishes request from response headers using the `set.headers` prefix.

### Practice: Status, Redirect, and Headers

Create endpoints demonstrating status codes, redirects, and custom headers:

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/', ({ status, set }) => {
		set.headers['x-powered-by'] = 'Elysia'

		return status(418, 'Hello Elysia!')
	})
	.get('/docs', ({ redirect }) => redirect('https://elysiajs.com'))
	.listen(3000)
```
