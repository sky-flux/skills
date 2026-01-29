import { Elysia, t } from 'elysia'
import { cors } from '@elysiajs/cors'
import { openapi } from '@elysiajs/openapi'

const app = new Elysia({ name: 'production-server' })
	// Plugins
	.use(cors())
	.use(openapi())
	// Request logging
	.onRequest(({ request }) => {
		console.log(`${request.method} ${request.url}`)
	})
	// Global error handler
	.onError(({ code, error, set }) => {
		if (code === 'VALIDATION') {
			set.status = 400
			return { error: 'Validation failed', details: error.message }
		}

		console.error(error)
		set.status = 500
		return { error: 'Internal server error' }
	})
	// Health check
	.get('/health', () => ({
		status: 'ok',
		uptime: process.uptime(),
		timestamp: new Date().toISOString()
	}))
	// Example API routes
	.group('/api', app =>
		app
			.get('/users', () => [
				{ id: 1, name: 'Alice' },
				{ id: 2, name: 'Bob' }
			])
			.get('/users/:id', ({ params: { id } }) => ({
				id,
				name: 'Alice'
			}), {
				params: t.Object({
					id: t.Number()
				})
			})
	)
	.listen(3000)

// Graceful shutdown
process.on('SIGINT', () => {
	console.log('Shutting down gracefully...')
	app.stop()
	process.exit(0)
})

console.log(`Server running at http://localhost:3000`)
console.log(`OpenAPI docs at http://localhost:3000/swagger`)

export type App = typeof app
