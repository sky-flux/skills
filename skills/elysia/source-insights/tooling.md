# ElysiaJS Tooling

Source: 6 tool repositories under `elysiajs/` organization

## `elysiajs/elf` - Project Scaffolding CLI

**Description**: Convenient way to scaffold Elysia projects

### What It Does

`elf` is an interactive CLI tool for creating new Elysia projects and adding plugins. It provides two main commands:

1. **`elf add`** - Add official plugins to an existing project
2. **`elf generate`** - Scaffold a new Elysia project from templates

### Source Structure

```
src/
  elf.ts           # CLI entry point with command routing
  add/             # Plugin installation logic
  generate/        # Project scaffolding templates
  utils/           # Shared utilities (package manager detection, install)
```

### Key Implementation Details

- Uses `@inquirer/select` for interactive prompts when no arguments provided
- Supports shorthand commands: `a`/`add`, `g`/`gen`/`generate`, `v`/`version`
- Argument parsing via `minimist`
- Detects and uses the appropriate package manager (`bun`, `npm`, etc.)
- The `add` command installs `@elysiajs/*` packages and configures them
- The `generate` command creates project structure with chosen template

### When to Use

- Starting a new Elysia project: `bunx @elysiajs/elf generate`
- Adding an official plugin: `bunx @elysiajs/elf add cors jwt`

---

## `elysiajs/publisher` - Local CI / Release Manager

**Description**: Elysia local CI for managing the monorepo release process

### What It Does

Automates the Elysia ecosystem release workflow across all official packages. Handles version bumping, peer dependency updates, building, testing, and publishing.

### Source Structure

```
src/
  index.ts           # Main entry, global types (PackageJSON interface)
  packages.ts        # Package registry and ordering
  build.ts           # Build orchestration
  test.ts            # Test runner
  release.ts         # Release workflow
  push.ts            # Git push automation
  install.ts         # Dependency installation
  update.ts          # Version update logic
  update-package.ts  # Package.json modification
  rename-version.ts  # Version string manipulation
  overwrite.ts       # File overwrite utilities
  peer.ts            # Peer dependency management
  add-remove.ts      # Add/remove packages
  utils.ts           # Shared helpers
```

### Key Implementation Details

- Defines the canonical list of all ElysiaJS packages and their dependency order
- Updates `peerDependencies.elysia` across all plugin packages
- Coordinates builds in dependency order (core first, then plugins)
- Runs test suites before publishing
- Handles npm publish with version tagging

### When to Use

- Releasing a new version of Elysia and all plugins
- Updating peer dependency versions across the ecosystem
- Running coordinated builds and tests

---

## `elysiajs/json-accelerator` - JSON Serialization Optimizer

**Description**: Accelerate JSON stringification by providing OpenAPI/TypeBox shape

### What It Does

Generates optimized, schema-aware `JSON.stringify()` replacements. Instead of generic serialization, it produces specialized stringifier functions that know the exact shape of the data, avoiding runtime type checks.

### Source Structure

```
src/
  index.ts    # Single-file implementation
```

### Key Implementation Details

- Takes a TypeBox schema (TObject, TArray, TRecord, etc.) as input
- Generates a specialized function string that serializes objects field-by-field
- Handles:
  - Nested objects and arrays
  - Optional/nullable fields
  - Union types (anyOf)
  - Integer format detection (string that looks like a number)
  - Special property names (spaces, hyphens, etc.)
  - Metadata extraction for nullable/undefinable fields
- Uses `new Function()` to compile the generated serializer
- Property access is inlined (e.g., `v.name` instead of dynamic key lookup)

### Performance Benefit

Standard `JSON.stringify()` must check the type of every value at runtime. The accelerator knows the shape at compile time, so it:
- Skips type checks for known primitives
- Directly concatenates string properties
- Inlines number/boolean conversion
- Avoids prototype chain lookups

### When to Use

- High-throughput APIs where JSON serialization is a bottleneck
- Elysia uses this internally when `encodeSchema: true` (default) to accelerate response serialization based on declared response schemas

---

## `elysiajs/exact-mirror` - TypeBox/OpenAPI Model Mirroring

**Description**: Mirror exact value to TypeBox/OpenAPI model

### What It Does

Generates optimized response encoding functions from TypeBox schemas, similar to json-accelerator but focused on creating exact mirrors of schema-defined structures. Used internally by Elysia for response encoding.

### Source Structure

