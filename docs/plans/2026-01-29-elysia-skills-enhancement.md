# ElysiaJS Skills 增强计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 ElysiaJS skills 从 66 文件增强到 80+ 文件，补全 Eden 专题（9 文件）、缺失内容（3 文件）、改善薄弱文件质量、增加实战示例，并修复结构问题。

**Architecture:** 按优先级分 8 个 Task 执行。最大缺口是 Eden 专题（网站 10 页 vs 我们 1 文件），其次是现有文件质量提升和实战模式补充。所有内容从 elysiajs.com 页面提取并重写为 skills 格式。

**Tech Stack:** Markdown、TypeScript（示例文件）、Claude Code skills 格式

---

### Task 1: 创建 Eden 专题目录 (9 个新文件)

当前 `references/eden.md` 仅 158 行，覆盖面不足。网站有 10 个 Eden 页面，需要创建独立的 `eden/` 目录体系。

**Files:**
- Create: `elysia/eden/overview.md`
- Create: `elysia/eden/installation.md`
- Create: `elysia/eden/fetch.md`
- Create: `elysia/eden/treaty-overview.md`
- Create: `elysia/eden/treaty-parameters.md`
- Create: `elysia/eden/treaty-response.md`
- Create: `elysia/eden/treaty-websocket.md`
- Create: `elysia/eden/treaty-config.md`
- Create: `elysia/eden/treaty-unit-test.md`

**Step 1: 创建 eden/ 目录**

Run: `mkdir -p /Users/martinadamsdev/elysiajs-skills/elysia/eden`

**Step 2: 获取并创建 overview.md**

从 `https://elysiajs.com/eden/overview` 获取。
覆盖：Eden 生态概览、Treaty vs Fetch 区分、类型安全原理、安装方式。

**Step 3: 获取并创建 installation.md**

从 `https://elysiajs.com/eden/installation` 获取。
覆盖：安装命令、类型导出 pattern、条件导入。

**Step 4: 获取并创建 fetch.md**

从 `https://elysiajs.com/eden/fetch` 获取。
覆盖：Eden Fetch API（独立于 Treaty 的低级 API）、用法、配置、与 Treaty 的对比。

**Step 5: 获取并创建 treaty-overview.md**

从 `https://elysiajs.com/eden/treaty/overview` 获取。
覆盖：Treaty 初始化、树形语法、HTTP 方法映射、路径参数。

**Step 6: 获取并创建 treaty-parameters.md**

从 `https://elysiajs.com/eden/treaty/parameters` 获取。
覆盖：body、headers、query、fetch options 的详细用法。

**Step 7: 获取并创建 treaty-response.md**

从 `https://elysiajs.com/eden/treaty/response` 获取。
覆盖：data/error/status/headers 解构、类型窄化、Stream/SSE 响应。

**Step 8: 获取并创建 treaty-websocket.md**

从 `https://elysiajs.com/eden/treaty/websocket` 获取。
覆盖：WebSocket 连接、消息类型、事件监听。

**Step 9: 获取并创建 treaty-config.md**

从 `https://elysiajs.com/eden/treaty/config` 获取。
覆盖：base URL、custom headers、onRequest/onResponse hooks、custom fetch。

**Step 10: 获取并创建 treaty-unit-test.md**

从 `https://elysiajs.com/eden/treaty/unit-test` 获取。
覆盖：使用 Treaty 测试 Elysia 服务端、零网络开销测试模式。

**Step 11: Commit**

```bash
cd /Users/martinadamsdev/elysiajs-skills
git add elysia/eden/
git commit -m "feat: add comprehensive Eden documentation (9 files covering Treaty, Fetch, config, testing)"
```

---

### Task 2: 添加缺失内容文件 (3 个新文件)

**Files:**
- Create: `elysia/references/cheat-sheet.md`
- Create: `elysia/plugins/overview.md`
- Create: `elysia/patterns/standalone-schema.md`

**Step 1: 获取并创建 cheat-sheet.md**

从 `https://elysiajs.com/integrations/cheat-sheet` 获取。
覆盖：Elysia by example 速查表，所有核心 API 的简洁示例。

**Step 2: 获取并创建 plugins/overview.md**

从 `https://elysiajs.com/plugins/overview` 获取。
覆盖：插件系统总览、官方插件列表、社区插件发现方式。

**Step 3: 获取并创建 standalone-schema.md**

从 `https://elysiajs.com/tutorial/patterns/standalone-schema` 获取。
覆盖：独立 schema 定义模式、跨路由复用、schema 组合。

**Step 4: Commit**

