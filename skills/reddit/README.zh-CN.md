# Reddit Opportunity Hunter

[English](./README.md) | **中文**

从全球 Reddit 社区中发现 niche 产品机会 — 未被满足的痛点、寻求工具的用户、市场空白 — 聚焦高购买力市场（美国、英国、欧盟、德语区、北欧、日本、韩国、澳大利亚等）。

**核心思路：** 扫描发达国家 Reddit 社区 → 发现真实用户痛点 → 找到可以 1-2 周内做出 MVP 的产品机会 → 用 USD/EUR/GBP 定价，赚汇率差。

---

## 安装

```bash
npx skills add sky-flux/skills --skill reddit
```

全局安装（所有项目可用）：

```bash
npx skills add sky-flux/skills --skill reddit -g
```

## 依赖

```bash
brew install curl jq
```

- **curl** — 用于请求 Reddit API
- **jq** — 用于解析和富化 Reddit JSON 数据

## 快速开始

### 第一步：检查环境

```bash
reddit.sh diagnose
```

验证 curl、jq、网络连通性和配置文件。

### 第二步：配置偏好

```bash
reddit.sh config show                    # 查看当前配置
reddit.sh config set output_language zh  # 中文输出报告
reddit.sh config set currency_display CNY # 人民币显示收入
reddit.sh config set focus_industries '["SaaS","DevTools","AI"]'  # 聚焦行业
```

### 第三步：首次扫描

```bash
reddit.sh fetch --campaign global_english --sort new --pages 1
```

### 第四步：让 Claude 分析

直接告诉 Claude：

```
扫描 Reddit 寻找产品机会
```

或使用：

```
/reddit
```

Claude 会执行 4 阶段管线：采集 → 分析 → 验证 → 报告。

## 工作原理

### 4 阶段管线

```
阶段 1：数据采集
  reddit.sh 从配置的 subreddit 抓取帖子
  jq 过滤垃圾信息，富化元数据（意图关键词、情感、技术栈、地理位置）

阶段 2：分析（Claude 执行）
  跨帖子、跨社区聚类痛点
  对每个机会打分（1-10），使用加权公式
  从上下文判断意图等级（1-5）

阶段 3：深度验证（评分 >= 8）
  抓取评论树，看更深层讨论
  搜索竞品投诉
  跨平台验证（可选）

阶段 4：报告
  生成产品机会卡片（含构建评估）
  每日扫描报告 / 周报 / 月报
```

### 评分算法

每个机会打 1-10 分：

| 维度 | 权重 | 衡量什么 |
|------|------|---------|
| 痛点强度 | 20% | 意图等级（1-5）、情感分析 |
| 竞品空白 | 20% | 现有方案、用户投诉 |
| 构建可行性 | 20% | 能否 1-2 周做出 MVP？ |
| 市场价值 | 20% | Tier S/A/B 市场、付费信号 |
| 痛点频次 | 15% | 多少帖子提到这个痛点？ |
| 时效性 | 5% | 持续性痛点 > 一闪而过 |

**分数阈值：**
- **>= 8** — 深度验证 + 报告高亮
- **>= 7** — 出现在每日报告
- **< 7** — 仅出现在趋势痛点汇总

## 15 个模式

### 数据采集

| 模式 | 用法 | 用途 |
|------|------|------|
| `fetch` | `reddit.sh fetch --campaign X --sort new --pages 2` | 抓取并富化帖子 |
| `comments` | `reddit.sh comments <帖子ID> <subreddit>` | 抓取评论树（含嵌套回复） |
| `search` | `reddit.sh search "关键词" [--global] [--type post\|user\|subreddit]` | 全 Reddit 搜索 |
| `firehose` | `reddit.sh firehose [sub1+sub2]` | 实时评论流轮询 |
| `stickied` | `reddit.sh stickied [subreddit]` | 置顶帖及其评论挖掘 |

### 发现与分析

| 模式 | 用法 | 用途 |
|------|------|------|
| `discover` | `reddit.sh discover <关键词> [--deep\|--from-sub\|--industry\|--autocomplete\|--footprint]` | 发现新的高价值 subreddit |
| `profile` | `reddit.sh profile <用户名> [--enrich]` | 用户画像分析（活跃社区、发帖历史） |
| `crosspost` | `reddit.sh crosspost [--campaign X]` | 交叉发帖用户检测 |
| `duplicates` | `reddit.sh duplicates <帖子ID>` | 链接传播追踪 |
| `wiki` | `reddit.sh wiki <subreddit> [页面]` | 社区 Wiki 知识提取 |

### 管理

| 模式 | 用法 | 用途 |
|------|------|------|
| `config` | `reddit.sh config [show\|set <key> <val>\|reset]` | 用户偏好配置 |
| `stats` | `reddit.sh stats` | 数据库统计（已扫描帖子、机会、监控线程） |
| `export` | `reddit.sh export [--format csv\|json]` | 导出机会数据 |
| `cleanup` | `reddit.sh cleanup` | 清理过期数据（30天帖子、过期监控） |
| `diagnose` | `reddit.sh diagnose` | 环境健康检查（jq、curl、网络、配额） |

## 配置

### 用户偏好（`.reddit/config.json`）

