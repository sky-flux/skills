# Swagger Plugin (Legacy)

The `@elysiajs/swagger` plugin is the predecessor to the `@elysiajs/openapi` plugin. It has been deprecated in favor of the OpenAPI plugin, which provides the same functionality with an updated API.

Source: https://elysiajs.com/plugins/swagger

## Deprecation Notice

The Swagger plugin is no longer actively maintained. New projects should use `@elysiajs/openapi` instead. See `plugins/openapi.md` for the current plugin documentation.

## Installation

```bash
bun add @elysiajs/swagger
```

## Basic Usage

```typescript
import { Elysia } from 'elysia'
import { swagger } from '@elysiajs/swagger'

new Elysia()
    .use(swagger())
    .get('/', () => 'hi')
    .post('/hello', () => 'world')
    .listen(3000)
```

The plugin exposes two endpoints:

- `/swagger` -- Interactive Scalar UI documentation
- `/swagger/json` -- Raw OpenAPI specification in JSON format

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `provider` | `'scalar'` | UI documentation provider |
| `path` | `'/swagger'` | Endpoint path for documentation UI |
| `excludeStaticFile` | `true` | Exclude static files from docs |
| `exclude` | -- | Paths to omit (string, RegExp, or array) |
| `scalar` | -- | Scalar UI customization settings |
| `swagger` | -- | OpenAPI v2 specification config |

### Custom Path

```typescript
new Elysia()
    .use(swagger({ path: '/v2/swagger' }))
    .listen(3000)
```

### Documentation Info

```typescript
new Elysia()
    .use(swagger({
        documentation: {
            info: {
                title: 'My API',
                version: '1.0.0'
            }
        }
    }))
    .listen(3000)
```

### Endpoint Tags

Define tags in configuration and assign them via `detail.tags`:

```typescript
new Elysia()
    .use(swagger({
        documentation: {
            tags: [
                { name: 'App', description: 'General endpoints' },
                { name: 'Auth', description: 'Authentication' }
            ]
        }
    }))
    .get('/', () => 'Hello', {
        detail: { tags: ['App'] }
    })
    .listen(3000)
```

### Security Schemes

```typescript
new Elysia()
    .use(swagger({
        documentation: {
            components: {
                securitySchemes: {
                    bearerAuth: {
                        type: 'http',
                        scheme: 'bearer',
                        bearerFormat: 'JWT'
                    }
                }
            }
        }
    }))
    .listen(3000)
```

## Migration to OpenAPI Plugin

The `@elysiajs/openapi` plugin replaces `@elysiajs/swagger` with the following changes:

| Swagger (legacy) | OpenAPI (current) |
|-------------------|-------------------|
| `@elysiajs/swagger` | `@elysiajs/openapi` |
| `import { swagger }` | `import { openapi }` |
| `.use(swagger())` | `.use(openapi())` |
| Default path: `/swagger` | Default path: `/openapi` |
| Spec at `/swagger/json` | Spec at `/openapi/json` |

### Migration Steps

1. Replace the package:
```bash
bun remove @elysiajs/swagger
bun add @elysiajs/openapi
```

2. Update the import and usage:
```typescript
// Before
import { swagger } from '@elysiajs/swagger'
new Elysia().use(swagger())

// After
import { openapi } from '@elysiajs/openapi'
new Elysia().use(openapi())
```

3. Update any hardcoded references to `/swagger` paths to `/openapi`.

4. The `documentation` configuration object remains compatible between both plugins.

See also:
- `plugins/openapi.md` -- Current OpenAPI plugin documentation (recommended)
