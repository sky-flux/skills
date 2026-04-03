# ElysiaJS 技能

[English](./README.md) | **中文**

一套全面的 Claude Code 技能，用于构建类型安全、高性能的 [ElysiaJS](https://elysiajs.com) 后端应用。

## 功能

这套技能让 Claude Code 深入掌握 ElysiaJS 生态，能够：

- 使用推荐的 MVC / 领域驱动模式搭建项目结构
- 编写类型安全的路由、处理器、校验 Schema（TypeBox、Zod、Valibot）和响应类型
- 实现认证、守卫和宏（JWT、会话、RBAC）
- 配置和使用官方插件（CORS、OpenAPI、JWT、静态文件、WebSocket、Cron 等）
- 集成外部工具：Drizzle ORM、Prisma、Better Auth、Vercel AI SDK 等
- 部署到 Bun、Node.js、Deno、Cloudflare Workers、Vercel、Netlify
- 搭建 Eden Treaty 实现服务端与客户端的端到端类型安全 RPC
- 使用内置 Treaty 测试工具编写单元测试
- 从 Express、Fastify、Hono 或 tRPC 迁移现有代码库

## 触发示例

- "用 JWT 认证和 Drizzle ORM 创建一个 ElysiaJS REST API"
- "给我的 Elysia 服务器添加 WebSocket 端点做实时聊天"
- "搭建 Eden Treaty 让 React 前端有类型安全的 API 调用"
- "把我的 Express 应用迁移到 ElysiaJS"
- "给我的 Elysia 路由添加 OpenAPI 文档"
- "给我的 Elysia 端点写单元测试"

## 目录结构

| 目录 / 文件 | 说明 |
|---|---|
| `SKILL.md` | AI 指令集 — 核心概念、最佳实践、快速入门示例 |
| `references/` | 核心文档：路由、校验、生命周期、插件、Eden、WebSocket、测试、部署 |
| `plugins/` | 官方插件文档：CORS、JWT、OpenAPI、静态文件、GraphQL、OpenTelemetry 等 |
| `integrations/` | 集成指南：Drizzle、Prisma、Better Auth、Next.js、Astro、SvelteKit、Expo、Vercel AI SDK 等 |
| `eden/` | Eden Treaty 完整文档：配置、参数、响应、WebSocket、单元测试、迁移 |
| `patterns/` | 高级模式：MVC、错误处理、上下文扩展、TypeBox 类型、宏、追踪、部署 |
| `migrations/` | 逐步迁移指南：从 Express、Fastify、Hono、tRPC 迁移 |
| `getting-started/` | 框架概览、快速入门、核心概念 |
| `essential/` | 处理器模式、Context API、最佳实践 |
| `tutorials/` | 整合教程 — 覆盖完整学习路径 |
| `blog/` | 版本亮点（v0.x–v1.x）、集成指南、性能基准 |
| `source-insights/` | 架构深度解析：核心内部实现、Eden 代理、插件生态、工具链 |
| `examples/` | 可运行的 TypeScript 示例（路由、文件上传、WebSocket、Cookie、守卫等） |

## 安装

```bash
npx skills add sky-flux/skills --skill elysiajs
```
