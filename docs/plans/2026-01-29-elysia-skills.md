# ElysiaJS Enhanced Skills Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于官方 `elysiajs/skills` 仓库创建增强版 Elysia skills，补充网站所有未覆盖的文档内容和源码洞察。

**Architecture:** 以官方 skills 为基础，增加 7 个缺失的 patterns 文件、4 个 migration 指南、1 个缺失的 integration，并基于核心仓库源码增强 SKILL.md 主文件。所有内容从 elysiajs.com 页面和 GitHub 源码中提取。

**Tech Stack:** Markdown、TypeScript (示例文件)、Claude Code skills 格式

---

### Task 1: 初始化项目并导入官方 skills 基础

**Files:**
- Create: `elysia/` (整个目录，从官方仓库复制)
- Create: `.gitignore`

**Step 1: 克隆官方 skills 仓库**

Run: `git clone https://github.com/elysiajs/skills.git /tmp/elysiajs-skills-official`

**Step 2: 复制 elysia/ 目录到项目**

Run: `cp -r /tmp/elysiajs-skills-official/elysia /Users/martinadamsdev/elysiajs-skills/elysia && cp /tmp/elysiajs-skills-official/.gitignore /Users/martinadamsdev/elysiajs-skills/.gitignore && cp /tmp/elysiajs-skills-official/.prettierrc /Users/martinadamsdev/elysiajs-skills/.prettierrc`

**Step 3: 验证文件结构**

Run: `find /Users/martinadamsdev/elysiajs-skills/elysia -type f | wc -l`
Expected: ~40+ 文件

**Step 4: Commit**

```bash
cd /Users/martinadamsdev/elysiajs-skills
git add .
git commit -m "feat: import official elysiajs/skills as base"
```

---

### Task 2: 添加缺失的 patterns 文件 (7 个)

官方 skills 仅有 `patterns/mvc.md`，网站上有 7 个额外的 patterns 页面未被覆盖。

**Files:**
- Create: `elysia/patterns/configuration.md`
- Create: `elysia/patterns/extends-context.md`
- Create: `elysia/patterns/error-handling.md`
- Create: `elysia/patterns/trace.md`
- Create: `elysia/patterns/typebox.md`
- Create: `elysia/patterns/typescript.md`
- Create: `elysia/patterns/mount.md`

**Step 1: 获取并创建 configuration.md**

从 `https://elysiajs.com/patterns/configuration` 获取内容。
覆盖：Elysia 构造函数的 25+ 配置选项（prefix, name, aot, serve, adapter, TLS 等）。

**Step 2: 获取并创建 extends-context.md**

从 `https://elysiajs.com/patterns/extends-context` 获取内容。
覆盖：state, decorate, derive, resolve 四个核心 API，affix 函数。

**Step 3: 获取并创建 error-handling.md**

从 `https://elysiajs.com/patterns/error-handling` 获取内容。
覆盖：自定义验证消息、自定义错误类、type-safe 错误窄化、生产环境行为。

**Step 4: 获取并创建 trace.md**

从 `https://elysiajs.com/patterns/trace` 获取内容。
覆盖：`.trace()` 性能监控、生命周期事件注入、TraceEndDetail。

**Step 5: 获取并创建 typebox.md**

从 `https://elysiajs.com/patterns/typebox` 获取内容。
覆盖：TypeBox 完整类型参考、Elysia 特有类型（File, Cookie, Nullable, Form 等）。

**Step 6: 获取并创建 typescript.md**

从 `https://elysiajs.com/patterns/typescript` 获取内容。
覆盖：类型推断、schema-to-type 转换、TypeScript 性能优化。

**Step 7: 获取并创建 mount.md**

从 `https://elysiajs.com/patterns/mount` 获取内容。
覆盖：WinterTC 框架互操作、挂载 Hono/Next.js/Nuxt 等。

**Step 8: Commit**

```bash
git add elysia/patterns/
git commit -m "feat: add 7 missing patterns (configuration, extends-context, error-handling, trace, typebox, typescript, mount)"
```

---

### Task 3: 添加 Migration 指南 (4 个)

官方 skills 完全缺少迁移指南。网站有 4 个详细的迁移页面。

**Files:**
- Create: `elysia/migrations/from-express.md`
- Create: `elysia/migrations/from-fastify.md`
- Create: `elysia/migrations/from-hono.md`
- Create: `elysia/migrations/from-trpc.md`

**Step 1: 获取并创建 from-express.md**

从 `https://elysiajs.com/migrate/from-express` 获取内容。
覆盖：15+ 主题的 Express vs Elysia 对比（路由、处理器、验证、文件上传、中间件、类型安全等）。

**Step 2: 获取并创建 from-fastify.md**

从 `https://elysiajs.com/migrate/from-fastify` 获取内容。

**Step 3: 获取并创建 from-hono.md**

从 `https://elysiajs.com/migrate/from-hono` 获取内容。

**Step 4: 获取并创建 from-trpc.md**

从 `https://elysiajs.com/migrate/from-trpc` 获取内容。

**Step 5: Commit**

```bash
git add elysia/migrations/
git commit -m "feat: add migration guides (from-express, from-fastify, from-hono, from-trpc)"
```

---

### Task 4: 添加缺失的 Integration (Netlify)

**Files:**
- Create: `elysia/integrations/netlify.md`

**Step 1: 获取并创建 netlify.md**