```bash
reddit.sh config show                                # 查看所有设置
reddit.sh config set output_language zh              # 中文报告
reddit.sh config set focus_industries '["SaaS","AI"]' # 聚焦行业
reddit.sh config set excluded_subreddits '["Entrepreneur"]'  # 排除子版块
reddit.sh config set score_threshold 8               # 只看高分机会
reddit.sh config set max_build_complexity Medium      # 过滤复杂项目
reddit.sh config set currency_display CNY            # 人民币显示收入
reddit.sh config reset                               # 恢复默认
```

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `output_language` | `en` | 报告语言 — `en`、`zh`、`ja`、`de`、`fr`、`es`、`pt`、`ko` |
| `focus_industries` | `[]` | 关注的行业（空=全部） |
| `excluded_subreddits` | `[]` | 跳过的 subreddit |
| `score_threshold` | `7` | 最低报告评分 |
| `max_build_complexity` | `Heavy` | 最大复杂度：`Trivial` / `Light` / `Medium` / `Heavy` |
| `currency_display` | `USD` | 收入预估货币 — `USD`、`CNY`、`EUR`、`GBP`、`JPY` |

### 扫描 Campaign（`references/subreddits.json`）

17 个 campaign，按经济价值分层：

| 层级 | 扫描频率 | 市场 | Campaign 示例 |
|------|---------|------|--------------|
| **Tier S** | 每次循环 | 美国、英国、欧盟、德语区、北欧、日本、澳大利亚 | `global_english`、`dach`、`france`、`east_asia` |
| **Tier A** | 每天 | 印度、巴西、东南亚、拉美、东欧 | `india`、`brazil`、`southeast_asia` |
| **Tier B** | 每周 | 非洲、南亚、土耳其 | `africa`、`south_asia`、`turkey` |

### 意图关键词（`references/intent_keywords.json`）

9 种语言（EN、DE、FR、PT、ES、JA、KO、AR、FI），5 个意图等级：

| 等级 | 信号 | 示例 |
|------|------|------|
| 1 | 直接购买意向 | "willing to pay"、"take my money"、"budget for" |
| 2 | 主动寻找方案 | "looking for a tool"、"switching from"、"need alternative" |
| 3 | 痛点表达 | "frustrated with"、"too expensive"、"spent hours trying" |
| 4 | 调研 | "what do you use for"、"best practices"、"evaluating" |
| 5 | 间接信号 | 领域讨论中暗含的未满足需求 |

## 输出

所有数据保存在项目根目录的 `.reddit/`：

```
.reddit/
├── config.json              # 用户配置
├── .reddit.json             # 状态文件（去重、监控、机会追踪）
├── 2026-03-15-scan.md       # 每日扫描报告
├── reports/
│   ├── 2026-W11-weekly.md   # 周报
│   └── 2026-03-monthly.md   # 月报
├── opportunities/
│   └── soc2-compliance-tool.md  # 产品机会卡片
└── archive/                 # 历史报告
```

### 产品机会卡片内容

每个高分机会生成详细卡片：

- **痛点** — 具体问题描述、来源帖子
- **市场证据** — 出现频次、强度、地理分布、预算信号
- **竞品格局** — 现有方案、为何不满意、市场空白
- **构建评估** — 复杂度、MVP 范围、构建时间、Solo Dev 适配度
- **收入模型** — 定价锚点、建议定价（USD/EUR/PPP）、分发渠道、CAC
- **跨市场信号** — 哪些市场有同样痛点

## 定时扫描

在 Claude Code 中使用 `/loop` 命令自动定时扫描：

```bash
/loop 30m /reddit          # 每 30 分钟扫描一次（推荐）
/loop 15m /reddit          # 更频繁 — 适合抓时效性机会
/loop 1h /reddit           # 每小时 — 更省 API 配额
```

周报：每周日自动生成
月报：每月最后一天自动生成

### 使用技巧

```bash
# 单次扫描（不循环）
/reddit

# 只扫描特定 campaign
reddit.sh fetch --campaign dach --sort new --pages 2

# 监控某个热帖的新评论
reddit.sh comments <帖子ID> <subreddit>

# 发现新的高价值 subreddit
reddit.sh discover "你的行业关键词"

# 查看 API 剩余配额
reddit.sh diagnose

# 深入分析某个高价值用户
reddit.sh profile 用户名 --enrich

# 导出所有机会为 CSV
reddit.sh export --format csv

# 清理过期数据（建议每月执行）
reddit.sh cleanup
```

## 速率限制

Reddit 未认证 API 配额：100 请求 / ~260 秒。

脚本自动处理：
- 请求间隔 3 秒
- 读取 `x-ratelimit-remaining` 响应头
- 429 时自动等待重试
- 多 subreddit 合并请求（`r/A+B+C/new.json`）减少总请求数
- 单次 Tier S 扫描约消耗 40-45 / 100 配额

## 安全说明

- 仅采集公开数据（Reddit 公开 JSON API）
- 不存储 PII（仅 Reddit 用户名和公开内容）
- `.reddit/` 目录应加入 `.gitignore`（脚本会自动提醒）
- 回复草稿标注 `[REVIEW BEFORE POSTING]`，不自动发送
- 建议每天不超过 5 条社区回复
- 遵守 Reddit 速率限制
