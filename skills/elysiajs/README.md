# ElysiaJS Skill

**English** | [中文](./README.zh-CN.md)

A comprehensive Claude Code skill for building type-safe, high-performance backends with [ElysiaJS](https://elysiajs.com).

## What it does

This skill gives Claude Code deep knowledge of the ElysiaJS ecosystem, enabling it to:

- Scaffold and structure ElysiaJS projects using recommended MVC/domain-driven patterns
- Write type-safe routes, handlers, validation schemas (TypeBox, Zod, Valibot), and response types
- Implement authentication, guards, and macros (JWT, session, RBAC)
- Configure and use official plugins (CORS, OpenAPI, JWT, static files, WebSocket, cron, and more)
- Integrate with external tools: Drizzle ORM, Prisma, Better Auth, Vercel AI SDK, and others
- Deploy to Bun, Node.js, Deno, Cloudflare Workers, Vercel, and Netlify
- Set up Eden Treaty for end-to-end type-safe RPC between server and client
- Write unit tests using the built-in Treaty test utilities
- Migrate existing codebases from Express, Fastify, Hono, or tRPC

## Trigger examples

- "Create an ElysiaJS REST API with JWT authentication and Drizzle ORM"
- "Add a WebSocket endpoint to my Elysia server for real-time chat"
- "Set up Eden Treaty so my React frontend has type-safe API calls"
- "Migrate my Express app to ElysiaJS"
- "Add OpenAPI documentation to my Elysia routes"
- "Write unit tests for my Elysia endpoints"

## Contents

| Directory / File | Description |
|---|---|
| `SKILL.md` | AI instructions, key concepts, best practices, and quick-start examples |
| `references/` | Core documentation: routing, validation, lifecycle, plugins, Eden, WebSocket, testing, deployment |
| `plugins/` | Official plugin docs: CORS, JWT, OpenAPI, static, GraphQL, OpenTelemetry, and more |
| `integrations/` | Integration guides for Drizzle, Prisma, Better Auth, Next.js, Astro, SvelteKit, Expo, Vercel AI SDK, and others |
| `eden/` | Complete Eden Treaty docs: setup, parameters, responses, WebSocket, unit testing, and migration |
| `patterns/` | Advanced patterns: MVC, error handling, context extension, TypeBox types, macros, tracing, deployment |
| `migrations/` | Step-by-step migration guides from Express, Fastify, Hono, and tRPC |
| `getting-started/` | Framework overview, quick-start, and key concepts |
| `essential/` | Handler patterns, Context API, and best practices |
| `tutorials/` | Consolidated step-by-step tutorials covering the full learning path |
| `blog/` | Release highlights (v0.x–v1.x), integration guides, and performance benchmarks |
| `source-insights/` | Architecture deep-dives: core internals, Eden proxy, plugin ecosystem, and tooling |
| `examples/` | Runnable TypeScript examples (routing, file upload, WebSocket, cookies, guards, and more) |

## Installation

```bash
npx skills add sky-flux/skills --skill elysiajs
```
