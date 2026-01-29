# Eden Installation

## Install

Install Eden on your frontend:

```bash
bun add @elysiajs/eden
bun add -d elysia
```

> **Tip:** Eden needs Elysia to infer utilities type. Make sure to install Elysia with the version matching on the server.

## Server Setup: Export the Type

On the server, export the Elysia app type:

```typescript
// server.ts
import { Elysia, t } from 'elysia'

const app = new Elysia()
    .get('/', () => 'Hi Elysia')
    .get('/id/:id', ({ params: { id } }) => id)
    .post('/mirror', ({ body }) => body, {
        body: t.Object({
            id: t.Number(),
            name: t.String()
        })
    })
    .listen(3000)

export type App = typeof app
```

## Client-Side Usage

Consume the API on the client:

```typescript
// client.ts
import { treaty } from '@elysiajs/eden'
import type { App } from './server'

const client = treaty<App>('localhost:3000')

// response: Hi Elysia
const { data: index } = await client.get()

// response: 1895
const { data: id } = await client.id({ id: 1895 }).get()

// response: { id: 1895, name: 'Skadi' }
const { data: nendoroid } = await client.mirror.post({
    id: 1895,
    name: 'Skadi'
})
```

## Gotchas

### Type Strict

Enable strict mode in **tsconfig.json**:

```json
{
  "compilerOptions": {
    "strict": true
  }
}
```

### Unmatch Elysia Version

Eden depends on the Elysia class to import the Elysia instance and infer types correctly. Verify matching versions:

```bash
npm why elysia
```

Ensure a single top-level version is resolved.

### TypeScript Version

Elysia uses newer features and syntax of TypeScript to infer types in the most performant way. Features like Const Generic and Template Literal are heavily used.

Minimum required: **TypeScript >= 5.0**

### Method Chaining

To make Eden work, Elysia must use method chaining. Each method returns a new type reference.

Correct:
```typescript
import { Elysia } from 'elysia'

new Elysia()
    .state('build', 1)
    // Store is strictly typed
    .get('/', ({ store: { build } }) => build)
    .listen(3000)
```

Incorrect (breaks type inference):
```typescript
import { Elysia } from 'elysia'

const app = new Elysia()

app.state('build', 1)

app.get('/', ({ store: { build } }) => build)
// Property 'build' does not exist on type '{}'.
app.listen(3000)
```

### Type Definitions

If you use Bun-specific features, install:

```bash
bun add -d @types/bun
```

### Path Alias (Monorepo)

If you use path aliases in a monorepo, make sure the frontend resolves the path the same as the backend.

Example tsconfig.json:
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

Backend:
```typescript
import { Elysia } from 'elysia'
import { a, b } from '@/controllers'

const app = new Elysia()
    .use(a)
    .use(b)
    .listen(3000)

export type app = typeof app
```

Frontend must resolve the same paths:
```typescript
import { treaty } from '@elysiajs/eden'
import type { app } from '@/index'

const client = treaty<app>('localhost:3000')
```

For monorepo, update the frontend tsconfig.json:
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["../apps/backend/src/*"]
    }
  }
}
```

#### Namespace Recommendation

We recommend adding a namespace prefix for each module in your monorepo to avoid confusion and conflict:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@frontend/*": ["./apps/frontend/src/*"],
      "@backend/*": ["./apps/backend/src/*"]
    }
  }
}
```

Usage:
```typescript
import { a, b } from '@backend/controllers'
```

> **Tip:** Create a single root tsconfig.json defining baseUrl and paths, with separate tsconfig.json for each module inheriting the root.
