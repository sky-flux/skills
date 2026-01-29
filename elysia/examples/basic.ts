import { Elysia, t } from 'elysia'

// Basic Elysia server
new Elysia()
	// Simple GET handler
	.get('/', 'Hello Elysia')
	// POST with body validation
	.post(
		'/greet',
		({ body: { name } }) => `Hello ${name}!`,
		{
			body: t.Object({
				name: t.String()
			})
		}
	)
	.listen(3000)

console.log('Server running at http://localhost:3000')
