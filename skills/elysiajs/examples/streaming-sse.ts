import { Elysia } from 'elysia'

new Elysia()
	// Basic streaming response
	.get('/stream', function* () {
		yield 'Hello '
		yield 'World'
	})
	// Server-Sent Events
	.get('/sse', async function* () {
		while (true) {
			yield { data: JSON.stringify({ time: Date.now() }) }
			await Bun.sleep(1000)
		}
	})
	// Stream with abort handling
	.get('/events', async function* ({ request }) {
		let running = true
		request.signal.addEventListener('abort', () => {
			running = false
		})

		let count = 0
		while (running) {
			yield { data: JSON.stringify({ count: count++ }) }
			await Bun.sleep(500)
		}
	})
	.listen(3000)
