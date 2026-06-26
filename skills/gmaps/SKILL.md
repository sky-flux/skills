---
name: gmaps
description: Use when searching Google Maps locations, extracting business listings from Google Maps search results, or scraping merchant details from Google Maps place pages. Use for batch keyword searches, scrolling through result lists, collecting business addresses/phones/websites from maps, or any automated Google Maps data collection task. Triggers on mentions of Google Maps scraping, merchant data extraction, business leads from maps, or bulk maps searches.
---

# Google Maps Bulk Business Collector

## Overview

Collect structured business data from Google Maps using `agent-browser --json snapshot`. Supports single keywords or batch keyword files (`.txt`, one per line). The workflow processes **current visible cards first, then scrolls for more** — ensuring no merchant is missed or duplicated.

## Prerequisites

- `agent-browser` CLI installed
- `agent-browser` skill installed

## Step 1: Install & Profile

```bash
# Check installation
which agent-browser || command -v agent-browser

# Install if missing (macOS)
brew install agent-browser
# Install if missing (other)
npm i -g agent-browser

# Install the skill
agent-browser install && npx skills add vercel-labs/agent-browser -g

# Get Chrome profile
agent-browser profiles
```

Use `--profile "Default"` for all commands to reuse login state.

> If daemon already running with different profile: `agent-browser close` first.

## Step 2: Read Keywords

The user may provide keywords in two ways:

**A. Single keyword:**
```
"pizza near Central Park, NY"
```

**B. Keyword file (`.txt`):**
```
/Users/martinadamsdev/workspace/googlemaps/keywords/keywords_chemistry.txt
```

If a file path is provided, read it and split by lines (skip empty lines and `#` comments).

## Step 3: For Each Keyword — Search, Extract, Scroll Loop

For every keyword in the list, execute the following.

### 3.1 Open Search Page

```bash
agent-browser --profile "Default" open "https://www.google.com/maps/search/{encodeURIComponent(keyword)}"
agent-browser wait 3000
```

### 3.2 Initialize State

Track in memory:
- `processedNames` = `Set()` — merchant names already processed (deduplication key)
- `results` = `[]` — all collected merchant details
- `noNewCount` = `0` — consecutive scrolls with zero new merchants
- `scrollAttempt` = `0` — current scroll number

### 3.3 Main Loop

**Repeat until bottom reached or max 30 scrolls:**

---

#### A. Extract current visible merchant list

```bash
agent-browser --json snapshot
```

From `data.refs`:

1. **Find articles** (`role: "article"`) — these are the visible merchant cards.
2. **Find links** (`role: "link"`) with matching names — each article has a corresponding link that navigates to its detail page.

```
articles = refs entries with role="article"   → [{ref: "e29", name: "Yara Indonesia"}, ...]
links    = refs entries with role="link"      → [{ref: "e36", name: "Yara Indonesia"}, ...]

Match each article to its link by name:
  "Yara Indonesia" (article e29) → link e36
  "PT Bio Agromitra" (article e30) → link e38
```

Build the merchant list:
```
visibleMerchants = [
  {name: "Yara Indonesia", articleRef: "e29", linkRef: "e36"},
  {name: "PT Bio Agromitra", articleRef: "e30", linkRef: "e38"},
  ...
]
```

**Note:** The `linkRef` is used to `click` into the detail page. The actual URL is obtained after navigation via `agent-browser get url`.

> **Ref IDs change after page reload.** After returning to the search results (Step F below), the accessibility tree is rebuilt and all ref IDs are reassigned. You **must re-run `snapshot --json`** before clicking the next merchant to get fresh `linkRef` values. Do NOT reuse stale ref IDs from a previous snapshot.

#### B. Filter new merchants

Compare names against already-processed merchants:

```
newMerchants = visibleMerchants.filter(m => !processedNames.has(m.name))
```

#### C. Bottom detection

```
IF newMerchants.length === 0:
  noNewCount += 1
  IF noNewCount >= 3:
    BREAK loop (reached bottom, all merchants processed)
  ELSE:
    // No new merchants this round, but haven't hit threshold yet
    // Continue to scroll and try again
ELSE:
  noNewCount = 0
```

#### D. Process each new merchant

For every merchant in `newMerchants` (in order):

```bash
# 1. Look up the current link ref for this merchant name
# (ref IDs change after each page reload — use the latest snapshot)
linkRef = findLinkRefByName(latestSnapshot, merchant.name)

# 2. Click the link ref to navigate to place page
agent-browser click {linkRef}

# 3. Wait for detail panel
agent-browser wait 4000

# 4. Get the place URL
agent-browser get url
```

