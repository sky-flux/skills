# Elysia Integration Guides

Consolidated from the official Elysia blog. Covers integrating Elysia with Prisma and Supabase.

---

## Prisma + Elysia

### Setup

Create a new Elysia project and install Prisma:

```bash
bun create elysia elysia-prisma
bun add -d prisma
bunx prisma init
```

This generates a `.env` file and creates a `prisma/schema.prisma` file.

### Database Schema

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int     @id @default(autoincrement())
  username  String  @unique
  password  String
}
```

### Environment Setup

Start PostgreSQL via Docker:

```bash
docker run -p 5432:5432 -e POSTGRES_PASSWORD=12345678 -d postgres
```

Configure `.env`:

```
DATABASE_URL="postgresql://postgres:12345678@localhost:5432/db?schema=public"
```

Run the initial migration:

```bash
bunx prisma migrate dev --name init
```

### Basic Implementation

```typescript
import { Elysia } from 'elysia'
import { PrismaClient } from '@prisma/client'

const db = new PrismaClient()

const app = new Elysia()
    .post(
        '/sign-up',
        async ({ body }) => db.user.create({
            data: body
        })
    )
    .listen(3000)
```

Important: When returning Prisma function results, always mark the callback function as `async` because Elysia requires async marking for proper promise handling.

### Type Validation

```typescript
import { Elysia, t } from 'elysia'
import { PrismaClient } from '@prisma/client'

const db = new PrismaClient()

const app = new Elysia()
    .post(
        '/sign-up',
        async ({ body }) => db.user.create({
            data: body
        }),
        {
            body: t.Object({
                username: t.String(),
                password: t.String({
                    minLength: 8
                })
            })
        }
    )
    .listen(3000)
```

### Error Handling

Handle Prisma error codes directly in route options:

```typescript
import { Elysia, t } from 'elysia'
import { PrismaClient } from '@prisma/client'

const db = new PrismaClient()

const app = new Elysia()
    .post(
        '/',
        async ({ body }) => db.user.create({
            data: body
        }),
        {
            error({ code }) {
                switch (code) {
                    case 'P2002':
                        return {
                            error: 'Username must be unique'
                        }
                }
            },
            body: t.Object({
                username: t.String(),
                password: t.String({
                    minLength: 8
                })
            })
        }
    )
    .listen(3000)
```

Error code `P2002` indicates unique constraint violations per Prisma documentation.

### Reference Schemas

Define reusable schemas with `.model()`:

```typescript
const app = new Elysia()
    .model({
        'user.sign': t.Object({
            username: t.String(),
            password: t.String({
                minLength: 8
            })
        })
    })
    .post(
        '/',
        async ({ body }) => db.user.create({
            data: body
        }),
        {
            error({ code }) {
                switch (code) {
                    case 'P2002':
                        return {
                            error: 'Username must be unique'
                        }
                }
            },
            body: 'user.sign'
        }
    )
    .listen(3000)
```

### Swagger / OpenAPI Documentation

```bash
bun add @elysiajs/swagger
```

```typescript
import { Elysia, t } from 'elysia'
import { PrismaClient } from '@prisma/client'
import { swagger } from '@elysiajs/swagger'

const db = new PrismaClient()

const app = new Elysia()
    .use(swagger())
    .post(
        '/',
        async ({ body }) =>
            db.user.create({
                data: body,
                select: {
                    id: true,
                    username: true
                }
            }),
        {
            error({ code }) {
                switch (code) {
                    case 'P2002':
                        return {
                            error: 'Username must be unique'
                        }
                }
            },
            body: t.Object({
                username: t.String(),
                password: t.String({
                    minLength: 8
                })
            }),
            response: t.Object({
                id: t.Number(),
                username: t.String()
            })
        }
    )
    .listen(3000)