```bash
git add elysia/references/cheat-sheet.md elysia/plugins/overview.md elysia/patterns/standalone-schema.md
git commit -m "feat: add cheat-sheet, plugin overview, and standalone-schema docs"
```

---

### Task 3: 增强 SKILL.md 薄弱章节

当前 SKILL.md (556 行) 有多个章节过于简略。

**Files:**
- Modify: `elysia/SKILL.md`

**Step 1: 扩展 Standard Schema 章节 (约 line 180)**

当前只有 Zod 示例。增加：
```typescript
// Valibot
import * as v from 'valibot'

.post('/user', ({ body }) => body, {
  body: v.object({
    name: v.string(),
    age: v.pipe(v.number(), v.minValue(0)),
    email: v.pipe(v.string(), v.email())
  })
})
```

**Step 2: 扩展 Macro 章节 (约 line 222)**

当前仅 10 行。增加实际场景示例：
- 认证 macro（JWT 验证 + 角色检查）
- 速率限制 macro
- 引用 `references/macro.md` 获取完整参考

**Step 3: 添加 Stream/SSE 章节**

在 Error Handling 之后添加：
```typescript
// Stream
.get('/stream', function* () {
  yield 'chunk 1'
  yield 'chunk 2'
})

// Server-Sent Events
.get('/sse', function* ({ set }) {
  set.headers['content-type'] = 'text/event-stream'
  while (true) {
    yield `data: ${JSON.stringify({ time: Date.now() })}\n\n`
    await Bun.sleep(1000)
  }
})
```

**Step 4: 添加 "Type Soundness" 概念**

在 Key Concept 章节末尾增加：解释 Elysia 如何推断所有可能的路由结果（成功 + 错误），以及 "Single Source of Truth"（一个 schema = 运行时验证 + 类型推断 + OpenAPI schema）。

**Step 5: 更新 Resources 章节**

添加新增的 `eden/` 目录索引、`cheat-sheet.md`、`plugins/overview.md`、`standalone-schema.md`。

**Step 6: Commit**

```bash
git add elysia/SKILL.md
git commit -m "feat: enhance SKILL.md with Standard Schema examples, Stream/SSE, macros, type soundness"
```

---

### Task 4: 提升薄弱文件质量

**Files:**
- Modify: `elysia/references/macro.md` (83 行 → 200+ 行)
- Modify: `elysia/patterns/typescript.md` (79 行 → 150+ 行)
- Modify: `elysia/patterns/mount.md` (64 行 → 120+ 行)
- Modify: `elysia/references/eden.md` (158 行 → 更新为索引文件)

**Step 1: 增强 macro.md**

从 `https://elysiajs.com/patterns/macro` 获取完整内容。增加：
- 属性简写（property shorthand）
- 错误处理模式
- Schema 组合
- 实际场景：认证 macro、RBAC macro、速率限制 macro
- 与 Guard 的对比

**Step 2: 增强 typescript.md**

从 `https://elysiajs.com/patterns/typescript` 补充。增加：
- 类型错误排查指南
- tsconfig 推荐配置
- 深层类型推断性能问题排查
- Eden 类型优化的更多策略

**Step 3: 增强 mount.md**

从 `https://elysiajs.com/patterns/mount` 补充。增加：
- 性能影响说明
- 限制和注意事项
- 实际使用场景
- 与 `.use()` 的区别

**Step 4: 更新 eden.md 为索引文件**

将 `references/eden.md` 改为简要概述 + 指向新 `eden/` 目录文件的索引。保留核心内容，添加指引。

**Step 5: Commit**

```bash
git add elysia/references/macro.md elysia/patterns/typescript.md elysia/patterns/mount.md elysia/references/eden.md
git commit -m "feat: enhance macro, typescript, mount docs and update eden index"
```

---

### Task 5: 添加实战示例文件

**Files:**
- Create: `elysia/examples/auth-jwt.ts`
- Create: `elysia/examples/streaming-sse.ts`
- Create: `elysia/examples/production-server.ts`
- Modify: `elysia/examples/basic.ts` (9 行 → 20+ 行)

**Step 1: 创建 auth-jwt.ts**

完整的 JWT 认证流程示例：
- 登录路由（验证凭据、生成 token）
- 受保护路由（验证 token、提取用户）
- 使用 macro 做认证守卫
- 角色检查

**Step 2: 创建 streaming-sse.ts**

Server-Sent Events 示例：
- 基础 Stream 响应
- SSE 实时推送
- 客户端连接管理

**Step 3: 创建 production-server.ts**

生产服务器示例：
- 健康检查端点
- 优雅关闭
- 请求日志
- CORS + Helmet 配置
- 错误处理中间件

