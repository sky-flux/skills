# Tutorial Introduction

> **Sources:**
> - https://elysiajs.com/tutorial
> - https://elysiajs.com/tutorial/whats-next

## Welcome to Elysia

Elysia is a backend TypeScript framework that focuses on developer experience and performance. The tutorial provides an interactive learning environment where you can experiment directly in the browser.

Key differentiators of Elysia include:

1. Performance comparable to Golang
2. Extraordinary TypeScript support with type soundness
3. Built around OpenAPI from the ground up
4. End-to-end type safety similar to tRPC
5. Uses Web Standards (compatible with Cloudflare Workers, Deno, Bun, Node.js)
6. Designed for humans first

The framework contains unique concepts that require learning, but users typically find it very enjoyable and intuitive to work with once familiar.

## What is Elysia

Elysia is an ergonomic web framework for building backend applications with TypeScript. Unlike traditional backend frameworks, Elysia can also run in a browser, allowing you to write and try out Elysia directly in your browser's playground.

## How to Use the Playground

The playground consists of three sections:

- **Documentation and task** (left side)
- **Code editor** (top right)
- **Preview, output, and console** (bottom right)

## First Assignment: Hello Elysia

Modify the starter code to respond with `"Hello Elysia!"` instead of `"Hello World!"`:

```typescript
import { Elysia } from 'elysia'

new Elysia()
	.get('/', 'Hello Elysia!')
	.listen(3000)
```

Change the response string within the `.get` method to `'Hello Elysia!'` to make the server respond accordingly when accessing the `/` route.

## Prerequisites

Before starting the tutorial, ensure you have:

- A modern web browser for the interactive playground
- Basic familiarity with TypeScript or JavaScript
- Understanding of HTTP concepts (methods, status codes, headers)

## Learning Path

The tutorial is organized into the following sections:

### Getting Started
- Your First Route
- Handler and Context
- Validation
- Plugin
- Life Cycle
- Encapsulation
- Guard
- Status and Headers

### Patterns
- Cookie
- Error Handling
- Extends Context
- Macro
- Validation Error
- Standalone Schema

### Features
- Mount
- OpenAPI
- End-to-End Type Safety
- Unit Test

## What's Next

After completing the tutorial, review these foundational pages before starting your own application:

- **Key Concept** - Core principles of Elysia and effective usage patterns
- **Best Practice** - Guidelines for writing quality Elysia code

### LLM Resources

For interactive learning with AI assistants, downloadable documentation files are available:

- `llms.txt` - Summarized Elysia documentation in Markdown format for LLM prompts
- `llms-full.txt` - Complete Elysia documentation as a single file

### Community Support

If you get stuck, community support is available through:

- **Discord** - Official ElysiaJS community server
- **Twitter** - Updates and project status (@elysiajs)
- **GitHub** - Source code and development

### Transitioning From Other Frameworks

Comparison guides exist for developers migrating from:

- Express
- Fastify
- Hono
- tRPC

### Essential Chapters

Foundational topics recommended before exploring advanced features:

- Route handling and routing mechanics
- Request handlers and response patterns
- Type-safe validation enforcement
- Lifecycle hooks and event patterns
- Plugin system for extending functionality

### Additional Exploration

Advanced patterns and features:

- Real-time applications with WebSocket
- Eden client library usage
- Application monitoring with OpenTelemetry
- Production deployment strategies

### Meta Framework Integration

Elysia works with popular frameworks: Astro, Expo, Next.js, Nuxt, SvelteKit.

### Popular Tool Integrations

AI SDK, Better Auth, Drizzle, Prisma, React Email.