```

The type system prevents accidentally returning sensitive fields like passwords from the API.

---

## Supabase + Elysia

### Setup

```bash
bun create elysia elysia-supabase
cd elysia-supabase
bun add elysia @elysiajs/cookie @supabase/supabase-js
```

Create `.env` with Supabase credentials:

```
supabase_url=https://[project].supabase.co
supabase_service_role=[service-role-key]
```

### Supabase Client Library

Create `src/libs/supabase.ts`:

```typescript
import { createClient } from '@supabase/supabase-js'

const { supabase_url, supabase_service_role } = process.env

export const supabase = createClient(supabase_url!, supabase_service_role!)
```

### Authentication Routes

Create `src/modules/authen.ts`:

```typescript
import { Elysia, t } from 'elysia'
import { supabase } from '../../libs'

const authen = (app: Elysia) =>
  app.group('/auth', (app) =>
    app
      .setModel({
        sign: t.Object({
          email: t.String({ format: 'email' }),
          password: t.String({ minLength: 8 })
        })
      })
      .post('/sign-up', async ({ body }) => {
        const { data, error } = await supabase.auth.signUp(body)
        if (error) return error
        return data.user
      }, { schema: { body: 'sign' } })
      .post('/sign-in', async ({ body }) => {
        const { data, error } = await supabase.auth.signInWithPassword(body)
        if (error) return error
        return data.user
      }, { schema: { body: 'sign' } })
  )
```

### Cookie-Based Session Storage

```typescript
import { cookie } from '@elysiajs/cookie'

app.use(
  cookie({
    httpOnly: true,
    // secure: true,        // HTTPS only
    // sameSite: "strict",  // Same-site policy
    // signed: true,        // Encryption
    // secret: process.env.COOKIE_SECRET
  })
)
```

### Token Refresh

```typescript
.get('/refresh', async ({ setCookie, cookie: { refresh_token } }) => {
  const { data, error } = await supabase.auth.refreshSession({
    refresh_token
  })
  if (error) return error
  setCookie('refresh_token', data.session!.refresh_token)
  return data.user
})
```

### Authorization with Derive

Create a reusable auth plugin at `src/libs/authen.ts`:

```typescript
export const authen = (app: Elysia) =>
  app
    .use(cookie())
    .derive(async ({ setCookie, cookie: { access_token, refresh_token } }) => {
      const { data, error } = await supabase.auth.getUser(access_token)

      if (data.user)
        return { userId: data.user.id }

      const { data: refreshed, error: refreshError } =
        await supabase.auth.refreshSession({ refresh_token })

      if (refreshError) throw error
      return { userId: refreshed.user!.id }
    })
```

### Database Operations

#### Create Post (Authorized)

```typescript
export const post = (app: Elysia) =>
  app.group('/post', (app) =>
    app
      .use(authen)
      .put('/create', async ({ body, userId }) => {
        const { data, error } = await supabase
          .from('post')
          .insert({ user_id: userId, ...body })
          .select('id')

        if (error) throw error
        return data[0]
      }, {
        schema: {
          body: t.Object({ detail: t.String() })
        }
      })
  )
```

#### Get Post (Public)

```typescript
.get('/:id', async ({ params: { id } }) => {
  const { data, error } = await supabase
    .from('post')
    .select()
    .eq('id', id)

  if (error) return error
  return {
    success: !!data[0],
    data: data[0] ?? null
  }
})
```

### Application Assembly

```typescript
import { Elysia } from 'elysia'
import { auth, post } from './modules'

const app = new Elysia()
  .use(auth)
  .use(post)
  .listen(3000)
```

### Swagger Integration

```bash
bun add @elysiajs/swagger
```

```typescript
import { swagger } from '@elysiajs/swagger'

const app = new Elysia()
  .use(swagger())
  .use(auth)
  .use(post)
  .listen(3000)
```

### Key Patterns

- **Schema Model Reusability**: Define schemas once via `setModel()` to reduce duplication across routes
- **Scope-Based Middleware**: Apply authorization selectively using `.use(authen)` within group scopes -- routes declared before remain public
- **Automatic Type Inference**: Elysia derives TypeScript types from schema definitions for compile-time safety
- **Row-Level Security**: Database relationships (`user_id` -> `auth.users`) enable Supabase RLS policies
