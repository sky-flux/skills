# ElysiaJS Community Resources

Source: `elysiajs/awesome-elysia` repository and the broader ecosystem

## General Resources

- **Official Website**: [elysiajs.com](https://elysiajs.com) - Documentation, guides, and API reference
- **GitHub Organization**: [github.com/elysiajs](https://github.com/elysiajs) - 26 active repositories
- **Discord**: Community chat for support and discussion
- **Twitter/X**: [@elaboratejs](https://twitter.com/elaboratejs) - Project updates

## Video Tutorials

### Introductory

- **The BETH Stack: Build Hypermedia-Driven Web Apps with Great DX and Performance** - Comprehensive introduction to Bun + Elysia + Turso + HTMX stack
- **The Bun 1.0 Tech Stack** - Overview of building with Bun and ElysiaJS
- **Elysia Js Tutorial - Basic For Bun js Framework** - Getting started basics

### Project-Based

- **Building a RESTful API with Bun and ElysiaJS** - REST API fundamentals
- **Let's build a REST API with Bun, Prisma and Elysia** - Database integration tutorial
- **Build a Multi-Tenant B2B App With BUN and HTMX - FULL COURSE** - Full-length course covering multi-tenancy patterns

### International

- **Learning Bun, Docker, and Fly.io with Elysia Demo App** (Vietnamese) - Deployment-focused tutorial

## Articles and Guides

### Official Ecosystem

- **Build an HTTP server using Elysia and Bun** (bun.sh) - Official Bun guide featuring Elysia

### Getting Started

- **Create a CRUD App with Bun and Elysia.js** (dev.to) - Step-by-step CRUD tutorial
- **Bun CRUD API with Elysia.js & MongoDB** (Medium) - MongoDB integration guide

### Architecture

- **BETH: A Modern Stack for the Modern Web** (Stackademic) - Deep dive into the BETH stack architecture (Bun, Elysia, Turso, HTMX)

### Authentication

- **Add JWT Authentication in Bun API** (dev.to) - JWT auth implementation guide

### Deployment

- **Deploy Elysia With CloudFlare Workers** (Medium) - Cloudflare Workers deployment guide

## Boilerplate Projects

### Full-Stack Starters

| Project | Stack | Key Features |
|---|---|---|
| **elysia-kickstart** | Elysia + HTMX + Tailwind + Auth.js + Drizzle | CI/CD, Docker, Railway/Vercel deployment |
| **dbest-stack** | DrizzleORM + Bun + Elysia + SolidStart + Tailwind | Full-stack with SolidJS frontend |
| **elysia-fullstack** | Elysia + Bun + Prisma + Vite + React + Tailwind | Dockerized full-stack setup |
| **elysia-better-auth-template** | Elysia + Better Auth + Postgres | Modern authentication template |

### API Starters

| Project | Stack | Key Features |
|---|---|---|
| **elysia-routing-controllers** | Elysia + Turso SQLite + Drizzle | Controller-based routing pattern |
| **elysia-clean-architecture** | Elysia + Bun + Postgres.js | Clean Architecture API example |

### Specialized

| Project | Focus | Description |
|---|---|---|
| **elysia-ws-event** | WebSocket | Event-driven WebSocket server |
| **elysia-caddy-starter** | Deployment | Elysia wrapped with Caddy reverse proxy (Dockerized) |

## Official Plugins

The ElysiaJS organization maintains 14+ official plugins:

### Core Functionality

| Plugin | Package | Purpose |
|---|---|---|
| **Eden** | `@elysiajs/eden` | Type-safe client (Treaty + Fetch) |
| **OpenAPI** | `@elysiajs/openapi` | Auto-generated API documentation (Swagger/Scalar UI) |
| **CORS** | `@elysiajs/cors` | Cross-Origin Resource Sharing |
| **Static** | `@elysiajs/static` | Static file serving with ETag caching |
| **HTML** | `@elysiajs/html` | JSX/HTML response support via KitaJS |
| **Stream** | `@elysiajs/stream` | Server-Sent Events (legacy; generators now preferred) |

### Authentication and Security

| Plugin | Package | Purpose |
|---|---|---|
| **JWT** | `@elysiajs/jwt` | JSON Web Token sign/verify |
| **Bearer** | `@elysiajs/bearer` | Bearer token extraction (RFC 6750) |
| **Cookie** | `@elysiajs/cookie` | Cookie management (legacy; now built-in) |
| **Lucia** | `@elysiajs/lucia` | Lucia auth integration (legacy) |

### GraphQL

| Plugin | Package | Purpose |
|---|---|---|
| **GraphQL Yoga** | `@elysiajs/graphql-yoga` | GraphQL via graphql-yoga |
| **Apollo** | `@elysiajs/apollo` | GraphQL via Apollo Server |

### Observability

| Plugin | Package | Purpose |
|---|---|---|
| **OpenTelemetry** | `@elysiajs/opentelemetry` | Distributed tracing with OpenTelemetry SDK |
| **Server Timing** | `@elysiajs/server-timing` | Server-Timing header for DevTools |

### Scheduling

| Plugin | Package | Purpose |
|---|---|---|
| **Cron** | `@elysiajs/cron` | Cron job scheduling via croner |

## Community Plugins

### Authentication and Authorization

| Plugin | Author | Description |
|---|---|---|
| **elysia-clerk** | wobsoriano | Clerk authentication integration |
| **elysia-oauth2** | bogeychan | OAuth 2.0 authorization code flow |
| **elysia-basic-auth** | itsyoboieltr | Basic HTTP authentication |
| **elysia-basic-auth** | eelkevdbos | Basic HTTP auth (request event based) |
| **elysia-session** | gaurishhs | Multi-runtime session management |

### Middleware and Utilities

| Plugin | Author | Description |
|---|---|---|
| **elysia-helmet** | DevTobias | Security headers (similar to helmet.js) |
| **elysia-rate-limit** | rayriffy | Simple lightweight rate limiter |
| **elysia-etag** | bogeychan | Automatic HTTP ETag generation |
| **elysia-nocache** | gaurishhs | Disable caching headers |
| **elysia-ip** | gaurishhs | Client IP address extraction |
| **elysia-requestid** | gtramontina | Request ID header forwarding |
| **elysia-http-error** | yfrans | HTTP error response helpers |
| **elysia-compression** | gusb3ll | Response compression |

### Logging

| Plugin | Author | Description |
|---|---|---|
| **logysia** | tristanisham | Classic logging middleware |
| **elysia-logger** | bogeychan | Pino-based logging |
| **elysia-logging** | otherguy | Multi-logger support (Pino, Winston, etc.) |

### Frontend Integration

| Plugin | Author | Description |
|---|---|---|
| **elysia-vite** | timnghg | Vite dev server integration |
| **elysia-vite-plugin-ssr** | timnghg | Vite Plugin SSR support |
| **elysia-hmr-html** | gtrabanco | HTML hot module reload |
| **elysia-inject-html** | gtrabanco | HTML code injection |

### Routing

| Plugin | Author | Description |
|---|---|---|
| **elysia-autoroutes** | wobsoriano | File-system based routing |
| **elysia-group-router** | itsyoboieltr | Folder-based group routing |

### Architecture

| Plugin | Author | Description |
|---|---|---|
| **elysia-decorators** | gaurishhs | TypeScript decorator-based routing |
| **elysia-polyfills** | bogeychan | Run Elysia on Node.js and Deno |
| **elysia-lambda** | TotalTechGeek | Deploy on AWS Lambda |

### Internationalization

| Plugin | Author | Description |
|---|---|---|
| **elysia-i18next** | eelkevdbos | i18next wrapper for i18n |

## Popular Stack Patterns

### BETH Stack

The most widely adopted Elysia stack:
- **B**un - JavaScript runtime
- **E**lysia - Web framework
- **T**urso - SQLite database (edge-compatible)
- **H**TMX - Hypermedia-driven frontend

### Elysia + Drizzle

Popular for type-safe database access:
- Elysia for API layer
- Drizzle ORM for database queries
- SQLite (Turso/libSQL) or PostgreSQL

### Elysia + React/SolidJS

Full-stack with modern frontend:
- Elysia API with Eden client
- Vite for frontend build
- React or SolidJS for UI
- End-to-end type safety via Eden Treaty

### Elysia + HTMX + KitaJS

Server-rendered hypermedia:
- Elysia with `@elysiajs/html`
- KitaJS for compile-time JSX-to-HTML
- HTMX for interactive updates
- No client-side JavaScript framework needed