```
src/
  index.ts    # Single-file implementation
```

### Key Implementation Details

- Processes TypeBox schemas including: Object, Array, Record, Union (anyOf), Intersect (allOf), Optional, Ref
- `mergeObjectIntersection()`: Flattens `allOf` intersections into a single object schema for efficient code generation
- Handles `$ref` references by resolving them through TypeBox's module system
- Supports HTML sanitization via a configurable `sanitize` parameter for string fields (prevents XSS)
- Uses TypeBox's `TypeCompiler` for schema validation
- Generates property access chains with proper optional chaining (`?.`) for nullable paths
- Special property name handling (spaces, brackets, dots, numeric-prefix)

### When to Use

- Used internally by Elysia's response encoding pipeline
- When you need to generate a typed response object that exactly matches a schema, stripping any extra properties
- For building custom response serializers that are schema-aware

---

## `elysiajs/sirine` - Function-as-Endpoint

**Description**: Export function as endpoint

### What It Does

Allows exporting plain functions that automatically become HTTP endpoints. A minimal framework for serverless-style function deployment.

### Source Structure

```
src/
  index.ts    # Request handling and routing
```

### Key Implementation Details

- Implements its own `mapResponse()` that converts return values to `Response`:
  - `String` -> `new Response(string)`
  - `Blob/File` -> `new Response(blob)` with `content-range` header
  - `Object/Array` -> `Response.json()`
  - `ReadableStream` -> SSE response with `text/event-stream`
  - `Error` -> 500 status JSON response
  - `Promise` -> Recursive await and map
  - `Function` -> Call and map result
- Uses `Memoirist` router (same as core Elysia)
- Parses request bodies based on Content-Type
- Supports Zod for input validation (`literal` import from zod)

### When to Use

- Deploying individual functions as HTTP endpoints
- Lightweight serverless-style development without the full Elysia class
- Prototyping endpoints quickly

---

## `elysiajs/node` - Node.js Adapter

**Description**: Run Elysia on Node.js

### What It Does

Provides a complete Node.js adapter for Elysia, enabling it to run on Node.js in addition to Bun. Bridges the gap between Node.js's `http`/`http2` APIs and Elysia's Web Standard-based architecture.

### Source Structure

```
src/
  index.ts     # Adapter definition and server setup
  handle.ts    # Response mapping (mapResponse, mapEarlyResponse, mapCompactResponse)
  ws.ts        # WebSocket adapter using crossws
  utils.ts     # Node.js-specific utilities
```

### Key Implementation Details

- **Extends `WebStandardAdapter`**: Inherits the Web Standard base and overrides response mapping
- **Response mapping**: Converts Elysia's `Response` objects to Node.js `ServerResponse` write calls
- **WebSocket support**: Uses `crossws` library to provide a unified WebSocket interface over Node.js
  - `createWebSocketAdapter()` creates a crossws-compatible adapter
  - Handles `upgrade`, `open`, `message`, `close` lifecycle events
  - Maps to Elysia's `ServerWebSocket` interface
- **Server creation**: Uses Node's `http.createServer()` (or `http2`) with the crossws `serve()` wrapper
- **Static handler**: `createStaticHandler()` generates pre-computed Node.js responses

### Adapter Registration

```typescript
export const node = () => ({
    ...WebStandardAdapter,
    name: '@elysiajs/node',
    handler: { mapCompactResponse, mapEarlyResponse, mapResponse, createStaticHandler },
    ws: ws.handler,
    listen(app) {
        return (options, callback) => {
            // Creates Node.js http server with crossws middleware
        }
    }
})
```

### When to Use

```typescript
import { Elysia } from 'elysia'
import { node } from '@elysiajs/node'

new Elysia({ adapter: node() })
    .get('/', () => 'Hello from Node.js!')
    .listen(3000)
```

- When deploying to environments without Bun (e.g., AWS Lambda with Node.js runtime, existing Node.js infrastructure)
- When you need Node.js-specific features or npm packages that require Node.js APIs
- For gradual migration from Express/Fastify to Elysia

### Runtime Compatibility

The Node adapter transforms Elysia's Web Standard `Request`/`Response` to work with Node.js's `IncomingMessage`/`ServerResponse`. This means:
- All Elysia features work (routing, validation, hooks, plugins)
- Some Bun-specific optimizations are not available (native static responses, Bun.serve)
- WebSocket support uses `crossws` instead of Bun's native WebSocket