**Validity check:** After getting the URL, verify the page is a real merchant detail page:

```
INVALID if:
  - URL contains "/search/" (did not navigate to a place page)
  - URL does not contain "/place/"
  - Extracted data has no "address" AND no "phone" (likely a city/region page)
```

If invalid, skip this merchant, add its name to `processedNames`, and return to Step F.

```bash
# 5. Run both snapshot formats (only for valid pages)
agent-browser --json snapshot    # structured refs (address/phone/website...)
agent-browser snapshot           # text tree (rating from image)
```

### From `agent-browser get url`

Record the returned URL as `maps` field.

### From JSON snapshot `data.refs`

| Field | Match Rule | Extraction |
|-------|-----------|-----------|
| **address** | `role: "button"` + `name` starts with `Address:` | strip `Address: ` prefix |
| **phone** | `role: "button"` + `name` starts with `Phone:` | strip `Phone: ` prefix |
| **website** | `role: "link"` + `name` starts with `Website:` | strip `Website: ` prefix |
| **pluscode** | `role: "button"` + `name` starts with `Plus code:` | strip `Plus code: ` prefix |
| **hours** | `role: "button"` + `name` starts with `Hours` / `Open` / `Closed` | strip `Hours ` prefix, remove trailing helpers |
| **category** | `role: "button"` near heading, no known prefix | `name` value |
| **claimed** | Any ref `name` contains `claim this business` (case-insensitive) | `false` if found, else `true` |

Social links: search all `link` refs for domains `facebook.com`, `instagram.com`, `linkedin.com`, `twitter.com`, `x.com`, `youtube.com`, `tiktok.com`.

### Merchant name (from URL)

The place page's accessibility tree does **not** reliably expose the merchant name in `heading [level=1]` (it is often empty). Instead, parse the name from the place URL:

```
URL: https://www.google.com/maps/place/Yara+Indonesia/@...
                        ^^^^^^^^^^^^^^^
                        Parse this segment
```

Extract: `Yara+Indonesia` → decode to `Yara Indonesia`

Decode rules:
- Replace `+` with space
- Replace `%20` with space, `%26` with `&`, `%2C` with `,`

If URL parsing fails, fall back to the merchant name from the search result card.

### Rating (from text snapshot)

Find `image` nodes containing "stars" in the text snapshot:

```
- image "4.4 stars "
```

Extract: `4.4` → `rating: "4.4"`

Add `{...extractedFields, name, rating, maps: placeUrl, keyword: currentKeyword}` to `results`.

Add `merchant.name` to `processedNames`.

#### E. Human-like delay between merchants

```bash
agent-browser wait {delay_ms}
```

Compute: `delay_ms = Math.round(3000 + Math.random() * 5000)` (range 3000–8000ms).

#### F. Return to search results & refresh refs

After processing a merchant (or skipping an invalid one), return to the search results page **and re-snapshot** to get fresh ref IDs:

```bash
agent-browser open "https://www.google.com/maps/search/{encodeURIComponent(keyword)}"
agent-browser wait 3000
agent-browser --json snapshot
```

Use the fresh snapshot to look up the `linkRef` for the next merchant by matching its name. **Do not reuse ref IDs from a previous iteration.**

#### G. Scroll for more results

```bash
agent-browser eval 'const f=document.querySelector("div[role=\"feed\"]");if(f)f.scrollTop=f.scrollHeight;'
agent-browser wait 2500
```

Increment `scrollAttempt`.

#### H. Continue loop

Go back to step **A**.

---

### 3.4 Output Keyword Results

After loop ends, write all `results` for this keyword to a file.

**JSON Lines format (recommended):**

Save to `skills/gmaps/output/{keyword_slug}.jsonl` (one JSON object per line):

```jsonl
{"name":"Yara Indonesia","address":"South Quarter...","phone":"+62 21 22722011","website":"yara.id","pluscode":"PQ4M+6X...","hours":"Closed  Opens 8:30 AM","category":"Fertilizer supplier","claimed":"true","socialLinks":"","maps":"https://www.google.com/maps/place/Yara+Indonesia/...","keyword":"urea fertilizer importer Jakarta Indonesia"}
{"name":"PT Bio Agromitra Indonesia","address":"...","phone":"...","maps":"...","keyword":"urea fertilizer importer Jakarta Indonesia"}
```

**CSV format (alternative):**

