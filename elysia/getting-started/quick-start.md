# Quick Start

> **Source**: https://elysiajs.com/quick-start

Elysia is a TypeScript backend framework optimized for Bun, with support for other JavaScript runtimes like Node.js.

---

## Prerequisites

### Install Bun Runtime

**macOS / Linux:**

```bash
curl -fsSL https://bun.sh/install | bash
```

**Windows:**

```bash
powershell -c "irm bun.sh/install.ps1 | iex"
```

---

## Scaffold a New Project

Use the automatic scaffold command to create a new Elysia project:

```bash
bun create elysia app
```

Then navigate into the project directory:

```bash
cd app
```

---

## Start the Development Server

Run the development server with automatic file-change reloading:

```bash
bun dev
```

Once running, visit `http://localhost:3000` to see the default response: `Hello Elysia`.

---

## Manual Setup

If you prefer to set up manually instead of using the scaffold command:

### 1. Initialize a new project

```bash
mkdir my-elysia-app
cd my-elysia-app
bun init
```

### 2. Install Elysia

```bash
bun add elysia
```

### 3. Create your first server

Create `src/index.ts`:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/', 'Hello Elysia')
    .listen(3000)
```

### 4. Run the server

```bash
bun run src/index.ts
```

---

## Basic Routing

Elysia supports all standard HTTP methods with a clean, chainable API:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/', 'Hello Elysia')
    .get('/user/:id', ({ params: { id } }) => id)
    .post('/form', ({ body }) => body)
    .listen(3000)
```

### Route Methods

| Method | Description |
|--------|-------------|
| `.get(path, handler)` | Handle GET requests |
| `.post(path, handler)` | Handle POST requests |
| `.put(path, handler)` | Handle PUT requests |
| `.patch(path, handler)` | Handle PATCH requests |
| `.delete(path, handler)` | Handle DELETE requests |

---

## Runtime Support

While Elysia is primarily optimized for Bun, it also supports:

- **Bun** - Primary runtime with full optimization
- **Node.js** - Supported runtime
- **Web Standard** - Compatible runtimes

---

## Development Features

- **Hot Reload**: The `bun dev` command automatically watches for file changes and restarts the server
- **TypeScript**: First-class TypeScript support with no additional configuration needed
- **Type Inference**: Automatic type inference for route parameters, body, and query strings
