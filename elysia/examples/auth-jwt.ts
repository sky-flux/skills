import { Elysia, t } from 'elysia'
import { jwt } from '@elysiajs/jwt'

const app = new Elysia()
	.use(
		jwt({
			name: 'jwt',
			secret: process.env.JWT_SECRET!
		})
	)
	// Login - generate token
	.post(
		'/login',
		async ({ body, jwt }) => {
			// In production, verify against database
			if (body.username === 'admin' && body.password === 'password') {
				const token = await jwt.sign({
					sub: '1',
					username: body.username
				})

				return { token }
			}

			return { error: 'Invalid credentials' }
		},
		{
			body: t.Object({
				username: t.String(),
				password: t.String()
			})
		}
	)
	// Auth macro for protected routes
	.macro({
		isAuth: (enabled: boolean) =>
			enabled
				? {
						async resolve({ jwt, headers, status }) {
							const auth = headers.authorization?.replace('Bearer ', '')
							if (!auth) return status(401, 'Missing token')

							const payload = await jwt.verify(auth)
							if (!payload) return status(401, 'Invalid token')

							return { user: payload }
						}
					}
				: {}
	})
	// Protected route
	.get('/profile', ({ user }) => ({
		id: user.sub,
		username: user.username
	}), { isAuth: true })
	.listen(3000)

export type App = typeof app
