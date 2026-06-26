# 从 `--json snapshot` + `snapshot` 提取数据

详情页需要 **两次** snapshot：

```bash
# JSON snapshot — 结构化 refs（address/phone/website/hours/category/claimed/socialLinks）
agent-browser --json snapshot

# Text snapshot — 树形 accessibility tree（rating 的 image）
agent-browser snapshot
```

---

## 列表页 — 从 JSON refs 提取商户卡片

搜索结果的商户卡片是 `role: "article"`：

```python
refs = json_snapshot["data"]["refs"]
articles = [
    {"ref": k, "name": v["name"]}
    for k, v in refs.items()
    if v.get("role") == "article"
]
# 例如：[{"ref": "e27", "name": "Yara Indonesia"}, ...]
```

**注意：** refs 中没有 href。通过 `click @linkRef` 进入详情页后，用 `agent-browser get url` 获取当前页面 URL。

**注意：** 每次页面重新加载后（包括返回搜索页再打开），ref IDs 会重新分配。处理下一个商户前必须重新执行 `--json snapshot` 获取新的 ref IDs。

---

## 详情页 — 字段提取

### A. 从 URL 解析商户名

Google Maps 详情页的 accessibility tree 中 `heading [level=1]` 经常为空，不可靠。商户名应从 URL 中解析：

```python
import re

def parse_name_from_url(url):
    """从 Google Maps place URL 中解析商户名
    例如: https://www.google.com/maps/place/Yara+Indonesia/@... → "Yara Indonesia"
    """
    match = re.search(r'/place/([^/@]+)', url)
    if match:
        name = match.group(1)
        # URL decode
        name = name.replace('+', ' ')
        name = name.replace('%20', ' ')
        name = name.replace('%26', '&')
        name = name.replace('%2C', ',')
        return name
    return ""
```

如果 URL 解析失败，回退到使用搜索结果中的商户名。

### B. 从文本 snapshot 提取 rating

```python
def extract_rating_from_text(text_snapshot):
    match = re.search(r'image "([\d.]+)\s*stars?\s*"', text_snapshot)
    if match:
        return match.group(1)
    return ""
```

### C. 从 JSON refs 提取其他字段

```python
def extract_fields_from_refs(refs_dict):
    """从 JSON snapshot 的 refs 中提取结构化字段"""
    refs = list(refs_dict.values())
    result = {}

    def strip_prefix(name, prefix):
        if not name.lower().startswith(prefix.lower()):
            return ""
        return name[len(prefix):].strip().lstrip(": ").strip()

    # address
    addr = next((r for r in refs
        if r.get("role") == "button" and r.get("name", "").startswith("Address:")), None)
    if addr:
        result["address"] = strip_prefix(addr["name"], "Address:")

    # phone
    phone = next((r for r in refs
        if r.get("role") == "button" and r.get("name", "").startswith("Phone:")), None)
    if phone:
        result["phone"] = strip_prefix(phone["name"], "Phone:")

    # website
    web = next((r for r in refs
        if r.get("role") == "link" and r.get("name", "").startswith("Website:")), None)
    if web:
        result["website"] = strip_prefix(web["name"], "Website:")

    # pluscode
    pc = next((r for r in refs
        if r.get("role") == "button" and r.get("name", "").startswith("Plus code:")), None)
    if pc:
        result["pluscode"] = strip_prefix(pc["name"], "Plus code:")

    # hours
    hrs = next((r for r in refs
        if r.get("role") == "button" and (
            r.get("name", "").startswith("Hours") or
            r.get("name", "").startswith("Open") or
            r.get("name", "").startswith("Closed")
        )), None)
    if hrs:
        result["hours"] = (hrs["name"]
            .replace("Hours ", "")
            .replace("Show open hours for the week", "")
            .replace("See more hours", "")
            .rstrip(" ·")
            .strip())

    # category — button，无已知前缀，不含冒号
    cat = next((r for r in refs
        if r.get("role") == "button" and r.get("name") and
        not r["name"].startswith("Address:") and
        not r["name"].startswith("Phone:") and
        not r["name"].startswith("Plus code:") and
        not r["name"].startswith("Hours") and
        not r["name"].startswith("Open") and
        not r["name"].startswith("Closed") and
        ":" not in r["name"]
    ), None)
    if cat:
        result["category"] = cat["name"]

    # claimed
    has_claim = any(
        "claim this business" in (r.get("name") or "").lower()
        for r in refs
    )
    result["claimed"] = "false" if has_claim else "true"

    # social links
    social_domains = ["facebook.com", "instagram.com", "linkedin.com",
                      "twitter.com", "x.com", "youtube.com", "tiktok.com"]
    socials = []
    for r in refs:
        if r.get("role") != "link":
            continue
        lower = (r.get("name") or "").lower()
        for domain in social_domains:
            if domain in lower:
                url = r.get("name", "")
                colon = url.find(":")
                if colon > 0:
                    url = url[colon + 1:].strip()
                if url and url not in socials:
                    socials.append(url)
                break
    if socials:
        result["socialLinks"] = "|".join(socials)

    return result
```

### 有效性检查

不是所有搜索结果都有独立的详情页。点击后需要检查 URL：

```python
def is_valid_merchant(url, extracted):
    """判断是否是有效的商户详情页"""
    if "/search/" in url:
        return False  # 没有导航到详情页
    if "/place/" not in url:
        return False  # 不是 place 页面
    # 城市/区域页面通常没有 address 和 phone
    if not extracted.get("address") and not extracted.get("phone"):
        return False
    return True
```

### 完整合并

```python
import json, re

# 1. click 进入详情页后，先获取 URL
place_url = run("agent-browser get url").strip()

# 2. 运行两次 snapshot
json_output = run("agent-browser --json snapshot")
text_output = run("agent-browser snapshot")

# 3. 解析 JSON
json_data = json.loads(json_output)
refs = json_data["data"]["refs"]

# 4. 提取所有字段
result = extract_fields_from_refs(refs)
result["name"] = parse_name_from_url(place_url) or merchant_name_from_search
result["rating"] = extract_rating_from_text(text_output)
result["maps"] = place_url
result["keyword"] = current_keyword

# 5. 有效性检查
if not is_valid_merchant(place_url, result):
    print("Skipped: not a valid merchant page")
    # 跳过，不加入结果

# result = {
#   "name": "Yara Indonesia",
#   "rating": "4.8",
#   "address": "South Quarter - Tower C...",
#   "phone": "+62 21 22722011",
#   "website": "yara.id",
#   "category": "Fertilizer supplier",
#   "claimed": "true",
#   ...
# }
```

---

## 输出格式

### JSON Lines

```jsonl
{"name":"Yara Indonesia","rating":"4.8","address":"South Quarter...","phone":"+62 21 22722011","website":"yara.id","pluscode":"PQ4M+6X...","hours":"Closed  Opens 8:30 AM","category":"Fertilizer supplier","claimed":"true","socialLinks":"","maps":"https://www.google.com/maps/place/Yara+Indonesia/...","keyword":"urea fertilizer importer Jakarta Indonesia"}
```

### CSV

```csv
name,rating,address,phone,website,pluscode,hours,category,claimed,socialLinks,maps,keyword
Yara Indonesia,4.8,"South Quarter, Tower C...",+62 21 22722011,yara.id,"PQ4M+6X...","Closed  Opens 8:30 AM",Fertilizer supplier,true,,https://.../Yara+Indonesia/,urea fertilizer importer Jakarta Indonesia
```