Save to `skills/gmaps/output/{keyword_slug}.csv`:

```csv
name,address,phone,website,pluscode,hours,category,claimed,socialLinks,maps,keyword
Yara Indonesia,"South Quarter, Tower C...",+62 21 22722011,yara.id,"PQ4M+6X West Cilandak...","Closed  Opens 8:30 AM",Fertilizer supplier,true,,https://.../Yara+Indonesia/,urea fertilizer importer Jakarta Indonesia
```

Fields to include: `name`, `address`, `phone`, `website`, `pluscode`, `hours`, `category`, `claimed`, `socialLinks`, `maps`, `keyword`.

Also output a brief summary:
- Keyword searched
- Total merchants collected
- File path

### 3.5 Next Keyword

Close browser session:

```bash
agent-browser close
```

Repeat from Step 3.1 for the next keyword.

## Step 4: Final Summary

After all keywords processed, output:
- Total keywords processed
- Total merchants collected across all keywords
- Per-keyword counts
- Output file paths (`skills/gmaps/output/*.jsonl` or `*.csv`)

## Critical Rules

1. **Order matters: extract first, scroll second.** Never scroll before processing current visible cards, or you may miss merchants that get pushed out of view.
2. **Deduplicate by name.** Within a keyword search, two cards with the same name are treated as the same merchant. Track `processedNames` to avoid re-processing.
3. **Never process the same name twice.** Check `processedNames` before clicking any detail page link.
4. **Always use `--json snapshot`** for detail pages. The `refs` object is stable against DOM changes.
5. **Google Maps is JS-rendered.** Always `open → wait → snapshot`. Never `snapshot <url>` directly.
6. **Bottom detection:** 3 consecutive iterations with `newMerchants.length === 0` means reached bottom.
7. **If a place page fails** (timeout, empty snapshot), log the error, skip that merchant, and continue. Do NOT stop the keyword.
8. **If eval returns empty array** on first iteration (no feed found), the page may still be loading. Wait 2000ms more and retry snapshot + eval once.
9. **Ref IDs are ephemeral.** After any page navigation (`click`, `open`), ref IDs are reassigned. Always re-snapshot before using a ref ID.
10. **Name comes from the URL, not the accessibility tree.** The `heading [level=1]` in Google Maps place pages is frequently empty. Parse the merchant name from `/place/{Name}/` in the URL.
11. **Filter invalid results.** Some search results are cities, regions, or listings without a dedicated place page. Skip any result where the URL stays on `/search/` or lacks both address and phone.

## Field Extraction Reference

### Detail Page — Two Sources

**Text snapshot** (tree structure) — for rating only:

```
- main [ref=e32]
  - heading [level=1]                    ← often empty; do NOT use for name
  - image "4.4 stars "                   ← rating
  - button "Pizza restaurant" [ref=e43]  ← category (from JSON refs instead)
  - region "Information for ..." [ref=e37]
    - button "Address: 117 W 57th St..." [ref=e58]
    - link "Website: angelospizzany.com " [ref=e63]
    - button "Phone: (212) 333-4333 " [ref=e64]
```

> **Name comes from the place URL**, not the accessibility tree. The `heading [level=1]` in Google Maps place pages is frequently empty. Parse the name from `/place/{Name}/` in the URL.

**JSON snapshot refs** — for structured fields:

```json
{
  "e58": {"name": "Address: 117 W 57th St, New York, NY 10019", "role": "button"},
  "e63": {"name": "Website: angelospizzany.com", "role": "link"},
  "e64": {"name": "Phone: (212) 333-4333", "role": "button"},
  "e65": {"name": "Plus code: Q27C+XR New York", "role": "button"},
  "e49": {"name": "Hours Open · Closes 10 PM Show open hours for the week", "role": "button"}
}
```

### Extraction Patterns

| Raw ref name | Extracted value |
|-------------|-----------------|
| `Address: 117 W 57th St, New York, NY 10019` | `117 W 57th St, New York, NY 10019` |
| `Phone: (212) 333-4333` | `(212) 333-4333` |
| `Website: angelospizzany.com` | `angelospizzany.com` |
| `Plus code: Q27C+XR New York` | `Q27C+XR New York` |
| `Hours Open · Closes 10 PM Show open hours for the week` | `Open · Closes 10 PM` |

**Strip prefix:** remove `Address:`, `Phone:`, `Website:`, `Plus code:` and leading whitespace.
**Clean hours:** remove trailing `Show open hours for the week`, `See more hours`, and trailing `·`.
