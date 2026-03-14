# Reddit Opportunity Hunter — Design Spec

## Core Mission

从发达国家 Reddit 社区中挖掘真实的 niche 痛点和未被满足的需求，发现可快速实现的产品机会，赚汇率差。

**核心定位：Product Opportunity Hunting，不是 Lead Hunting。**

- 输入：Reddit 上的真实用户讨论
- 输出：可执行的产品机会报告（痛点、市场规模、竞品空白、定价锚点、构建难度）
- 目标：找到能在 1-2 周内做出 MVP、用 USD/EUR/GBP 定价的 niche 产品机会

---

## Architecture

```
skills/reddit/
├── SKILL.md                        # 主指令：编排整个流程
├── metadata.json                   # 版本、标签
├── README.md
├── scripts/
│   └── reddit.sh                   # curl+jq 数据抓取脚本（14 个模式）
└── references/
    ├── subreddits.json             # 全球 subreddit 配置（按经济价值分层）
    ├── intent_keywords.json        # 多语言意图关键词库
    ├── market_keywords.json        # 各国商业/合规术语
    └── seasonal_patterns.json      # 季节性模式
```

**用户项目中的输出目录：**

```
.reddit-leads/
├── .reddit.json                    # 状态文件（去重、监控、线索生命周期）
├── 2026-03-15-scan.md              # 每日扫描报告
├── reports/
│   ├── 2026-W11-weekly.md          # 周报
│   └── 2026-03-monthly.md          # 月报
├── opportunities/
│   └── soc2-compliance-tool.md     # 单个产品机会详细分析
└── archive/                        # 历史报告
```

---

## reddit.sh — 14 个模式

脚本是纯 bash + curl + jq，浏览器 UA 伪装，内置 rate limiting（读取 `x-ratelimit-remaining` header，低于 10 自动等待）。

| # | 模式 | 命令 | 用途 |
|---|------|------|------|
| 1 | **fetch** | `reddit.sh fetch [--sort new\|hot\|rising\|top\|controversial] [--pages N] [--campaign X]` | 抓取 subreddit 帖子列表 |
| 2 | **comments** | `reddit.sh comments <post_id> <subreddit>` | 抓取帖子评论树（含嵌套回复） |
| 3 | **profile** | `reddit.sh profile <username> [--enrich]` | 用户画像（overview + 发帖 + 评论历史） |
| 4 | **discover** | `reddit.sh discover <keyword> [--method keyword\|autocomplete\|footprint\|overlap]` | 发现新 subreddit |
| 5 | **search** | `reddit.sh search <query> [--type post\|user\|subreddit] [--global] [--subreddit X]` | 全 Reddit 或指定 subreddit 内搜索（注：评论搜索不可用，用 firehose 替代） |
| 6 | **crosspost** | `reddit.sh crosspost [--campaign X]` | 交叉发帖用户检测 |
| 7 | **stickied** | `reddit.sh stickied [subreddit]` | 置顶/周期帖评论挖掘 |
| 8 | **firehose** | `reddit.sh firehose [subreddits]` | 实时评论流监控 |
| 9 | **export** | `reddit.sh export [--format csv\|json]` | CRM 导出 |
| 10 | **cleanup** | `reddit.sh cleanup` | 过期数据清理 |
| 11 | **diagnose** | `reddit.sh diagnose` | 环境检查和错误诊断 |
| 12 | **duplicates** | `reddit.sh duplicates <post_id>` | 链接传播追踪 |
| 13 | **wiki** | `reddit.sh wiki <subreddit> [page]` | 社区 wiki 知识库挖掘 |
| 14 | **stats** | `reddit.sh stats` | 数据库统计 |

### Rate Limiting

Reddit 未认证 API 配额：100 请求 / ~260 秒。

- 请求间隔默认 `sleep 3`
- 读取 `x-ratelimit-remaining`，低于 10 时等待 `x-ratelimit-reset` 秒
- 多 subreddit 合并请求（`r/A+B+C/new.json`）减少总请求数
- HTTP 429 → 读取 `Retry-After`，等待后重试
- HTTP 403 → 切换 UA，重试一次
- HTTP 5xx → 跳过，记录错误，继续下一个

### 浏览器 UA 伪装

```bash
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
```

---

## Reddit API 端点清单（24 个已验证可用）

所有端点均已通过浏览器 UA 伪装实测验证。`limit` 参数最大值为 100（超过会静默截断）。

| # | 端点 | 用途 | 备注 |
|---|------|------|------|
| 1 | `/r/{sub}/new.json` | 最新帖子 | ✅ |
| 2 | `/r/{sub}/hot.json` | 热门帖子（stickied 在最前） | ✅ |
| 3 | `/r/{sub}/rising.json` | 上升帖子 | ✅ |
| 4 | `/r/{sub}/top.json?t=day\|week\|month\|all` | 顶部帖子 | ✅ |
| 5 | `/r/{sub}/controversial.json?t=day\|week\|month\|all` | 争议帖 | ✅ |
| 6 | `/r/{sub}/search.json?q=X&restrict_sr=on&sort=new&t=week` | 子版块内搜索 | ✅ sort: new/top/relevance/comments |
| 7 | `/r/{sub}/comments/{id}.json?limit=N&depth=N` | 帖子+评论树 | ✅ 返回 2 元素数组 [post, comments] |
| 8 | `/r/{sub}/comments.json` | 评论流（firehose） | ✅ 每条含 link_title/link_permalink |
| 9 | `/r/{sub}/about.json` | 子版块元数据 | ✅ 含 subreddit_type, wiki_enabled |
| 10 | `/r/{sub}/about/rules.json` | 子版块规则 | ✅ |
| 11 | `/r/{sub}/wiki/pages.json` | Wiki 页面列表 | ⚠️ 需先检查 about.json 的 wiki_enabled |
| 12 | `/r/{sub}/wiki/{page}.json` | Wiki 页面内容 | ⚠️ 同上 |
| 13 | `/r/A+B+C/new.json` | 多版块合并请求（8+ 已验证） | ✅ |
| 14 | `/search.json?q=X&sort=new&t=week` | 全 Reddit 搜索（帖子） | ✅ sort: new/top/relevance/comments |
| 15 | `/search.json?q=X&type=user` | 全 Reddit 搜索（用户） | ✅ |
| 16 | `/search.json?q=X&type=sr` | 全 Reddit 搜索（subreddit） | ✅ |
| 17 | `/subreddits/search.json?q=X` | Subreddit 搜索（同 #16） | ✅ 可与 #16 合并 |
| 18 | `/subreddits/new.json` | 新建 subreddit | ✅ |
| 19 | `/api/subreddit_autocomplete_v2.json?query=X` | Subreddit 自动补全 | ✅ |
| 20 | `/duplicates/{id}.json` | 同一链接的其他提交 | ✅ 仅对 link post 有意义 |
| 21 | `/user/{name}/about.json` | 用户 profile | ✅ 404 = 已删除/suspended |
| 22 | `/user/{name}/overview.json` | 用户混合时间线 | ✅ |
| 23 | `/user/{name}/submitted.json` | 用户发帖历史 | ✅ |
| 24 | `/user/{name}/comments.json` | 用户评论历史 | ✅ body 文本完整 |

