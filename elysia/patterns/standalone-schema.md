# Standalone Schema Pattern

Standalone schemas allow guard schemas and route-specific schemas to coexist (merge) rather than having the route schema override the guard schema.

Source: https://elysiajs.com/tutorial/patterns/standalone-schema

## The Problem

By default, when you define a schema on both a guard and a route, the route-level schema replaces the guard schema entirely:

```ts
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
			// This REPLACES the guard body schema -- age is lost
			body: t.Object({
				name: t.String()
			})
		}
	)
	.listen(3000)
```

In this case, the route only validates `name`. The guard's `age` field is completely overridden.

## The Solution: `schema: 'standalone'`

Add `schema: 'standalone'` to your guard configuration. This merges the guard schema with the route schema so both apply:

```ts
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
		({ body }) => body,
		{
			body: t.Object({
				name: t.String()
			})
		}
	)
	.listen(3000)
```

With standalone mode, the request body now requires **both** `age` (from guard) and `name` (from route). The schemas merge rather than override.

## Cross-Route Reuse

Standalone schemas are useful for enforcing shared validation across multiple routes while still allowing each route to define its own additional constraints:

```ts
import { Elysia, t } from 'elysia'

// Shared auth fields applied to all routes in this guard
const app = new Elysia()
	.guard({
		schema: 'standalone',
		headers: t.Object({
			authorization: t.String()
		})
	})
	.post(
		'/user',
		({ body }) => body,
		{
			body: t.Object({
				name: t.String(),
				email: t.String()
			})
		}
	)
	.put(
		'/user',
		({ body }) => body,
		{
			body: t.Object({
				name: t.String()
			})
		}
	)
	.delete(
		'/user/:id',
		({ params }) => params.id,
		{
			params: t.Object({
				id: t.String()
			})
		}
	)
	.listen(3000)
```

All three routes require the `authorization` header (from the guard) while each defines its own body or params schema. The schemas coexist.

## Schema Composition with Multiple Libraries

Standalone schemas support composition across different validation libraries. You can define a guard with Zod while using Elysia's `t` (TypeBox) for route schemas, or vice versa:

```ts
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

Both schemas apply without conflicts -- Elysia handles the interop between TypeBox and Zod validators transparently.

## Nested Guards

Standalone schemas compose through nested guards as well. Each guard layer adds its schema on top of the previous:

```ts
import { Elysia, t } from 'elysia'

new Elysia()
	.guard({
		schema: 'standalone',
		headers: t.Object({
			'x-api-key': t.String()
		})
	})
	.group('/admin', (app) =>
		app
			.guard({
				schema: 'standalone',
				headers: t.Object({
					'x-admin-token': t.String()
				})
			})
			.get('/dashboard', () => 'admin dashboard')
	)
	.listen(3000)
```

The `/admin/dashboard` route requires **both** `x-api-key` (outer guard) and `x-admin-token` (inner guard) headers.

## When to Use Standalone Schemas

- **Shared authentication/authorization** -- enforce auth headers or tokens across a group of routes
- **Common request metadata** -- require fields like `x-request-id` or `x-tenant-id` on all requests
- **Layered validation** -- build up validation requirements through nested route groups
- **Multi-library projects** -- mix Zod, TypeBox, or other validators within the same route tree

## Comparison: Default vs Standalone

| Behavior | Default Guard | Standalone Guard |
|----------|---------------|------------------|
| Route schema + guard schema | Route **replaces** guard | Route **merges** with guard |
| Config | (none) | `schema: 'standalone'` |
| Use case | Override guard per route | Compose shared + route schemas |
| Cross-library | N/A | Supported (Zod + TypeBox etc.) |
