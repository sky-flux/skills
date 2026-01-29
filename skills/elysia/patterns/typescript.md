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
// { id: string; name: string }
```

For Zod:
```typescript
import { z } from 'zod'

const UserSchema = z.object({
    id: z.string(),
    name: z.string()
})

type User = z.infer<typeof UserSchema>
```

## Recommended tsconfig Settings

For optimal Elysia type inference, use these compiler options:

```json
{
  "compilerOptions": {
    "strict": true,
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true,
    "types": ["bun-types"]
  }
}
```

Key settings:
- **`strict: true`** - Required for Eden type safety and proper error narrowing
- **`moduleResolution: "Bundler"`** - Best for Bun projects; avoids resolution issues with `.ts` imports
- **`skipLibCheck: true`** - Speeds up compilation by skipping type checks on `.d.ts` files in node_modules
- **`declaration: true`** - Required if exporting app types for Eden consumers in separate packages

## Type Performance

Elysia prioritizes type inference performance through pre-release benchmarking to prevent deep type errors.

### The "Excessively Deep" Error

The most common type error in large Elysia apps:

```
Type instantiation is excessively deep and possibly infinite. ts(2589)
```

This occurs when the TypeScript compiler exceeds its recursion limit evaluating chained method types. Common causes:
- Too many chained `.get()` / `.post()` calls on a single Elysia instance (50+ routes)
- Deeply nested plugin composition
- Complex generic type parameters in schema definitions

Solutions:
1. **Split into plugins** - Break large route files into smaller plugins with `new Elysia()` instances
2. **Use `.group()`** - Group related routes to reduce chain depth
3. **Export sub-app types** - See Eden Optimization below

### Debugging Slow Inference

Run at the project root to generate a trace:

```bash
tsc --generateTrace trace --noEmit --incremental false
```

Open the generated `trace/trace.json` in Perfetto UI (https://ui.perfetto.dev) to identify type inference bottlenecks.

The trace flame graph shows:
- Which files take the longest to type-check
- Specific line numbers causing deep instantiation
- Type evaluation counts per expression

### Eden Optimization

Use sub-app exports to isolate inference and improve performance in Eden clients:

```typescript
// server/src/index.ts
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

Additional Eden optimization strategies:
- **Lazy type imports** - Use `import type` exclusively for server types on the frontend to avoid bundling server code
- **Granular sub-app exports** - Export one type per domain plugin rather than the entire app type
- **Separate type package** - In monorepos, create a shared `types` package that re-exports only the server types Eden needs

```typescript
// packages/api-types/index.ts
export type { userRoutes } from '../../apps/server/src/routes/user'
export type { postRoutes } from '../../apps/server/src/routes/post'

// apps/frontend/src/api.ts
import { treaty } from '@elysiajs/eden'
import type { userRoutes } from '@myapp/api-types'

const userApi = treaty<userRoutes>('localhost:3000')
```

## Type Error Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Type instantiation is excessively deep` | Too many chained routes or deep plugin nesting | Split into sub-plugins, use `.group()` |
| `Property 'x' does not exist on type` | Schema not defined or plugin not chained | Add schema validation or check `.use()` ordering |
| `'data' is possibly null` | Eden response not narrowed | Check `error` before accessing `data` |
| `Type 'string' is not assignable to type 'never'` | Strict mode + missing schema | Add explicit schema or enable `strict: true` in tsconfig |
| `Cannot find module '@elysiajs/eden'` | Missing dependency or types | Run `bun add @elysiajs/eden` and `bun add -d elysia` |
| Eden shows `unknown` types | Version mismatch between elysia and eden | Run `npm why elysia` and ensure single version |

### Strict Mode Requirement

Eden requires `strict: true` in `tsconfig.json`. Without it, error narrowing does not work correctly:

```typescript
// With strict: true - correct behavior
const { data, error } = await api.user.get()
if (error) {
  // error is narrowed to the error type
  console.log(error.status)
}
// data is narrowed to the success type

// Without strict: true - data and error may both appear as any
```

### Method Chaining Requirement

Elysia builds its type system through method chaining. Breaking the chain loses type information:

```typescript
// CORRECT - chained methods preserve types
const app = new Elysia()
    .state('version', 1)
    .get('/', ({ store }) => store.version) // store.version is typed as number

// INCORRECT - separate statements lose types
const app = new Elysia()
app.state('version', 1)
app.get('/', ({ store }) => store.version) // store may not include 'version'
```
