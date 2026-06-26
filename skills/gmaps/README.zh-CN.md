# Google Maps 商家批量采集器

[English](./README.md) | **中文**

使用 `agent-browser --json snapshot` 从 Google Maps 采集结构化商家数据。支持单个关键词或批量关键词文件（`.txt`，每行一个）。工作流程遵循**先提取当前可见卡片、再滚动加载更多**的原则，确保不遗漏、不重复。

**核心理念：** 按关键词搜索 Google Maps → 提取可见商家卡片 → 点击进入详情页 → 解析详情页 → 滚动加载更多 → 保存结构化数据。

---

## 安装

```bash
npx skills add sky-flux/skills --skill gmaps
```

全局安装（所有项目可用）：

```bash
npx skills add sky-flux/skills --skill gmaps -g
```

## 前提条件

- 已安装 **agent-browser** CLI
- 已安装 **agent-browser** skill

```bash
which agent-browser || command -v agent-browser
agent-browser install && npx skills add vercel-labs/agent-browser -g
agent-browser profiles
```

所有命令使用 `--profile "Default"` 以复用登录状态。

> 如果已有不同 profile 的守护进程在运行，先执行 `agent-browser close`。

## 快速开始

直接说：

```
采集纽约中央公园附近的披萨店
```

或提供关键词文件：

```
/Users/martinadamsdev/workspace/googlemaps/keywords/keywords_chemistry.txt
```

## 工作原理

1. **读取关键词** — 单个关键词或 `.txt` 文件（每行一个，允许 `#` 注释）。
2. **打开搜索页** — 用 `agent-browser open` 打开 Google Maps 搜索 URL。
3. **提取可见卡片** — 查找 `role="article"` 条目，并按名称匹配对应的 `role="link"`。
4. **处理每个新商家** — 点击进入详情页、验证 URL、提取字段。
5. **返回并滚动** — 重新 snapshot 刷新 ref ID，然后滚动结果列表。
6. **触底检测** — 连续 3 次滚动没有新商家时停止。
7. **保存结果** — 输出 JSON Lines 或 CSV 到 `skills/gmaps/output/`。

## 输出字段

| 字段 | 说明 |
|------|------|
| `name` | 商家名称（从 place URL 解析） |
| `address` | 街道地址 |
| `phone` | 电话号码 |
| `website` | 网站 URL |
| `pluscode` | Google Maps Plus Code |
| `hours` | 营业时间 |
| `category` | 商家类别 |
| `claimed` | 是否已认领商家 |
| `socialLinks` | 页面中找到的社交媒体链接 |
| `maps` | 详情页 URL |
| `keyword` | 产生该结果的关键词 |

## 输出格式

**JSON Lines**（默认）：

```jsonl
{"name":"Yara Indonesia","address":"South Quarter...","phone":"+62 21 22722011","website":"yara.id","pluscode":"PQ4M+6X...","hours":"Closed  Opens 8:30 AM","category":"Fertilizer supplier","claimed":"true","socialLinks":"","maps":"https://www.google.com/maps/place/Yara+Indonesia/...","keyword":"urea fertilizer importer Jakarta Indonesia"}
```

**CSV**（可选）：

```csv
name,address,phone,website,pluscode,hours,category,claimed,socialLinks,maps,keyword
Yara Indonesia,"South Quarter, Tower C...",+62 21 22722011,yara.id,"PQ4M+6X West Cilandak...","Closed  Opens 8:30 AM",Fertilizer supplier,true,,https://.../Yara+Indonesia/,urea fertilizer importer Jakarta Indonesia
```

## 关键规则

- 滚动前**先提取**当前可见卡片。
- 每个关键词内按名称**去重**。
- ref ID 是临时的，导航后必须重新 snapshot。
- 商家名称从 place URL 解析，不要从 accessibility tree 读取。
- 跳过 URL 仍停留在 `/search/` 或同时缺少地址和电话的结果。

## 参考文档

- `SKILL.md` — 完整逐步工作流程与提取规则
