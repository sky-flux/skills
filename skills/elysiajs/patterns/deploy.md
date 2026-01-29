# Deploy
Production deployment patterns for ElysiaJS — cluster mode, binary compilation, Docker, and platform-specific configuration.

## Cluster Mode

Elysia is single-threaded by default. Fork workers to leverage multi-core processors:

**src/index.ts**
```typescript
import cluster from 'node:cluster'
import os from 'node:os'
import process from 'node:process'

if (cluster.isPrimary) {
    for (let i = 0; i < os.availableParallelism(); i++)
        cluster.fork()
} else {
    await import('./server')
    console.log(`Worker ${process.pid} started`)
}
```

**src/server.ts**
```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/', () => 'Hello World!')
    .listen(3000)
```

Bun uses `SO_REUSEPORT` by default, allowing multiple instances on the same port (Linux only).

## Binary Compilation

Compile to a portable binary to reduce memory usage by 2-3x:

```bash
bun build \
  --compile \
  --minify-whitespace \
  --minify-syntax \
  --target bun \
  --outfile server \
  src/index.ts
```

Run the resulting binary without requiring Bun on the host:

```bash
./server
```

### Cross-Platform Targets

Specify the platform with `--target`:

```bash
bun build \
  --compile \
  --minify-whitespace \
  --minify-syntax \
  --target bun-linux-x64 \
  --outfile server \
  src/index.ts
```

Available targets: `bun-linux-x64`, `bun-linux-arm64`, `bun-windows-x64`, `bun-darwin-x64`, `bun-darwin-arm64`, and musl variants.

### Minification Note

The `--minify` flag reduces function names to single characters, which breaks OpenTelemetry tracing. Use granular flags (`--minify-whitespace`, `--minify-syntax`) instead when OpenTelemetry is in use.

### Permissions

Enable execution on Linux:

```bash
chmod +x ./server
./server
```

Bun requires AVX2 hardware support; there is no workaround for systems that lack it.

## JavaScript Bundle Alternative

For environments that cannot run compiled binaries (or Windows deployments):

```bash
bun build \
  --minify-whitespace \
  --minify-syntax \
  --outfile ./dist/index.js \
  src/index.ts
```

```bash
NODE_ENV=production bun ./dist/index.js
```

## Docker

Multi-stage Dockerfile using Distroless for minimal image size:

```dockerfile
FROM oven/bun AS build

WORKDIR /app

COPY package.json package.json
COPY bun.lock bun.lock

RUN bun install

COPY ./src ./src

ENV NODE_ENV=production

RUN bun build \
  --compile \
  --minify-whitespace \
  --minify-syntax \
  --outfile server \
  src/index.ts

FROM gcr.io/distroless/base

WORKDIR /app

COPY --from=build /app/server server

ENV NODE_ENV=production

CMD ["./server"]

EXPOSE 3000
```

### OpenTelemetry in Docker

Exclude instrumented libraries from bundling to preserve monkey-patching:

```bash
bun build --compile --external pg --outfile server src/index.ts
```

Ensure production dependencies are listed in `package.json`:

```json
{
    "dependencies": {
        "pg": "^8.15.6"
    },
    "devDependencies": {
        "@elysiajs/opentelemetry": "^1.2.0"
    }
}
```

Install production dependencies only:

```bash
bun install --production
```

### Monorepo Deployments

For Turborepo or similar structures, place the Dockerfile inside the app directory and build from the monorepo root:

```bash
docker build -f apps/server/Dockerfile -t elysia-mono .
```

Include all dependent package configs in the COPY statements.

## Railway

Railway assigns a dynamic port via the `PORT` environment variable:

```typescript
new Elysia()
    .listen(process.env.PORT ?? 3000)
```

Elysia automatically binds to `0.0.0.0`, which is compatible with Railway's infrastructure.