**已排除的端点：**
- ~~`/r/{sub}/about/moderators.json`~~ — 需要认证（403），移除
- ~~`/search.json?q=X&type=comment`~~ — **未认证 API 不返回评论内容**（body 为 null），移除。评论搜索改用 firehose 端点 (#8) + jq 过滤

**重要技术细节：**
- 评论的 `replies` 字段不一致：有回复时是 object，无回复时是空字符串 `""`（不是 null）
- 每条帖子自带 `subreddit_subscribers` 字段，无需额外调用 about.json 获取订阅数
- `removed_by_category` 非 null 表示帖子已被删除，用于过滤
- `num_crossposts` 字段可用于病毒传播检测

---

## 核心流程：Product Opportunity Hunting

### Phase 1: 数据采集

```
reddit.sh fetch --campaign global_english --sort new --pages 2
reddit.sh fetch --campaign dach --sort new
reddit.sh fetch --campaign france --sort new
... (按 scan_priority 配置)
```

jq 初筛：
- 过滤 spam/bot（随机用户名正则、空 selftext、新号低 karma）
- 提取关键字段：title, selftext, author, score, num_comments, permalink, link_flair_text, created_utc, upvote_ratio
- 标记帖子类型：question（标题含 `?` 或疑问词）、pain（负面情绪词）、request（意图关键词）
- 标记时间窗口：URGENT(<1h) / HOT(1-4h) / WARM(4-24h) / COOL(24-72h)

### Phase 2: 痛点聚合与产品机会识别

Claude 分析初筛结果，核心任务：

1. **痛点聚类** — 跨帖子、跨 subreddit 识别同一主题的讨论
2. **频次统计** — 同一痛点本周出现了几次？在几个不同社区？
3. **强度评估** — 用户只是随口提到，还是真的很痛苦（情感分析 + 意图分级）
4. **市场验证信号提取**：
   - 已有解决方案？用户在骂什么？（竞品空白）
   - 有人提到愿意付费？金额？（定价锚点）
   - 团队规模、公司阶段？（客户画像）
   - 哪些工具已经被试过并否决了？（"already tried" 列表）

### Phase 3: 深度验证（对高分机会）

对 Claude 评分 ≥ 8 的产品机会：

1. **抓取评论树** — `reddit.sh comments` 看更深层讨论
2. **竞品搜索** — `reddit.sh search "[competitor] alternative" --global` 验证竞品不满
3. **Thread 监控** — 加入 watched_threads，持续关注后续讨论
4. **跨平台验证（可选）** — WebSearch 搜索竞品定价、功能对比

### Phase 4: 产品机会报告

输出到 `.reddit-leads/opportunities/` 目录：

```markdown
## 🎯 Product Opportunity: [Name]

### Pain Point
[具体描述这个痛点是什么，来自哪些帖子]

### Market Evidence
- **Frequency**: X posts in Y subreddits this week
- **Intensity**: [desperate/frustrated/exploring]
- **Geography**: [US/UK/EU/...] — [currency opportunity]
- **Target user**: [who exactly has this problem]
- **Budget signals**: [any pricing mentions]

### Competitive Landscape
- **Existing paid solutions**: [list with pricing]
- **Open-source alternatives**: [list with GitHub stars, activity]
- **Why they fail**: [specific complaints from Reddit]
- **Gap**: [what's missing that you could build]
- **Recent launches**: [any Product Hunt / HN launches in last 6 months]

### Build Assessment
- **Complexity**: [Trivial / Light / Medium / Heavy / Disqualified]
- **MVP scope**: [what's the minimum to validate]
- **Estimated build time**: [2-3 days / 1 week / 2 weeks / 1+ month]
- **Tech stack suggestion**: [based on the problem]
- **Technical moat**: [can someone clone this in a weekend? What protects you?]
- **Solo Dev fit**: [✅/❌ for each dimension — see Solo Dev 适配评分]

### Revenue Model
- **Pricing anchor**: [what competitors charge]
- **Suggested pricing tiers**:
  - Global USD: $X/mo (Tier S English markets)
  - EUR/GBP localized: €X/mo (European markets, potentially +10-20%)
  - PPP-adjusted: $Y/mo (Tier A/B markets, 40-60% of USD price)
- **Distribution channel**: [SEO? marketplace? community? How will customers find this?]
- **Retention model**: [subscription / one-time / usage-based]
- **Market size estimate**: [based on Reddit signal frequency]
- **Revenue potential**: $X/mo × Y customers = $Z/mo (¥W/mo)
- **CAC estimate**: [rough acquisition cost — Reddit replies, SEO, paid?]
- **Payback period**: [months of subscription to recover build time investment]
- **Churn risk**: [one-time problem or ongoing need?]

### Cross-Market Signal
- **Markets with this pain**: [list of countries/regions]
- **Localization effort**: [just translation? or functional differences?]
- **Cross-market multiplier applied**: [yes/no, bonus points]

### Source Posts
- [Post 1 title](permalink) — r/subreddit, X comments, Y score
- [Post 2 title](permalink) — r/subreddit, X comments, Y score
```

---

## 意图信号分级

### Tier 1 — 直接购买意向（最高价值）

```
willing to pay, budget for, what's the pricing, free trial,
need this ASAP, urgent, deadline, where do I sign up, take my money
```

### Tier 2 — 主动寻找解决方案

```
looking for a tool, anyone know, recommend a, help me find,
switching from X, need alternative, X vs Y
```

### Tier 3 — 痛点表达

```
frustrated with, struggling with, doesn't support, too expensive,
broken, can't figure out, spent hours trying
```

### Tier 4 — 讨论和调研

```
what do you use for, how do you handle, best practices for,
thinking about, considering, evaluating
```

### Tier 5 — 间接信号

```
某领域的问题讨论（没直接要工具，但暗含需求）
AMA 里的提问
```

---

## Opportunity 打分算法

Claude 对每个产品机会打 1-10 分：

| 维度 | 权重 | 评分依据 |
|------|------|---------|
| **痛点强度** | 20% | Tier 1-5 意图级别，情感词分析 |
| **竞品空白** | 20% | 现有方案数量、用户不满程度、开源替代品 |
| **构建可行性** | 20% | 复杂度分级（见下），能否 1-2 周 MVP |
| **市场价值** | 20% | 目标地区乘数（Tier S 2.0x / Tier A 1.5x / Tier B 0.8x），付费信号 |
| **痛点频次** | 15% | 本周出现次数，跨几个社区（注意：高频次可能意味着竞品多） |
| **时效性** | 5% | 对构建策略，持续性痛点比闪现痛点更有价值 |

### 评分公式（精确定义）

```
Step 1: 计算原始加权分 (1-10)
  raw_score = intensity*0.20 + competitive_gap*0.20 + build_feasibility*0.20
            + market_value*0.20 + frequency*0.15 + timeliness*0.05

Step 2: 应用加成/惩罚 (在原始分上加减，不乘)
  adjusted = raw_score
  + cross_market_bonus     (同一痛点 3+ Tier S 市场 → +1.5)
  + seasonal_bonus          (与 4-6 周内季节性高峰吻合 → +1.0；刚过 → -1.0)
  - false_positive_penalty  (见假阳性过滤表，-2 到 -3)

Step 3: 钳位到 1-10
  final_score = clamp(adjusted, 1, 10)

Step 4: 分数衰减（仅用于已有机会的后续扫描）
  if 本周无新提及: final_score *= 0.88 (每周衰减 12%)
```

**市场乘数不作用于 final_score，而是作用于 market_value 维度的评分：**
- Tier S 国家的帖子：market_value 维度基础分 +3（在 1-10 范围内）
- Tier A 国家的帖子：market_value 维度基础分 +1
- Tier B 国家的帖子：market_value 维度基础分 +0

**阈值检查使用 final_score：**
- `final_score >= 8` → 进入 Phase 3 深度验证 + 报告中高亮
- `final_score >= 7` → 出现在每日报告的 New Opportunities 列表
- `final_score < 7` → 仅出现在 Trending Pain Points 聚合中

### 构建复杂度分级

| 级别 | 时间 | 特征 | 示例 |
|------|------|------|------|
| **Trivial** | 2-3 天 | 静态站 + Stripe + 邮件，无后端逻辑 | 落地页+waitlist、计算器工具 |
| **Light** | 1 周 | 单 API 集成、基本 CRUD、auth | Chrome 扩展、简单 dashboard、连接器 |
| **Medium** | 2 周 | 多集成、用户账户、数据处理管线 | 报告工具、工作流自动化 |
| **Heavy** | 1+ 月 | 实时功能、复杂权限、合规要求、ML/AI | 协作工具、合规平台 |
| **Disqualified** | — | 需要受监管数据处理、硬件集成、网络效应 | 直接排除 |

Heavy 和 Disqualified 级别的机会自动降分或排除。

### 假阳性过滤

Reddit 痛点的噪声比高。以下情况自动标记为低价值或排除：

| 信号 | 处理 |
|------|------|
| 单一用户提及，无其他人佐证 | 降分 -3 |
| 发帖者零历史参与该话题（一次性吐槽） | 降分 -2 |
| 需要 B2B 企业销售流程（"procurement"、"vendor approval"、"IT department"） | 标记"非 solo dev 适合" |
| 痛点是平台特定的，平台自身可在更新中修复 | 排除 |
| 合规要求因管辖区而异（build once, maintain forever） | 标记为 Heavy |
| 已有强开源替代品（GitHub stars > 5k 且活跃维护） | 降分 -2 |

### Solo Dev 适配评分（独立于机会评分）

即使机会真实，也要评估是否适合一个人做：

| 维度 | ✅ 适合 | ❌ 不适合 |
|------|---------|----------|
| 构建时间 | < 2 周 MVP | > 1 月 |
| 合规负担 | 无持续合规 | 需要持续合规维护 |
| 分发渠道 | 可自助发现（SEO、marketplace、社区） | 需要 sales call |
| 收入模式 | 订阅制（recurring） | 一次性购买 |
| 技术栈 | 你已掌握的 | 需要学习新领域 |
| 网络效应 | 不需要（第 1 个客户就能用） | 需要临界量 |

### 微验证阶段（Phase 3.5）

在投入构建之前增加轻量验证步骤：

1. 在相关 subreddit 发一个真诚提问（不推产品），验证问题共鸣度
2. 搭建 landing page + 邮件注册（2 小时），测试转化
3. 在 Twitter/X 和 Hacker News 搜索同一痛点，Reddit 外佐证
4. 搜索是否有人做过并失败了（失败产品和缺席产品一样有信息量）

---

## 全球 Subreddit 配置（按经济价值分层）

### Tier S — 高购买力发达国家（最高优先级，赚汇率差）

**英语通用社区（美国为主）：**
SaaS (620k), startups (2M), Entrepreneur (5.1M), smallbusiness (2.4M), SideProject (651k), microsaas (169k), indiehackers (156k), buildinpublic (69k), growmybusiness (90k), NoCodeSaaS (39k), SaasDevelopers (24k), SaaSSales (28k), SaaSMarketing (25k), saasbuild (17k)

**英语发达国家：**
unitedkingdom (5.4M), BusinessBritain (2.6k), canada (4.3M), canadianbusiness (5.1k), australia (2.8M), newzealand (836k), nz_sme (326), ireland (1.25M)

**DACH（德语区）：**
StartupDACH (14.9k), de (3.17M), Switzerland (584k), Austria (655k)

**法国：**
FrenchTech (3.9k), entrepreneurfrance (1.3k), france (2.54M)

**北欧：**
sweden (1.02M), Norway (574k), Denmark (847k), Finland (298k), Suomi (635k), Iceland (100k)

**荷比卢+南欧：**
Netherlands (479k), belgium (391k), italy (1.12M), spain (1.05M), portugal (767k), greece (270k)

**东亚发达经济体：**
japan (1.77M), JapanBusiness (552), korea (1.40M), taiwan (756k), HongKong (700k), smeSingapore (2.2k)

**中东高购买力：**
dubai (527k), UAE (268k), BusinessownersUAE (654)

**扫描频率：** 每次 `/loop` 都扫。

### Tier A — 高增长经济体（乘数 1.5x）

**印度：** IndianEntrepreneur (25.4k), StartUpIndia (404k), india (3.40M)
**巴西：** empreendedorismo (133k), brasil (3.29M)
**东南亚：** Philippines (3.54M), PhStartups (26.5k), indonesia (944k), VietNam (1.48M), Thailand (926k), StartupsThailand (780), malaysia (1.32M)
**拉美西语：** mexico (3.16M), argentina (1.51M), Colombia (931k), chile (895k), startupsmexico (152)
**东欧：** poland (1.17M), Romania (1.12M), ukraine (937k), hungary (689k), croatia (428k), serbia (460k)
**中东成长型：** saudiarabia (185k)
**波罗的海数字经济：** estonia (3.8k), latvia (77k), lithuania (134k)

**扫描频率：** 每天一次。

### Tier B — 信息化发展中经济体（乘数 0.8x）

**非洲：** Kenya (272k), KenyaStartups (4.1k), Nigeria (236k), southafrica (395k), Egypt (350k), Morocco (394k), ghana (110k), Rwanda (23k), Ethiopia (54k)
**中国海外：** China (643k), China_irl (403k)
**南亚：** pakistan (657k), bangladesh (97k), srilanka (162k)
**中亚：** Kazakhstan (64k), Uzbekistan (24k)
**土耳其：** Turkey (1.70M)（注：TRY 货币不稳定，除非目标客户以 USD/EUR 定价，否则汇率差为负）

**扫描频率：** 每周一次。

---

## 多语言关键词库

### 德语 (DE)

```
痛点: frustriert, Problem mit, Alternative zu, zu teuer, suche Tool
意图: wer kennt, Empfehlung für, welches Tool, Erfahrungen mit
商业: Gründung, Startup, Mittelstand, GmbH, Existenzgründung, Digitalisierung
合规: Datenschutz, DSGVO, Bürokratie, GoBD
```

### 法语 (FR)

```
痛点: frustré, problème avec, alternative à, trop cher, cherche outil
意图: qui connaît, recommandation, quel outil, retour d'expérience
商业: création entreprise, startup, French Tech, BPI, SARL/SAS
合规: RGPD, charges sociales, comptabilité
```

### 葡萄牙语 (PT)

```
痛点: frustrado, problema com, alternativa para, caro demais, preciso de ferramenta
意图: alguém conhece, recomendação, qual ferramenta, experiência com
商业: startup, empreendedor, faturamento, negócio
```

### 西班牙语 (ES)

```
痛点: frustrado, problema con, alternativa a, demasiado caro, busco herramienta
意图: alguien conoce, recomendación, qué herramienta, experiencia con
商业: emprendedor, startup, negocio, empresa
```

### 日语 (JA)

```
痛点: 困っている, 代替, 高すぎる, ツール探し
意图: おすすめ, 使っている人, 比較, 経験
商业: スタートアップ, 起業, ベンチャー, SaaS
合规: 個人情報保護, 電子帳簿保存法
```

### 韩语 (KO)

```
痛点: 문제, 대안, 너무 비싼, 도구 찾기
意图: 추천, 사용해본, 비교, 경험
```

### 阿拉伯语 (AR)

```
痛点: مشكلة, بديل, غالي, أداة
意图: توصية, تجربة, مقارنة
```

### 芬兰语 (FI)

```
痛点: ongelma, vaihtoehto, liian kallis, työkalu
意图: suositus, kokemus, vertailu
```

---

## seasonal_patterns.json Schema

```json
{
  "patterns": [
    {
      "name": "US tax season",
      "regions": ["US"],
      "start_month": 1, "end_month": 4,
      "keywords": ["tax", "accounting", "bookkeeping", "CPA", "filing"],
      "note": "Businesses seeking tax/accounting tools"
    },
    {
      "name": "Q4 budget spend",
      "regions": ["US", "UK", "EU"],
      "start_month": 10, "end_month": 11,
      "keywords": ["budget", "procurement", "annual plan", "renew"],
      "note": "Use-it-or-lose-it budget → higher purchase willingness"
    },
    {
      "name": "New Year planning",
      "regions": ["global"],
      "start_month": 12, "end_month": 1,
      "keywords": ["2027 tools", "new year", "planning", "goals", "resolution"],
      "note": "New tools evaluation cycle"
    },
    {
      "name": "Back to school",
      "regions": ["US", "UK", "AU"],
      "start_month": 8, "end_month": 9,
      "keywords": ["education", "student", "school", "LMS", "learning"],
      "note": "EdTech demand spike"
    },
    {
      "name": "GDPR/privacy awareness",
      "regions": ["EU", "UK"],
      "start_month": 5, "end_month": 6,
      "keywords": ["GDPR", "privacy", "compliance", "data protection"],
      "note": "Annual GDPR enforcement reports trigger tool searches"
    }
  ]
}
```

Claude 在 Phase 2 评分时检查当前日期是否在某个 pattern 的窗口内（或未来 4-6 周内进入窗口）。如果痛点关键词与 pattern 关键词重叠 → 应用 Step 2 的 seasonal_bonus (+1.0)。

---

## 数据采集增强

### Spam/Bot 过滤（jq 层）

```jq
# 随机生成用户名（Reddit 自动分配的格式）
.author | test("^[A-Z][a-z]+-[A-Z][a-z]+[0-9]+$")

# 空 self post（标题党，无实质内容）
(.is_self == true and .selftext == "")

# 已删除/移除的帖子
(.author == "[deleted]" or .selftext == "[removed]" or .removed_by_category != null)

# 帖子 score 为负（社区已否决）
(.score < 0)
```

注意：`link_karma` / `comment_karma` 字段**不存在于帖子列表**中，只存在于 `/user/{name}/about.json`。如需按 karma 过滤，需要对可疑用户单独调用 profile 端点（消耗额外请求配额）。

### 提问帖检测（jq 层）

```jq
.title | test("\\?$|^How |^What |^Why |^Where |^Which |^Has anyone|^Does anyone|^Anyone |^Is there|^Can you|^Should I"; "i")
```

### 负面情绪提取（jq 层）

```jq
[.selftext | scan("(?i)(frustrat|disappoint|terrible|awful|waste of|regret|mistake|fail|broke|crash|bug|lost|scam|ripoff|overcharg)\\w*")] | flatten | unique
```

### 技术栈检测（jq 层）

```jq
[.selftext | scan("(?i)(react|next\\.?js|vue|angular|node|python|django|rails|stripe|aws|vercel|supabase|firebase|postgres|mongo|redis|docker|kubernetes|tailwind|typescript|graphql|prisma|drizzle)")] | flatten | unique
```

### 公司阶段信号（jq 层）

```jq
# MRR/ARR 金额
[.selftext | scan("(?i)\\$[0-9,]+k?\\s*(mrr|arr|revenue|/month|per month)")] | flatten

# 团队规模
[.selftext | scan("(?i)(solo|[0-9]+ (person|people|employee|team))")] | flatten
```

### 地理信号（jq 层）

```jq
[.selftext | scan("(?i)(US|UK|Europe|India|Australia|Canada|Germany|France|Brazil|Asia|LATAM|APAC|EMEA)")] | flatten | unique
```

---

## "求推荐"帖结构化解析

Claude 对 Tier 1-2 意图的帖子提取：

```json
{
  "need": "项目管理工具",
  "must_have": ["看板视图", "Slack集成", "< $20/月"],
  "nice_to_have": ["API", "自托管"],
  "already_tried": ["Notion", "Trello"],
  "why_rejected": {"Notion": "太复杂", "Trello": "功能太少"},
  "team_size": "5人",
  "budget": "$20/月/人",
  "geography": "US",
  "urgency_timeline": "by end of quarter",
  "decision_maker": true,
  "company_stage": "Series A, 15 people"
}
```

多个这样的结构化数据聚合后 → 产品需求画像。

---

## 竞品监控

`subreddits.json` 的 `competitors` 字段：

```json
{
  "competitors": ["Notion", "Airtable", "Monday.com"],
  "competitor_queries": [
    "{competitor} alternative",
    "{competitor} frustrated",
    "switching from {competitor}",
    "{competitor} vs",
    "{competitor} too expensive"
  ]
}
```

竞品搜索用全局搜索（不限 subreddit），因为竞品讨论出现在任何社区。

---

## Thread 监控

对高价值帖子持续追踪新评论：

```json
// .reddit.json
{
  "watched_threads": {
    "post_id": {
      "subreddit": "SaaS",
      "title": "...",
      "opportunity": "soc2-compliance-tool",
      "last_comment_count": 12,
      "last_checked": 1710500000,
      "watch_until": 1711100000
    }
  }
}
```

默认监控 7 天。每次 `/loop` 检查 comment count 变化。

---

## 去重与状态管理

`.reddit.json` 结构：

```json
{
  "seen_posts": {"post_id": timestamp, ...},
  "watched_threads": {...},
  "opportunities": {
    "soc2-compliance-tool": {
      "score": 9,
      "first_seen": "2026-03-15",
      "status": "investigating",
      "source_posts": ["id1", "id2"],
      "pain_frequency": 7,
      "actions": [
        {"date": "2026-03-15", "type": "discovered"},
        {"date": "2026-03-16", "type": "deep_dive"}
      ]
    }
  },
  "products_seen": {
    "proofzify.com": {
      "first_seen": "2026-03-15",
      "mention_count": 3,
      "context": "施工完成证明工具"
    }
  },
  "influencers": {
    "u/username": {
      "total_comment_score": 312,
      "seen_in": ["r/SaaS", "r/startups"],
      "expertise": "SaaS operations"
    }
  },
  "community_overlap": {
    "r/SaaS+r/microsaas": 23,
    "r/SaaS+r/SideProject": 18,
    "r/startups+r/Entrepreneur": 12
  }
}
```

`community_overlap` 由 `crosspost` 模式在检测交叉发帖时自动更新。键是两个 subreddit 名用 `+` 拼接（字母序），值是检测到的交叉发帖用户数。用于 `discover` 模式推荐新 subreddit（高重叠 = 值得监控的相关社区）。

数据清理策略：
- `seen_posts`：30 天过期
- `watched_threads`：`watch_until` 过期
- `opportunities`：手动归档
- `products_seen`：60 天未出现降低优先级

---

## 报告体系

### 每日扫描报告

```markdown
# Reddit Opportunity Scan — 2026-03-15

## 🎯 New Opportunities (score ≥ 7)
1. [Opportunity name] — score 9/10 — [brief]
2. ...

## 🔥 Trending Pain Points
- "topic A" — 5 mentions across 3 subreddits
- "topic B" — 3 mentions, rising

## ⏰ Time-Sensitive (< 2h old, high intent)
- [post title](link) — r/subreddit — URGENT
- ...

## 📊 Scan Stats
- Scanned: X subreddits, Y posts
- New opportunities: N
- Updated opportunities: M
```

### 周报

```markdown
# Weekly Opportunity Report — Week 11 (Mar 10-16, 2026)

## 📊 Summary
- Scanned: X subreddits across Y countries
- New opportunities: N (A high, B medium, C low)
- Top opportunity: [name] — score X

## 🎯 Top 5 Opportunities (ranked by score)
[detailed cards for each]

## 🔥 Trending Pain Points (this week vs last)
[frequency comparison]

## 🌍 Geographic Breakdown
| Region | Posts | Opportunities | Hit Rate |
|--------|-------|--------------|----------|
| US/EN  | X     | Y            | Z%       |
| DACH   | X     | Y            | Z%       |
...

## 💰 Revenue Potential Summary
Total estimated opportunity: $X/mo potential
Top market: [country/region]

## 📈 Content Ideas (from this scan)
[blog/social content suggestions based on trending topics]
```

### 月报增加

- 机会转化漏斗（discovered → investigating → building → launched → revenue）
- Subreddit ROI 排名
- 竞品趋势
- 跨市场需求对比
- 推荐配置调整

---

## 与营销 Skill 集成

| 阶段 | Skill | 用途 |
|------|-------|------|
| 痛点 → 内容选题 | content-strategy | 从高频痛点生成内容计划 |
| 机会 → 落地页 | copywriting | 为验证中的产品写落地页文案 |
| 竞品分析 | competitor-alternatives | 生成竞品对比页 |
| 社区回复 | copywriting | 生成自然、有价值的回复草稿 |
| 社交内容 | social-content | Reddit 热点 → LinkedIn/Twitter 内容 |
| 私信触达 | cold-email | 生成 Reddit DM 草稿 |

---

## 回复质量守则

Reddit 反感硬广。回复草稿遵循：

1. **先提供价值** — 80% 实质建议，20% 自然提及
2. **不以推销开头** — 永远先回答问题
3. **匹配语气** — 技术问题说技术，吐槽帖先共情
4. **承认局限** — 不假装万能
5. **多语言** — 检测帖子语言，用相同语言回复
6. **每日上限** — 建议不超过 5 条回复
7. **所有草稿标注 `[REVIEW BEFORE POSTING]`**

回复格式因帖子类型而异：
- 提问帖 → 分步骤解答
- 吐槽帖 → 共情 + 方案
- 对比帖 → 客观对比
- 求推荐帖 → 列选项（含你的产品）

---

## 高级分析

### 争议帖挖掘

`/r/{sub}/controversial.json` — 高评论低票比的帖子包含最真实的意见交锋。

### 评论流监控

`/r/{sub}/comments.json` — 整个 subreddit 的实时评论流，捕捉老帖子下的新讨论。

### 置顶帖挖掘

每个 subreddit 的 stickied 帖子（如 r/SaaS "Monthly Deals", r/startups "Share your startup"）是集中展示区，一次扫描大量产品信息。

### 多维度交叉分析

- 意图 × 技术栈 → DevTools 精准机会
- 情感 × 公司阶段 → 有预算的痛苦客户
- 地理 × 帖子时间 → 时区推断
- 社区重叠 × 竞品提及 → 迁移中的用户
- 发帖频率 × 情感轨迹 → 需求升级的用户

### 帖子生命周期预测

- 1h 内 score > 5 → 可能上 hot
- 1h 内 3+ 实质评论 → 引发讨论
- 被 crosspost → 影响力扩散
- 连续 2 次扫描 score 不变 → 已见顶

### 回复竞争度分析

- 0 回复 → ★★★★★ 完美空白
- 全是短回复 → ★★★★ 你的长回复脱颖而出
- 有中等回复 → ★★★ 需要补充视角
- 有高质量长回复 → ★★ 需要非常独特视角
- 已有竞品推荐 → ★ 考虑跳过

---

## 安全与合规

- 只采集公开数据（Reddit 公开 JSON API）
- 不存储 PII（仅 Reddit 用户名和公开内容）
- 回复草稿永远不自动发送
- `.reddit.json` 和 `.reddit-leads/` 应加入 `.gitignore`
- 控制请求频率，遵守 Reddit rate limit
- 每天回复上限建议 5 条

---

## 配合 `/loop` 定时运行

```
/loop 30m /reddit                    # 每 30 分钟扫一次
```

每次循环：
1. 读取 `subreddits.json` 配置（支持热重载）
2. 按 scan_priority 执行对应 tier 的扫描
3. 与 `.reddit.json` 去重，只处理新帖
4. 检查 watched_threads 新评论
5. Claude 分析、打分、聚合
6. 输出增量报告
7. 高价值机会（score ≥ 8）显示 `🚨 OPPORTUNITY: [title]`

---

## 全球定时扫描排期

```
UTC 00:00 - 06:00 → 亚太 (JP, KR, AU, NZ, SG, IN, TW, HK)
UTC 06:00 - 12:00 → 欧洲 (DE, FR, UK, NL, Nordic, IE, CH, IT, ES, PT)
UTC 12:00 - 18:00 → 美洲 (US, CA) + 全球英语社区
UTC 18:00 - 24:00 → 拉美 (BR, MX, AR) + 中东 (UAE, SA) + 非洲 (KE, NG, ZA)
```

---

## jq → Claude 数据合约

reddit.sh 所有模式输出统一的 JSON 结构，作为 Claude 分析的输入：

```json
{
  "meta": {
    "mode": "fetch",
    "campaign": "global_english",
    "sort": "new",
    "timestamp": 1710500000,
    "subreddits_scanned": ["SaaS", "startups", "Entrepreneur"],
    "total_raw": 300,
    "total_after_filter": 187,
    "errors": []
  },
  "posts": [
    {
      "id": "abc123",
      "subreddit": "SaaS",
      "title": "Anyone struggling to orchestrate multiple AI agents?",
      "selftext": "...",
      "author": "username",
      "score": 12,
      "num_comments": 8,
      "upvote_ratio": 0.89,
      "created_utc": 1710499000,
      "permalink": "/r/SaaS/comments/abc123/...",
      "link_flair_text": "B2B SaaS",
      "is_self": true,
      "edited": false,
      "crosspost_parent": null,

      "_jq_enriched": {
        "age_hours": 0.5,
        "time_window": "URGENT",
        "is_question": true,
        "tags": ["question", "request", "pain"],
        "intent_keywords_matched": ["looking for", "anyone know"],
        "negative_signals": ["frustrated"],
        "tech_stack": ["supabase", "next.js"],
        "company_stage": ["$5k MRR", "solo"],
        "geo_signals": ["US"],
        "revenue_mentions": ["$5k MRR"],
        "is_spam": false,
        "engagement_per_hour": 40.0
      }
    }
  ]
}
```

`_jq_enriched` 字段由 jq 在脚本层面计算，Claude 直接消费。

### `_jq_enriched` 字段定义

| 字段 | 类型 | 计算方式 |
|------|------|---------|
| `age_hours` | float | `(now - created_utc) / 3600` |
| `time_window` | string | `URGENT`(<1h), `HOT`(1-4h), `WARM`(4-24h), `COOL`(24-72h), `OLD`(>72h) |
| `is_question` | bool | 标题匹配 `\?$\|^How \|^What \|^Why \|...` 正则 |
| `tags` | string[] | 非互斥标签列表，一个帖子可同时命中多个：`question`（标题含疑问词）、`pain`（负面情绪词命中）、`request`（意图关键词命中） |
| `intent_keywords_matched` | string[] | 帖子 title+selftext 中命中的意图关键词原文（jq substring match） |
| `negative_signals` | string[] | 负面情绪词命中列表 |
| `tech_stack` | string[] | 技术栈关键词命中列表 |
| `company_stage` | string[] | MRR/团队规模等原文摘取 |
| `geo_signals` | string[] | 地理关键词命中列表 |
| `revenue_mentions` | string[] | 收入相关原文摘取 |
| `is_spam` | bool | 命中任一 spam 规则 |
| `engagement_per_hour` | float | `(score + num_comments) / max(age_hours, 0.1)` — 分母最小 0.1 防止除零 |

**意图分级（intent_tier）由 Claude 在 Phase 2 判定，不在 jq 层计算。** jq 只做关键词匹配并输出 `intent_keywords_matched`，Claude 结合上下文判断真实意图等级（1-5）。这比 jq 正则匹配更准确，因为"looking for a tool"在不同上下文中可能是 Tier 2 也可能是 Tier 4。

---

## subreddits.json 完整 Schema

```json
{
  "$schema": "subreddits-config-v1",
  "campaigns": {
    "global_english": {
      "tier": "S",
      "language": "en",
      "scan_frequency": "every_loop",
      "subreddits": [
        {
          "name": "SaaS",
          "subscribers": 620000,
          "sort_modes": ["new", "hot"],
          "pages": 2,
          "flair_boost": {"B2B SaaS": 1},
          "health": "high",
          "rules_summary": "允许推广但必须相关且有价值",
          "self_promo_allowed": true,
          "moderation_strictness": "medium"
        }
      ],
      "search_keywords": ["looking for a tool", "need alternative", "frustrated with"],
      "competitors": ["Notion", "Airtable"],
      "competitor_queries": [
        "{competitor} alternative",
        "{competitor} frustrated",
        "switching from {competitor}"
      ]
    },
    "dach": {
      "tier": "S",
      "language": "de",
      "scan_frequency": "daily",
      "subreddits": [
        {"name": "StartupDACH", "subscribers": 14900, "sort_modes": ["new"], "pages": 1},
        {"name": "de", "subscribers": 3170000, "sort_modes": ["search_only"], "pages": 0}
      ],
      "search_keywords": ["Startup", "SaaS", "Gründung", "Alternative zu", "Tool gesucht", "frustriert"]
    }
  },
  "scan_priority": {
    "every_loop": {"tiers": ["S"], "depth": "full", "comment_fetch": true},
    "daily": {"tiers": ["A"], "depth": "standard", "comment_fetch": "high_score_only"},
    "weekly": {"tiers": ["B"], "depth": "light", "comment_fetch": false}
  }
}
```

大型国家 sub（如 r/de）设置 `sort_modes: ["search_only"]`，不做 fetch 全量扫描，只用关键词搜索。

### 配置字段定义

| 字段 | 类型 | 说明 |
|------|------|------|
| `flair_boost` | `{string: number}` | 命中指定 flair 时，在 Phase 2 中 Claude 对该帖子的 `market_value` 维度加 N 分（1-10 范围内）。例如 `{"B2B SaaS": 1}` 表示命中此 flair 的帖子 market_value +1 |
| `health` | `"high" \| "medium" \| "low"` | 由 `discover` 模式根据以下规则自动计算：`high` = 订阅 > 10k 且日帖 > 5 且互动率 > 3 评论/帖；`medium` = 满足 2 项；`low` = 满足 0-1 项 |
| `moderation_strictness` | `"high" \| "medium" \| "low"` | 由 `discover` 模式从 `/about/rules.json` 推断。影响回复/触达模块（可选模块）中的回复风格。**不影响核心机会发现流程的评分** |
| `self_promo_allowed` | bool | 同上，仅影响可选的回复模块 |
| `rules_summary` | string | 人类可读的规则摘要，供 Claude 在生成回复草稿时参考 |

### scan_priority 详细定义

| 配置 | 含义 |
|------|------|
| `"comment_fetch": true` | 对 `final_score >= 8` 的帖子自动抓取评论树 |
| `"comment_fetch": "high_score_only"` | 对 `final_score >= 8` 的帖子抓取评论树（与 `true` 相同，仅语义更明确） |
| `"comment_fetch": false` | 不自动抓取评论，仅在用户手动请求时抓取 |

---

## 模式输出格式

每个模式输出 JSON 到 stdout，Claude 通过管道或临时文件消费。

| 模式 | 输出实体 | 关键字段 |
|------|---------|---------|
| fetch | `{meta, posts[]}` | 见数据合约 |
| comments | `{post, comments[{author, body, score, replies[], depth}]}` | 评论树 |
| profile | `{user, posts[], comments[], subreddits_active[], urls_found[]}` | 用户画像 |
| discover | `{query, results[{name, subscribers, description, health_score}]}` | subreddit 列表 |
| search | `{query, type, results[]}` | 同 fetch 的 posts 或 comments |
| crosspost | `{multi_posters[{author, post_count, subreddits[], titles[]}]}` | 交叉用户 |
| stickied | `{subreddit, thread, comments[]}` | 同 comments |
| firehose | `{subreddits, comments[{author, body, subreddit, link_title, score, urls[]}]}` | 评论流 |
| export | CSV 或 JSON 文件 | 机会列表 |
| cleanup | `{cleaned: {seen_posts: N, watched_threads: N, ...}}` | 清理统计 |
| diagnose | `{network: ok, rate_limit: {remaining, reset}, jq: ok, config: ok}` | 诊断结果 |
| duplicates | `{post_id, duplicates[{subreddit, title, score}]}` | 同链接提交 |
| wiki | `{subreddit, page, content_md}` | wiki 内容 |
| stats | `{total_seen, total_opportunities, total_watched, subreddits_configured, data_size_kb}` | 统计 |

---

## Firehose 模式说明

firehose 模式是 **轮询** 而非流式（Reddit 未认证 API 不提供 WebSocket）。

- 调用 `/r/{sub}/comments.json?limit=100`
- 用 `.reddit.json` 中的 `last_firehose_comment_id` 去重
- 推荐轮询间隔：60 秒（配合 `/loop 1m` 或独立 cron）
- 适用于需要实时性的场景，普通扫描用 fetch 即可

---

## 首次运行

首次运行时：
1. 检查 jq 是否已安装，未安装则提示 `brew install jq`
2. 创建 `.reddit-leads/` 目录和 `.reddit-leads/.reddit.json`（空初始状态）
3. 提示用户检查 `subreddits.json` 配置是否符合自己的产品领域
4. 提示是否存在 `.agents/product-marketing-context.md`，如有则加载
5. 执行一次小规模扫描（仅 Tier S 英语社区，1 页）验证连通性
6. 输出第一份扫描报告

---

## Subreddit 访问异常处理

| 异常 | HTTP 状态 | 处理 |
|------|----------|------|
| 私有 sub | 403 + `"reason": "private"` | 跳过，从配置中标记为 `private`，不再扫描 |
| 被隔离 sub | 403 + quarantine | 跳过（需要登录确认才能访问） |
| 已删除/不存在 sub | 404 | 跳过，从配置中移除，记录警告 |
| 名称变更/重定向 | 302 | 更新配置中的名称 |
| NSFW sub | 需要认证 | 跳过（未认证 API 无法访问） |

---

## 周报/月报触发机制

- **周报：** 每周日 UTC 23:00 的 `/loop` 循环中触发（检测当前是否为周日）
- **月报：** 每月最后一天的 `/loop` 循环中触发
- 如果错过触发时间，下次 `/loop` 补生成
- 可手动触发：用户输入 `/reddit weekly` 或 `/reddit monthly`

---

## Rate Limit 预算分配

100 请求/~260 秒的预算这样分配：

| 用途 | 请求数 | 说明 |
|------|--------|------|
| Tier S fetch（合并请求） | ~15 | 60+ sub 合并为 ~12 组，部分 2 页 |
| Tier S search（竞品+意图） | ~10 | 竞品查询 + 意图关键词搜索 |
| Comments（高分帖） | ~10 | 对 score ≥ 8 的帖子抓评论 |
| Watched threads 检查 | ~5 | 最多 5 个监控中的帖子 |
| Profile（高价值用户） | ~5 | 最多 5 个用户画像 |
| 缓冲 | ~55 | 留给 Tier A 日扫描、discover 等 |

单次 `/loop` 循环（Tier S only）约消耗 40-45 个请求，在 ~2.5 分钟内完成。留有充足缓冲。

---

## Opportunity 生命周期状态机

```
discovered → investigating → validated → building → launched → revenue → archived
                                                              → no_traction → archived
            → declined → archived
```

| 状态 | 触发 |
|------|------|
| discovered | 首次识别到产品机会 |
| investigating | 进入 Phase 3 深度验证 |
| validated | 微验证通过（landing page 有注册、Reddit 外有佐证） |
| building | 用户确认开始构建 |
| launched | MVP 上线 |
| revenue | 产生首笔收入 |
| no_traction | 上线后无转化 |
| declined | 用户主动放弃该机会 |
| archived | 终态 |

---

## .gitignore 模板

Skill 首次运行时提示用户将以下内容加入项目 `.gitignore`：

```
# Reddit Opportunity Hunter
.reddit-leads/
.reddit-leads/.reddit.json
```

---

## 回复/触达（可选模块）

以下功能是可选的辅助模块，不属于核心的产品机会发现流程。当用户已经有产品并想在 Reddit 推广时使用：

- 回复草稿生成
- 回复竞争度分析
- 回复时机建议
- 私信草稿（配合 cold-email skill）
- 社区参与策略

核心流程始终是：**发现痛点 → 评估机会 → 验证 → 构建 → 赚钱。**

---

## Subreddit 质量动态评分

追踪每个 subreddit 的历史命中率（机会发现数 / 扫描帖子数）：

```json
{
  "subreddit_quality": {
    "SaaS": {"scanned": 2340, "opportunities": 23, "hit_rate": 0.98},
    "microsaas": {"scanned": 890, "opportunities": 15, "hit_rate": 1.69},
    "Entrepreneur": {"scanned": 3100, "opportunities": 8, "hit_rate": 0.26}
  }
}
```

命中率高的小 sub（如 microsaas 1.69%）比命中率低的大 sub（如 Entrepreneur 0.26%）更值得深度扫描。动态调整 scan_priority。
