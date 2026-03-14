# Design Sizes Quick Reference

> Look up sizes by project type. All values are CSS pixels (logical pixels), not physical pixels.

---

## 1. Web Page Design

### 1.1 Design Canvas Sizes (Figma / Design Files)

| Type | Recommended Canvas Width | Content Area max-width | Notes |
|------|--------------------------|------------------------|-------|
| **Desktop** | 1440px | 1200px (centered) | Most common design file width |
| **Desktop (Large Screen)** | 1920px | 1200-1280px | More side margins |
| **Laptop** | 1366px | 1140px | World's second most common resolution |
| **Tablet Landscape** | 1024px | 960px | iPad Pro |
| **Tablet Portrait** | 768px | 720px | iPad |
| **Mobile** | 375px | 375px (full width) | iPhone SE / older model baseline |
| **Mobile (Mainstream)** | 390px | 390px | iPhone 15 / mainstream Android |
| **Mobile (Large Screen)** | 430px | 430px | iPhone 15 Pro Max |

**Practical Tip:** Design at 1440px wide, content area 1200px centered, 120px on each side. One file covers the vast majority of desktop screens.

### 1.2 Responsive Breakpoints

| Breakpoint | Tailwind | Bootstrap | Devices Covered |
|------------|----------|-----------|-----------------|
| **sm** | 640px | 576px | Large phone landscape |
| **md** | 768px | 768px | Tablet portrait |
| **lg** | 1024px | 992px | Tablet landscape / small laptop |
| **xl** | 1280px | 1200px | Standard desktop |
| **2xl** | 1536px | 1400px | Large desktop |

**Mobile-first:** Write small-screen styles first, scale up with `@media (min-width)`.

### 1.3 Common Device CSS Viewports

**Mobile (Portrait)**
| Device | Viewport (CSS px) |
|--------|-------------------|
| iPhone SE | 375 × 667 |
| iPhone 14/15 | 393 × 852 |
| iPhone 15 Pro Max | 430 × 932 |
| Samsung Galaxy S24 | 360 × 780 |
| Pixel 8 | 412 × 915 |
| Xiaomi/OPPO Mainstream | 360-412 × 800-915 |

**Tablet**
| Device | Viewport |
|--------|----------|
| iPad (10th gen) | 810 × 1080 |
| iPad Air | 820 × 1180 |
| iPad Pro 11" | 834 × 1194 |
| iPad Pro 12.9" | 1024 × 1366 |
| Android Tablet | 800 × 1280 |

**Desktop (Common Resolutions)**
| Resolution | Global Market Share |
|------------|---------------------|
| 1920 × 1080 | ~22% |
| 1366 × 768 | ~12% |
| 1536 × 864 | ~9% |
| 1440 × 900 | ~6% |
| 2560 × 1440 | ~5% |

---

## 2. Size Guide by Project Type

### 2.1 Landing Page / Marketing Page

```
Design canvas:      1440 × tall page (no height limit)
Content area:       max-width 1200px, centered
Hero area:          full width, height 600-800px (80-100vh)
Section spacing:    80-120px
Side safe zone:     content ≥ 120px from canvas edge (desktop), 24px (mobile)
```

### 2.2 Dashboard / Admin Panel

```
Design canvas:      1440 × 900 (or 1920 × 1080)
Sidebar width:      240-280px (expanded) / 64-80px (collapsed)
Topbar height:      56-64px
Content area:       100% - sidebar width
Card spacing:       16-24px (gap)
Table row height:   48-56px
Minimum column width: 120px
```

### 2.3 Single-Screen Pages (Login / Register / 404)

```
Desktop:            centered card 400-480px wide, vertically centered
Mobile:             full width, padding 24px
Form input height:  40-48px
Button height:      40-48px
Form item spacing:  16-20px
```

### 2.4 Mobile App Pages

```
Design canvas:      390 × 844 (iPhone 15 baseline)
Or:                 375 × 812 (compatible with older devices)
Status bar height:  iOS 59px / Android 24dp
Navigation bar height: 44-56px
Bottom tab bar height: 49-83px (including safe area)
Bottom safe area:   iOS 34px (with Home Indicator)
Minimum touch target: 44 × 44pt (Apple) / 48 × 48dp (Material)
Content padding:    16px left/right
```

### 2.5 WeChat Mini Program

```
Design canvas:      375 × 812 (iPhone X baseline)
Or:                 750 × 1624 (@2x)
Navigation bar:     system custom 88rpx (including status bar)
Tabbar height:      98rpx
Bottom safe area:   68rpx
Base font size:     28rpx (≈14px)
```

### 2.6 Email Template

```
Email width:        600px (standard) / max 700-800px
Banner height:      200-350px
Mobile width:       adaptive, minimum 320px
Images:             JPG (photos) / PNG (logo/transparent)
Total email length: 1500-2000px (avoid being too long)
CTA button:         minimum 44px tall, 120px wide
```

### 2.7 Poster / Print Design

```
A4 (print):         210 × 297mm → 2480 × 3508px @300dpi
A3:                 297 × 420mm → 3508 × 4961px @300dpi
Business card:      90 × 54mm → 1063 × 638px @300dpi
Banner (exhibition): based on physical size, at least 150dpi
Web poster:         1200 × 1600px or 1080 × 1920px (portrait)
```

