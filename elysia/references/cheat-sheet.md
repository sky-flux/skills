# Elysia Cheat Sheet

Quick reference for all core Elysia APIs with concise examples.

Source: https://elysiajs.com/integrations/cheat-sheet

## Hello World

```ts
import { Elysia } from 'elysia'

new Elysia()
	.get('/', () => 'Hello World')
	.listen(3000)
```

## Custom HTTP Method

Define routes using standard or custom HTTP methods/verbs.

```ts
import { Elysia } from 'elysia'

new Elysia()
	.get('/hi', () => 'Hi')
	.post('/hi', () => 'From Post')
	.put('/hi', () => 'From Put')
	.route('M-SEARCH', '/hi', () => 'Custom Method')
	.listen(3000)
```

## Path Parameter

Using dynamic path parameters and wildcards.

```ts
import { Elysia } from 'elysia'

new Elysia()
	.get('/id/:id', ({ params: { id } }) => id)
	.get('/rest/*', () => 'Rest')
	.listen(3000)
```

## Return JSON

Elysia converts response objects to JSON automatically.

```ts
import { Elysia } from 'elysia'

new Elysia()
	.get('/json', () => {
		return {
			hello: 'Elysia'
		}
	})
	.listen(3000)
```

## Return a File

A file can be returned as formdata response. The response must be a 1-level deep object.

```ts
import { Elysia, file } from 'elysia'

new Elysia()
	.get('/json', () => {
		return {
			hello: 'Elysia',
			image: file('public/cat.jpg')
		}
	})
	.listen(3000)
```

## Header and Status

Set a custom header and a status code.

```ts
import { Elysia } from 'elysia'

new Elysia()
	.get('/', ({ set, status }) => {
		set.headers['x-powered-by'] = 'Elysia'

		return status(418, "I'm a teapot")
	})
	.listen(3000)
```

## Group

Define a prefix once for sub routes.

```ts
import { Elysia } from 'elysia'

new Elysia()
	.get('/', () => 'Hi')
	.group('/auth', (app) => {
		return app
			.get('/', () => 'Hi')
			.post('/sign-in', ({ body }) => body)
			.put('/sign-up', ({ body }) => body)
	})
	.listen(3000)
```

## Schema (Validation)

Enforce a data type on a route using `t` (TypeBox).

```ts
import { Elysia, t } from 'elysia'

new Elysia()
	.post('/mirror', ({ body: { username } }) => username, {
		body: t.Object({
			username: t.String(),
			password: t.String()
		})
	})
	.listen(3000)
```

## File Upload

Handle single and multiple file uploads with type validation.

```ts
import { Elysia, t } from 'elysia'

new Elysia()
	.post('/body', ({ body }) => body, {
		body: t.Object({
			file: t.File({ format: 'image/*' }),
			multipleFiles: t.Files()
		})
	})
	.listen(3000)
```

## Lifecycle Hook

Intercept Elysia events in order. Hooks can be global or route-scoped.

```ts
import { Elysia, t } from 'elysia'

new Elysia()
	.onRequest(() => {
		console.log('On request')
	})
	.on('beforeHandle', () => {
		console.log('Before handle')
	})
	.post('/mirror', ({ body }) => body, {
		body: t.Object({
			username: t.String(),
			password: t.String()
		}),
		afterHandle: () => {
			console.log('After handle')
		}
	})
	.listen(3000)
```

## Guard

Enforce a data type across sub routes within a scope.

```ts
import { Elysia, t } from 'elysia'

new Elysia()
	.guard({
		response: t.String()
	}, (app) =>
		app
			.get('/', () => 'Hi')
			// This would cause a type error at compile time
			.get('/invalid', () => 1)
	)
	.listen(3000)
```

## Custom Context

Add custom variables to route context via `state` (store) and `decorate` (methods).

```ts
import { Elysia } from 'elysia'

new Elysia()
	.state('version', 1)
	.decorate('getDate', () => Date.now())
	.get('/version', ({
		getDate,
		store: { version }
	}) => `${version} ${getDate()}`)
	.listen(3000)
```

