# Fullstack Dev Server
Using Bun 1.3's integrated fullstack dev server with ElysiaJS — run React with HMR and no separate bundler.

## Overview

Bun 1.3 introduced a fullstack dev server with HMR support. This allows direct use of React (or other frontend frameworks) without Vite or Webpack, combining frontend and backend development in a single project.

## Setup

### 1. Install the Static Plugin

Use `await` syntax to enable HMR hooks:

```typescript
import { Elysia } from 'elysia'
import { staticPlugin } from '@elysiajs/static'

new Elysia()
    .use(await staticPlugin())
    .listen(3000)
```

### 2. Create the HTML Entry Point

**public/index.html**
```html
<div id="root"></div>
<script type="module" src="./index.tsx"></script>
```

### 3. Configure TypeScript for JSX

**tsconfig.json**
```json
{
    "compilerOptions": {
        "jsx": "react-jsx"
    }
}
```

## Custom Prefix Path

Change the default `/public` prefix:

```typescript
.use(
    await staticPlugin({
        prefix: '/'
    })
)
```

## Tailwind CSS Integration

Tailwind CSS 4 works via the `bun-plugin-tailwind` plugin. Configure it in `bunfig.toml`.

## Path Aliases

Define aliases in `tsconfig.json` — they work automatically without extra configuration:

```json
{
    "compilerOptions": {
        "baseUrl": ".",
        "paths": {
            "@public/*": ["public/*"]
        }
    }
}
```

## Production Build

Build the fullstack server the same way as a standard Elysia app:

```bash
bun build --compile --target bun --outfile server src/index.ts
```

The compiled binary requires the `public` folder in the same deployment directory.

## Compatibility

Verified to work with:
- HMR (hot module replacement)
- Tailwind CSS
- TanStack Query
- Eden Treaty
- Path aliases
