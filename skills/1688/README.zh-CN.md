# 1688

[English](./README.md) | **中文**

通过 Bing/Google 搜索 + Kimi WebBridge 查找阿里巴巴中国（1688.com）批发供应商，提取完整联系信息，并按到空/海/陆口岸的距离进行物流评分。

**核心思路：** 在 Bing/Google 搜索 1688 工厂页面 → 提取店铺子域名 → 访问联系信息页面 → 获取电话、手机、地址和联系人 → 联系人缺失时 Kimi 优先调用天眼查补充 → 按工厂地址到最近空/海/陆口岸的距离打分，距离越近优先级越高，降低国内段运输成本。

---

## 安装

```bash
npx skills add sky-flux/skills --skill 1688
```

全局安装（在所有项目中可用）：

```bash
npx skills add sky-flux/skills --skill 1688 -g
```

## 前置条件

- **Kimi WebBridge** — 浏览器自动化守护进程（运行在 `127.0.0.1:10086`）
  ```bash
  ~/.kimi-webbridge/bin/kimi-webbridge status
  ```

## 快速开始

直接提问：

```
查找 1688 上的轴承供应商并提取他们的联系信息
```

或者：

```
在 1688 上搜索仓储货架制造商，获取 3 家供应商的电话号码
```

## 工作原理

1. **Bing/Google 搜索** — `site:1688.com/factory <产品>` 查找工厂页面，优先使用 Bing 避免验证码
2. **提取 URL** — 从搜索结果中解析 `www.1688.com/factory/...` 链接
3. **访问工厂页面** — 加载每个工厂黄页
4. **提取子域名** — 通过无障碍树或文本匹配找到店铺链接（例如 `xxx.1688.com`）
5. **访问联系信息页面** — 跳转到 `https://<子域名>.1688.com/page/contactinfo.htm`
6. **提取联系方式** — 从页面中解析电话、手机、地址、联系人
7. **补充信息（可选）** — 如果缺少联系人，Kimi 优先调用天眼查数据补充；非 Kimi 或无法调用天眼查时，使用 Bing/Google 搜索工商注册信息
8. **物流评分** — 根据工厂地址计算到最近空运/海运/陆运口岸的距离，距离越近得分越高、优先级越高

## 输出格式

结果以 Markdown 表格形式返回：

| 公司 | 电话 | 手机 | 地址 | 联系人 | 店铺 | 最近口岸 | 运输方式 | 物流分 |
|------|------|------|------|--------|------|---------|---------|--------|
| 示例轴承有限公司 | 86 010 12345678 | 13800138000 | 北京市... | 张先生 | example.1688.com | 天津港 | 海运 | 8 |

## 参考资料

- `references/search-engines.md` — Bing/Google 搜索结果提取与拦截检测
- `references/factory.md` — 工厂页面子域名提取脚本
- `references/contact.md` — 联系信息页面联系方式提取脚本
- `references/logistics-airports.md` — 主要空运口岸（机场海关）
- `references/logistics-seaports.md` — 主要海运口岸（港口海关）
- `references/logistics-land-ports.md` — 主要陆运口岸（边境/跨境关口）
- `references/logistics-scoring.md` — 基于口岸距离的工厂物流评分