**Step 4: 增强 basic.ts**

添加 `.listen()` 调用和基本注释，使其成为可运行的最小示例。

**Step 5: Commit**

```bash
git add elysia/examples/
git commit -m "feat: add auth-jwt, streaming-sse, production-server examples and enhance basic.ts"
```

---

### Task 6: 修复结构和元数据问题

**Files:**
- Modify: `elysia/metadata.json`
- Modify: `elysia/SKILL.md` (修复引用错误)

**Step 1: 完善 metadata.json**

```json
{
  "version": "3.0.0",
  "organization": "Sky Flux",
  "date": "29 Jan 2026",
  "abstract": "Comprehensive ElysiaJS skills with full Eden coverage, migration guides, patterns, and production examples.",
  "references": ["https://elysiajs.com/llms.txt"],
  "tags": ["elysiajs", "bun", "typescript", "backend", "api", "type-safe"],
  "elysiaVersion": ">=1.2"
}
```

**Step 2: 修复 SKILL.md 中的引用**

- 修复 `react-email.d` → `react-email.md`（Resources 章节 integrations 列表中的笔误）
- 确保所有 Resources 列表文件路径与实际文件一致

**Step 3: Commit**

```bash
git add elysia/metadata.json elysia/SKILL.md
git commit -m "fix: update metadata, fix broken references in SKILL.md"
```

---

### Task 7: 添加阅读指引到 SKILL.md

**Files:**
- Modify: `elysia/SKILL.md`

**Step 1: 在 Resources 章节顶部添加阅读优先级**

```markdown
## Resources

### Recommended Reading Order

**Tier 1 - 基础（必读）:**
1. `references/route.md` - 路由、Handler、Context
2. `references/validation.md` - 输入输出验证
3. `references/lifecycle.md` - 请求生命周期
4. `references/plugin.md` - 插件系统

**Tier 2 - 核心模式:**
5. `patterns/extends-context.md` - 上下文扩展 API
6. `patterns/error-handling.md` - 错误处理
7. `references/eden.md` - 端到端类型安全客户端
8. `patterns/mvc.md` - 项目架构

**Tier 3 - 进阶:**
9. `references/macro.md` - 可组合的 schema/lifecycle
10. `patterns/configuration.md` - 服务器配置
11. `patterns/trace.md` - 性能监控
12. `references/cheat-sheet.md` - 速查表
```

**Step 2: Commit**

```bash
git add elysia/SKILL.md
git commit -m "feat: add recommended reading order to SKILL.md resources"
```

---

### Task 8: 最终验证

**Files:**
- 无新文件

**Step 1: 验证总文件数**

Run: `find /Users/martinadamsdev/elysiajs-skills/elysia -type f | wc -l`
Expected: 80+ 文件

**Step 2: 验证无空文件**

Run: `find /Users/martinadamsdev/elysiajs-skills/elysia -type f -empty`
Expected: 无输出

**Step 3: 验证目录结构完整**

Run: `find /Users/martinadamsdev/elysiajs-skills/elysia -type d | sort`
Expected: eden/, examples/, integrations/, migrations/, patterns/, plugins/, references/

**Step 4: 统计总行数**

Run: `find /Users/martinadamsdev/elysiajs-skills/elysia -type f | xargs wc -l | tail -1`

**Step 5: Final commit**

```bash
git add .
git commit -m "feat: finalize ElysiaJS enhanced skills v3.0.0"
```

---

## 最终交付物预期

```
新增文件 (15 个):
├── eden/                     ← NEW 目录 (9 文件)
│   ├── overview.md
│   ├── installation.md
│   ├── fetch.md
│   ├── treaty-overview.md
│   ├── treaty-parameters.md
│   ├── treaty-response.md
│   ├── treaty-websocket.md
│   ├── treaty-config.md
│   └── treaty-unit-test.md
├── references/cheat-sheet.md  ← NEW
├── plugins/overview.md        ← NEW
├── patterns/standalone-schema.md ← NEW
├── examples/auth-jwt.ts       ← NEW
├── examples/streaming-sse.ts  ← NEW
└── examples/production-server.ts ← NEW

增强文件 (6 个):
├── SKILL.md                   (Standard Schema, Stream/SSE, Macro, Type Soundness, 阅读指引)
├── references/macro.md        (83 → 200+ 行)
├── patterns/typescript.md     (79 → 150+ 行)
├── patterns/mount.md          (64 → 120+ 行)
├── references/eden.md         (更新为索引文件)
├── examples/basic.ts          (9 → 20+ 行)
└── metadata.json              (完善字段)
```

**从 66 文件 → 81+ 文件，质量全面提升。**
