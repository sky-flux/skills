# TypeScript
Elysia offers first-class support for TypeScript out of the box. The framework requires minimal manual type annotations in most scenarios.

## Inference

Elysia automatically determines request and response types based on provided schemas.

```typescript
import { Elysia, t } from 'elysia'
import { z } from 'zod'

const app = new Elysia()
    .post('/user/:id', ({ body }) => body, {
        body: t.Object({
            id: t.String()
        }),
        query: z.object({
            name: z.string()
        })
    })
```

Elysia supports schema libraries including Zod, Valibot, ArkType, Effect Schema, Yup, and Joi for type conversion.

## Schema to Type

All supported schema libraries can convert to TypeScript types. Using TypeBox:

```typescript
import { Elysia, t } from 'elysia'

const User = t.Object({
    id: t.String(),
    name: t.String()
})

type User = typeof User['static']
```

## Type Performance

Elysia prioritizes type inference performance through pre-release benchmarking to prevent deep type errors.

### Debugging Slow Inference

Run at the project root to generate a trace:

```bash
tsc --generateTrace trace --noEmit --incremental false
```

Open the generated `trace/trace.json` in Perfetto UI (https://ui.perfetto.dev) to identify type inference bottlenecks.

### Eden Optimization

Use sub-app exports to isolate inference and improve performance in Eden clients:

```typescript
import { Elysia } from 'elysia'
import { plugin1, plugin2, plugin3 } from './plugin'

const app = new Elysia()
    .use([plugin1, plugin2, plugin3])
    .listen(3000)

export type app = typeof app
export type subApp = typeof plugin1
```

Frontend implementation using sub-app type:

```typescript
import { treaty } from '@elysiajs/eden'
import type { subApp } from 'backend/src'

const api = treaty<subApp>('localhost:3000')
```

This isolates plugin type inference, reducing the type computation burden on the TypeScript compiler when using Eden on the frontend.
