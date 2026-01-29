
# Netlify Edge Function Integration

## What It Is
Netlify Edge Functions run on Deno, which is one of Elysia's supported runtimes since Elysia is built on Web Standard.

## File Structure
Place edge functions in the `netlify/edge-functions` directory. The file name maps to the endpoint path.

For a `/hello` endpoint, create `netlify/edge-functions/hello.ts`:
```
├─ netlify
│  └─ edge-functions
│     └─ hello.ts
```

## Setup
1. Create `netlify/edge-functions/hello.ts`:
```typescript
import { Elysia } from 'elysia'

export const config = { path: '/hello' }

export default new Elysia({ prefix: '/hello' })
	.get('/', () => 'Hello Elysia')
```

Key points:
- Export a `config` object with `path` matching the route
- Export a default Elysia instance with a matching `prefix`

## Local Development
1. Install Netlify CLI:
```bash
bun add -g netlify-cli
```

2. Start the dev server:
```bash
netlify dev
```

This simulates edge function invocation locally.

## pnpm
pnpm does not auto-install peer dependencies, so you must install them manually:
```bash
pnpm add @sinclair/typebox openapi-types
```