从 `https://elysiajs.com/integrations/netlify` 获取内容。
覆盖：Netlify Edge Functions 配置、文件结构、本地开发。

**Step 2: Commit**

```bash
git add elysia/integrations/netlify.md
git commit -m "feat: add Netlify integration guide"
```

---

### Task 5: 从核心仓库源码提取洞察，增强 SKILL.md

分析 `elysiajs/elysia` 核心仓库和 `elysiajs/eden` 源码，提取官方 skills 中未充分覆盖的高级模式和最佳实践。

**Files:**
- Modify: `elysia/SKILL.md`

**Step 1: 分析 elysia 核心仓库**

用 `gh` CLI 查看核心仓库的关键源码文件：
- `src/index.ts` - 核心 Elysia 类
- `src/types.ts` - 类型系统
- `src/adapter/` - 适配器模式

提取：高级 API 模式、内部架构洞察、常见陷阱。

**Step 2: 分析 eden 仓库**

查看 `elysiajs/eden` 的核心实现，补充 Eden Treaty 的高级用法。

**Step 3: 更新 SKILL.md**

在 SKILL.md 中增强以下部分：
- 添加 "Advanced Patterns" 章节（基于源码分析）
- 更新 "Resources" 章节，列出新增的所有文件
- 添加 migrations/ 目录索引
- 添加新 patterns 文件索引

**Step 4: Commit**

```bash
git add elysia/SKILL.md
git commit -m "feat: enhance SKILL.md with source code insights and updated index"
```

---

### Task 6: 更新 metadata.json 并最终验证

**Files:**
- Modify: `elysia/metadata.json`

**Step 1: 更新 metadata.json**

更新版本号和日期：
```json
{
  "version": "2.0.0",
  "organization": "ElysiaJS (Enhanced)",
  "date": "29 Jan 2026",
  "abstract": "Enhanced ElysiaJS skills with comprehensive patterns, migration guides, and source code insights.",
  "references": ["https://elysiajs.com/llms.txt"]
}
```

**Step 2: 验证所有文件存在**

Run: `find /Users/martinadamsdev/elysiajs-skills/elysia -type f | sort`
Expected: 50+ 文件（原 40 + 新增 12）

**Step 3: 验证文件内容非空**

Run: `find /Users/martinadamsdev/elysiajs-skills/elysia -type f -empty`
Expected: 无输出（没有空文件）

**Step 4: Final Commit**

```bash
git add .
git commit -m "feat: finalize enhanced ElysiaJS skills v2.0.0"
```

---

## 最终交付物

```
elysiajs-skills/
├── .gitignore
├── .prettierrc
├── docs/plans/
│   └── 2026-01-29-elysia-skills.md (本计划)
└── elysia/
    ├── SKILL.md              (增强版主文件)
    ├── metadata.json         (更新版本)
    ├── examples/             (14 个示例，来自官方)
    │   ├── basic.ts
    │   ├── body-parser.ts
    │   ├── complex.ts
    │   ├── cookie.ts
    │   ├── error.ts
    │   ├── file.ts
    │   ├── guard.ts
    │   ├── map-response.ts
    │   ├── redirect.ts
    │   ├── rename.ts
    │   ├── schema.ts
    │   ├── state.ts
    │   ├── upload-file.ts
    │   └── websocket.ts
    ├── integrations/         (16 个，官方 15 + netlify)
    │   ├── ai-sdk.md
    │   ├── astro.md
    │   ├── better-auth.md
    │   ├── cloudflare-worker.md
    │   ├── deno.md
    │   ├── drizzle.md
    │   ├── expo.md
    │   ├── netlify.md        ← NEW
    │   ├── nextjs.md
    │   ├── nodejs.md
    │   ├── nuxt.md
    │   ├── prisma.md
    │   ├── react-email.md
    │   ├── sveltekit.md
    │   ├── tanstack-start.md
    │   └── vercel.md
    ├── migrations/           ← NEW (4 个迁移指南)
    │   ├── from-express.md
    │   ├── from-fastify.md
    │   ├── from-hono.md
    │   └── from-trpc.md
    ├── patterns/             (8 个，官方 1 + 新增 7)
    │   ├── configuration.md  ← NEW
    │   ├── error-handling.md ← NEW
    │   ├── extends-context.md← NEW
    │   ├── mount.md          ← NEW
    │   ├── mvc.md
    │   ├── trace.md          ← NEW
    │   ├── typebox.md        ← NEW
    │   └── typescript.md     ← NEW
    ├── plugins/              (11 个，来自官方)
    │   ├── bearer.md
    │   ├── cors.md
    │   ├── cron.md
    │   ├── graphql-apollo.md
    │   ├── graphql-yoga.md
    │   ├── html.md
    │   ├── jwt.md
    │   ├── openapi.md
    │   ├── opentelemetry.md
    │   ├── server-timing.md
    │   └── static.md
    └── references/           (11 个，来自官方)
        ├── bun-fullstack-dev-server.md
        ├── cookie.md
        ├── deployment.md
        ├── eden.md
        ├── lifecycle.md
        ├── macro.md
        ├── plugin.md
        ├── route.md
        ├── testing.md
        ├── validation.md
        └── websocket.md
```

**新增内容共 12 个文件：**
- 7 个 patterns（configuration, extends-context, error-handling, trace, typebox, typescript, mount）
- 4 个 migrations（from-express, from-fastify, from-hono, from-trpc）
- 1 个 integration（netlify）
- SKILL.md 增强（源码洞察 + 更新索引）
