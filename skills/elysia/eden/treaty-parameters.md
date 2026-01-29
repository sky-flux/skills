# Eden Treaty Parameters

Eden Treaty methods accept 2 parameters to send data to the server. Both parameters are type safe and guided by TypeScript automatically:

1. **body** - request body
2. **additional parameters** (optional object):
   - `query` - query string parameters
   - `headers` - request headers
   - `fetch` - fetch RequestInit options

## Body + Additional Parameters (POST/PUT/PATCH/DELETE)

Methods that accept body take it as the first argument, with optional additional parameters as the second argument:

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .post('/user', ({ body }) => body, {
        body: t.Object({
            name: t.String()
        })
    })
    .listen(3000)

const api = treaty<typeof app>('localhost:3000')

// Body only
api.user.post({
    name: 'Elysia'
})

// Body + additional parameters
api.user.post({
    name: 'Elysia'
}, {
    // This is optional as not specified in schema
    headers: {
        authorization: 'Bearer 12345'
    },
    query: {
        id: 2
    }
})
```

## No Body (GET/HEAD)

Methods that do not accept body (GET, HEAD) take only additional parameters as a single argument:

```typescript
import { Elysia } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .get('/hello', () => 'hi')
    .listen(3000)

const api = treaty<typeof app>('localhost:3000')

api.hello.get({
    // This is optional as not specified in schema
    headers: {
        hello: 'world'
    }
})
```

## Empty Body

If body is optional or not needed but query or headers is required, pass the body as `null` or `undefined`:

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .post('/user', () => 'hi', {
        query: t.Object({
            name: t.String()
        })
    })
    .listen(3000)

const api = treaty<typeof app>('localhost:3000')

api.user.post(null, {
    query: {
        name: 'Ely'
    }
})
```

## Fetch Parameters

Eden Treaty is a fetch wrapper. You can add any valid Fetch parameters by passing them to `fetch`:

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .get('/hello', () => 'hi')
    .listen(3000)

const api = treaty<typeof app>('localhost:3000')

const controller = new AbortController()

const cancelRequest = setTimeout(() => {
    controller.abort()
}, 5000)

await api.hello.get({
    fetch: {
        signal: controller.signal
    }
})

clearTimeout(cancelRequest)
```

## File Upload

To attach files, pass one of the following types:

- `File`
- `File[]`
- `FileList`
- `Blob`

Attaching a file results in `content-type` being set to `multipart/form-data`.

```typescript
import { Elysia, t } from 'elysia'
import { treaty } from '@elysiajs/eden'

const app = new Elysia()
    .post('/image', ({ body: { image, title } }) => title, {
        body: t.Object({
            title: t.String(),
            image: t.Files()
        })
    })
    .listen(3000)

export const api = treaty<typeof app>('localhost:3000')

const images = document.getElementById('images') as HTMLInputElement

const { data } = await api.image.post({
    title: "Misono Mika",
    image: images.files!,
})
```

## Quick Reference

| Scenario | Syntax |
|----------|--------|
| POST with body | `.user.post({ name: 'Elysia' })` |
| POST with body + headers | `.user.post({ name: 'Elysia' }, { headers: { auth: 'x' } })` |
| GET with query | `.hello.get({ query: { name: 'x' } })` |
| POST with empty body + query | `.user.post(null, { query: { name: 'x' } })` |
| GET with fetch options | `.hello.get({ fetch: { signal: controller.signal } })` |
| File upload | `.image.post({ title: 'x', image: fileInput.files! })` |
