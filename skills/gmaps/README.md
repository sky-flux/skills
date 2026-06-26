# Google Maps Bulk Business Collector

**English** | [中文](./README.zh-CN.md)

Collect structured business data from Google Maps using `agent-browser --json snapshot`. Supports single keywords or batch keyword files (`.txt`, one per line). The workflow processes **current visible cards first, then scrolls for more** — ensuring no merchant is missed or duplicated.

**Core idea:** Search Google Maps by keyword → extract visible merchant cards → click each card → parse the place page → scroll for more results → save structured data.

---

## Installation

```bash
npx skills add sky-flux/skills --skill gmaps
```

Install globally (available across all projects):

```bash
npx skills add sky-flux/skills --skill gmaps -g
```

## Prerequisites

- **agent-browser** CLI installed
- **agent-browser** skill installed

```bash
which agent-browser || command -v agent-browser
agent-browser install && npx skills add vercel-labs/agent-browser -g
agent-browser profiles
```

Use `--profile "Default"` for all commands to reuse login state.

> If a daemon is already running with a different profile, run `agent-browser close` first.

## Quick Start

Just ask:

```
Scrape Google Maps for pizza places near Central Park, NY
```

Or provide a keyword file:

```
/Users/martinadamsdev/workspace/googlemaps/keywords/keywords_chemistry.txt
```

## How It Works

1. **Read keywords** — Single keyword or `.txt` file (one per line, `#` comments allowed).
2. **Open search page** — `agent-browser open` the Google Maps search URL.
3. **Extract visible cards** — Find `role="article"` entries and matching `role="link"` entries by name.
4. **Process each new merchant** — Click into the place page, validate the URL, and extract fields.
5. **Return and scroll** — Re-snapshot to refresh ref IDs, then scroll the result feed.
6. **Bottom detection** — Stop after 3 consecutive scrolls yield no new merchants.
7. **Save results** — Output JSON Lines or CSV to `skills/gmaps/output/`.

## Output Fields

| Field | Description |
|-------|-------------|
| `name` | Merchant name (parsed from place URL) |
| `address` | Street address |
| `phone` | Phone number |
| `website` | Website URL |
| `pluscode` | Google Maps Plus Code |
| `hours` | Opening hours |
| `category` | Business category |
| `claimed` | Whether the business is claimed |
| `socialLinks` | Social media links found on the page |
| `maps` | Place page URL |
| `keyword` | Keyword that produced this result |

## Output Format

**JSON Lines** (default):

```jsonl
{"name":"Yara Indonesia","address":"South Quarter...","phone":"+62 21 22722011","website":"yara.id","pluscode":"PQ4M+6X...","hours":"Closed  Opens 8:30 AM","category":"Fertilizer supplier","claimed":"true","socialLinks":"","maps":"https://www.google.com/maps/place/Yara+Indonesia/...","keyword":"urea fertilizer importer Jakarta Indonesia"}
```

**CSV** (alternative):

```csv
name,address,phone,website,pluscode,hours,category,claimed,socialLinks,maps,keyword
Yara Indonesia,"South Quarter, Tower C...",+62 21 22722011,yara.id,"PQ4M+6X West Cilandak...","Closed  Opens 8:30 AM",Fertilizer supplier,true,,https://.../Yara+Indonesia/,urea fertilizer importer Jakarta Indonesia
```

## Critical Rules

- Extract visible cards **before** scrolling.
- Deduplicate merchants **by name** within each keyword.
- Ref IDs are ephemeral; always re-snapshot after navigation.
- Parse merchant name from the place URL, not the accessibility tree.
- Skip results where the URL stays on `/search/` or lacks both address and phone.

## References

- `SKILL.md` — Full step-by-step workflow and extraction rules