- `state(key, value)` -- adds to `store`, accessed via `store.key`
- `decorate(key, value)` -- adds directly to context, accessed via `key`

## Redirect

Redirect a response to another path.

```ts
import { Elysia } from 'elysia'

new Elysia()
	.get('/', () => 'hi')
	.get('/redirect', ({ redirect }) => {
		return redirect('/')
	})
	.listen(3000)
```

## Plugin

Create a separate Elysia instance and compose with `.use()`.

```ts
import { Elysia } from 'elysia'

const plugin = new Elysia()
	.state('plugin-version', 1)
	.get('/hi', () => 'hi')

new Elysia()
	.use(plugin)
	.get('/version', ({ store }) => store['plugin-version'])
	.listen(3000)
```

## WebSocket

Create a realtime connection using WebSocket.

```ts
import { Elysia } from 'elysia'

new Elysia()
	.ws('/ping', {
		message(ws, message) {
			ws.send('hello ' + message)
		}
	})
	.listen(3000)
```

## OpenAPI Documentation

Create interactive documentation using Scalar (or optionally Swagger).

```ts
import { Elysia } from 'elysia'
import { openapi } from '@elysiajs/openapi'

const app = new Elysia()
	.use(openapi())
	.listen(3000)

console.log(
	`View documentation at "${app.server!.url}openapi" in your browser`
)
```

## Unit Test

Write a unit test using Elysia's `.handle()` method with Bun's test runner.

```ts
// test/index.test.ts
import { describe, expect, it } from 'bun:test'
import { Elysia } from 'elysia'

describe('Elysia', () => {
	it('return a response', async () => {
		const app = new Elysia().get('/', () => 'hi')

		const response = await app
			.handle(new Request('http://localhost/'))
			.then((res) => res.text())

		expect(response).toBe('hi')
	})
})
```

## Custom Body Parser

Create custom logic for parsing request bodies based on content type.

```ts
import { Elysia } from 'elysia'

new Elysia()
	.onParse(({ request, contentType }) => {
		if (contentType === 'application/custom-type')
			return request.text()
	})
```

## GraphQL

Create a GraphQL server using GraphQL Yoga (or Apollo).

```ts
import { Elysia } from 'elysia'
import { yoga } from '@elysiajs/graphql-yoga'

const app = new Elysia()
	.use(
		yoga({
			typeDefs: /* GraphQL */ `
				type Query {
					hi: String
				}
			`,
			resolvers: {
				Query: {
					hi: () => 'Hello from Elysia'
				}
			}
		})
	)
	.listen(3000)
```

## Quick Reference Table

| API | Purpose | Example |
|-----|---------|---------|
| `.get()` / `.post()` / `.put()` / `.delete()` | HTTP route | `.get('/path', handler)` |
| `.route(method, path, handler)` | Custom HTTP verb | `.route('M-SEARCH', '/path', handler)` |
| `.group(prefix, callback)` | Route grouping | `.group('/api', app => app.get(...))` |
| `.guard(schema, callback)` | Schema enforcement scope | `.guard({ body: t.Object({}) }, app => ...)` |
| `.use(plugin)` | Plugin composition | `.use(cors())` |
| `.state(key, value)` | Add to `store` context | `.state('version', 1)` |
| `.decorate(key, value)` | Add to context directly | `.decorate('fn', () => ...)` |
| `.onRequest()` | Request lifecycle hook | `.onRequest(() => { ... })` |
| `.on('beforeHandle', fn)` | Named lifecycle hook | `.on('beforeHandle', () => { ... })` |
| `.onParse()` | Custom body parser | `.onParse(({ contentType }) => ...)` |
| `.ws(path, config)` | WebSocket route | `.ws('/ws', { message(ws, msg) {} })` |
| `.listen(port)` | Start server | `.listen(3000)` |
| `t.Object()` / `t.String()` etc. | Schema validation | `body: t.Object({ name: t.String() })` |
| `file(path)` | Return a file | `file('public/cat.jpg')` |
| `status(code, body)` | Return with status | `status(418, "I'm a teapot")` |
| `redirect(path)` | Redirect response | `redirect('/')` |
