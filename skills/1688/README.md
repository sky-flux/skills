# 1688

**English** | [中文](./README.zh-CN.md)

Find Alibaba China (1688.com) wholesale suppliers and extract complete contact information via Bing/Google Search + Kimi WebBridge.

**Core idea:** Search Bing/Google for 1688 factory pages → extract shop subdomains → visit contactinfo pages → get phone, mobile, address, and contact person; supplement missing contact info via Tianyancha (Kimi) or Bing/Google search.

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
4. **Extract Subdomains** — Find shop links (e.g., `xxx.1688.com`) via accessibility tree or text matching
5. **Visit Contactinfo** — Navigate to `https://<subdomain>.1688.com/page/contactinfo.htm`
6. **Extract Contacts** — Parse phone, mobile, address, contact person from the page
7. **Supplement (Optional)** — If contact person is missing, query Tianyancha first when using Kimi; otherwise fall back to Bing/Google search for business registration info

## Output Format

Results are returned as Markdown tables:

| Company | Phone | Mobile | Address | Contact | Shop |
|---------|-------|--------|---------|---------|------|
| Example Bearing Co. | 86 010 12345678 | 13800138000 | Beijing... | Mr. Zhang | example.1688.com |

## References

- `references/google-search.md` — Google search result extraction scripts
- `references/factory.md` — Factory page subdomain extraction scripts
- `references/contact.md` — Contactinfo page contact extraction scripts