### 2.8 Social Media Images

**Common Ratios**
| Ratio | Use Case |
|-------|----------|
| 1:1 (Square) | Feed posts, avatars |
| 4:5 (Portrait) | Best for Instagram / Xiaohongshu Feed |
| 16:9 (Landscape) | YouTube cover / thumbnails, website banners |
| 9:16 (Vertical) | Stories / Reels / short video |

**Platform-Specific Sizes**
| Platform | Type | Size (px) |
|----------|------|-----------|
| **WeChat Official Account** | Cover image (large) | 900 × 383 (2.35:1) |
| | Cover image (small) | 500 × 500 (1:1) |
| | Article image | Width ≥ 900 |
| **Xiaohongshu** | Feed image | 1080 × 1440 (3:4) |
| | Cover image | 1080 × 1440 |
| **Douyin / TikTok** | Video / Cover | 1080 × 1920 (9:16) |
| **Instagram** | Square post | 1080 × 1080 |
| | Portrait post | 1080 × 1350 (4:5) |
| | Stories / Reels | 1080 × 1920 (9:16) |
| **Twitter / X** | Post image | 1200 × 675 (16:9) |
| | Banner | 1500 × 500 |
| **LinkedIn** | Post image | 1200 × 627 |
| | Banner | 1584 × 396 |
| **YouTube** | Thumbnail | 1280 × 720 (16:9) |
| | Channel Banner | 2560 × 1440 |
| **Facebook** | Post image | 1200 × 630 |
| | Cover | 820 × 312 |

### 2.9 App Icon

| Platform | Size | Notes |
|----------|------|-------|
| iOS App Icon | 1024 × 1024px | System auto-scales after submission |
| Android (Adaptive) | 108 × 108dp (432×432px @4x) | Foreground 72dp, background 108dp |
| macOS | 1024 × 1024px | |
| Favicon | 32 × 32 + 16 × 16 | Also need 180×180 (apple-touch-icon) |
| PWA Icon | 512 × 512 | manifest.json |

### 2.10 OG Share Image (Open Graph)

```
Recommended:        1200 × 630px (1.91:1)
Minimum:            600 × 315px
Twitter Card:       1200 × 600px (2:1)
WeChat Share:       500 × 500 (1:1) or 900 × 500
```

---

## 3. Typography Size Quick Reference

### 3.1 Web Font Sizes

| Element | Desktop | Mobile | Line Height |
|---------|---------|--------|-------------|
| H1 | 48-64px | 32-40px | 1.1-1.2 |
| H2 | 32-40px | 24-30px | 1.2-1.3 |
| H3 | 24-28px | 20-24px | 1.2-1.3 |
| Body text | 16px | 16px (don't shrink!) | 1.5-1.6 |
| Secondary text | 14px | 14px | 1.4-1.5 |
| Caption | 12-13px | 12px | 1.4 |
| Button | 14-16px | 14-16px | 1 |

**CJK body line height 1.6-1.8, headings 1.3-1.4.**

### 3.2 Spacing System

```
4px  — icon and text
8px  — tight elements (label↔input)
12px — between list items
16px — between paragraphs, inside cards
24px — between modules
32px — large blocks
48px — section internal padding
64px — between sections (mobile)
80-96px — between sections (desktop)
120px — hero / footer generous whitespace
```

### 3.3 Component Size Reference

| Component | Height | Notes |
|-----------|--------|-------|
| Navigation bar (Desktop) | 56-64px | |
| Navigation bar (Mobile) | 48-56px | |
| Input field | 40-48px | Apple minimum 44pt |
| Button (Large) | 44-48px | |
| Button (Medium) | 36-40px | |
| Button (Small) | 28-32px | |
| Avatar (Small) | 32px | |
| Avatar (Medium) | 40-48px | |
| Avatar (Large) | 64-96px | |
| Badge | 20-24px | |
| Table row | 48-56px | |
| Sidebar (Expanded) | 240-280px wide | |
| Sidebar (Collapsed) | 64-80px wide | |
| Modal (Small) | 400px wide | |
| Modal (Medium) | 600px wide | |
| Modal (Large) | 800px wide | |
| Toast | 360px wide, 48-64px tall | |

### 3.4 Minimum Touch Target

| Platform | Minimum Size | Notes |
|----------|--------------|-------|
| Apple (iOS) | 44 × 44pt | HIG required |
| Material (Android) | 48 × 48dp | Recommended, minimum 24dp icon + padding |
| Web (WCAG) | 24 × 24px (minimum) / 44 × 44px (recommended) | WCAG 2.5.8 |

---

## 4. Content Width and Readability

| Rule | Value |
|------|-------|
| Optimal English body line length | 45-75 characters (≈ 65ch) |
| Optimal CJK body line length | 25-35 characters |
| Recommended max-width | `65ch` or `680px` |
| Large screen content container | max-width 1200px, margin: 0 auto |
| Extra-large screen (>1600px) | Consider multi-column layout or limit to 1400px |
