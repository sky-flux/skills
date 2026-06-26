# 1688

**English** | [中文](./README.zh-CN.md)

Find Alibaba China (1688.com) wholesale suppliers, extract complete contact information, and score them by logistics proximity to air/sea/land customs ports via Bing/Google Search + Kimi WebBridge.

**Core idea:** Search Bing/Google for 1688 factory pages → extract shop subdomains → visit contactinfo pages → get phone, mobile, address, and contact person → supplement missing contact info via Tianyancha (Kimi) or Bing/Google search → score factories across multiple dimensions (information completeness, business credibility, scale, establishment years, 1688 shop age, product match, logistics distance, activity, partners, certifications, official website, domain age) and cross-check via Google/Bing to reduce risk.

---

## Installation

```bash
npx skills add sky-flux/skills --skill 1688
```

Install globally (available across all projects):

```bash
npx skills add sky-flux/skills --skill 1688 -g
```

## Prerequisites

- **Kimi WebBridge** — Browser automation daemon (runs on `127.0.0.1:10086`)
  ```bash
  ~/.kimi-webbridge/bin/kimi-webbridge status
  ```

## Quick Start

Just ask:

```
Find 1688 suppliers for bearings and extract their contact info
```

Or:

```
Search 1688 for warehouse shelf manufacturers, get 3 suppliers' phone numbers
```

## How It Works

1. **Google/Bing Search** — `site:1688.com/factory <product>` finds factory pages; Bing is preferred to avoid CAPTCHA
2. **Extract URLs** — Parse search results for `www.1688.com/factory/...` links
3. **Visit Factory Pages** — Load each factory yellow page
4. **Extract Subdomains & Main Products** — Find shop links (e.g., `xxx.1688.com`) and extract `mainProducts` for scoring and supplier database archiving
5. **Visit Contactinfo** — Navigate to `https://<subdomain>.1688.com/page/contactinfo.htm`
6. **Extract Contacts** — Parse phone, mobile, address, contact person from the page
7. **Supplement (Optional)** — If contact person is missing, query Tianyancha first when using Kimi; otherwise fall back to Bing/Google search for business registration info
8. **Logistics Scoring** — Calculate the distance from the factory address to the nearest air/sea/land customs port; closer factories get higher priority to lower transport costs
9. **Comprehensive Scoring** — Score factories across 12+ dimensions (info completeness, business credibility, scale, establishment, 1688 shop age, product match, logistics, activity, partners, certifications, official website, domain age) and cross-check via Google/Bing

## Output Format

Results are returned as Markdown tables:

| Company | Main Products | Phone | Mobile | Address | Contact | Shop | Nearest Port | Mode | Logistics Score |
|---------|--------------|-------|--------|---------|---------|------|--------------|------|-----------------|
| Example Bearing Co. | bearings, deep groove ball bearings | 86 010 12345678 | 13800138000 | Beijing... | Mr. Zhang | example.1688.com | Tianjin Port | sea | 8 |

## References

- `references/search-engines.md` — Bing/Google search result extraction and block detection
- `references/factory.md` — Factory page subdomain extraction scripts
- `references/contact.md` — Contactinfo page contact extraction scripts
- `references/logistics-airports.md` — Major air freight customs airports
- `references/logistics-seaports.md` — Major sea freight customs ports
- `references/logistics-land-ports.md` — Major land border crossings
- `references/logistics-scoring.md` — Distance-based factory logistics scoring
- `references/factory-scoring.md` — Comprehensive factory scoring and ranking guide
