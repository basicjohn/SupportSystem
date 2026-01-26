# Support System - Mockup Review & Recommendations

## Current Mockups Analysis

Your existing mockups (`support-system-mockups.html`) are a solid foundation with beautiful iOS-native styling. However, some elements don't align with our simplified MVP architecture.

---

## Key Issues to Address

### 1. Tab Bar Structure

**Current:** 4 tabs (Home, Links, Merchants, Settings/Creators - inconsistent)

**Recommended for MVP:** 3 tabs
```
[Links]  [Benefactors]  [Settings]
```

**Why:**
- "Home" is unnecessary for MVP - Links tab can serve as the landing page
- "Merchants" and "Benefactors" are really the same thing in our model (merchant-centric benefactor assignment)
- Simpler = faster to build

---

### 2. Data Model Mismatch: Creator-Centric vs Merchant-Centric

**Current mockups show:** Benefactors as the primary entity
- "MKBHD - 8 codes across 5 merchants"
- Benefactor detail page showing all their codes
- Grid of benefactor avatars

**Our architecture:** Merchants as the primary entity
- Each merchant has ONE benefactor assigned
- User saves links → links grouped by merchant → user assigns benefactor to merchant
- Benefactor is just metadata on the merchant (creatorName + code)

**Recommended change:**
- Remove the standalone "Benefactors" list page
- Rename "Merchants" tab to "Benefactors" (since that's where you manage them)
- Each merchant card shows: domain, link count, assigned benefactor (or "Add")
- Tapping a merchant lets you add/edit the benefactor code

---

### 3. Simplify Stats (Remove V2+ Features)

**Current mockups show:**
- "Codes Applied" (requires purchase tracking - V2)
- "This Week: 8 with benefactor codes applied" (requires usage tracking - V2)

**MVP should show:**
- Links Saved (count)
- Merchants (count)
- With Codes / Without Codes (simple counts)

---

### 4. Settings - Remove V1+ Features

**Current mockups show:**
- "Auto-apply Codes" toggle (V1 - browser extension)
- "Default Browser" (not needed for web MVP)

**MVP Settings:**
- Theme (Light/Dark/System)
- Export Data
- Clear Data
- About/Version

---

### 5. Share Extension - Simplify

**Current mockups show:**
- "Choose Benefactor" when multiple exist (V1+ feature)

**MVP:** One benefactor per merchant, no choice needed
- If merchant has benefactor → show "Code ready"
- If no benefactor → show "No code set" with option to add

---

## Recommended Screen Structure (MVP)

### Tab 1: Links (Home/Landing)
```
┌──────────────────────────────┐
│ 🔗 Links                     │
├──────────────────────────────┤
│ [Paste a link...]            │
├──────────────────────────────┤
│ Quick Stats:                 │
│ 24 links · 8 merchants       │
│ 6 with codes · 2 need codes  │
├──────────────────────────────┤
│ ▼ amazon.com (5)        ✓    │
│   └── Sony headphones        │
│   └── USB-C cable            │
│                              │
│ ▼ bestbuy.com (2)       ✓    │
│   └── 4K Monitor             │
│                              │
│ ▼ nike.com (1)          ⚠    │
│   └── Running shoes          │
└──────────────────────────────┘
  [Links]  [Benefactors]  [⚙️]
```

### Tab 2: Benefactors (Merchant List)
```
┌──────────────────────────────┐
│ 👤 Benefactors               │
├──────────────────────────────┤
│ Merchants with your codes    │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ amazon.com          (5)  │ │
│ │ 👤 MKBHD · TECH20        │ │
│ │                    [Edit]│ │
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ bestbuy.com         (2)  │ │
│ │ 👤 LinusTech · LINUS15   │ │
│ │                    [Edit]│ │
│ └──────────────────────────┘ │
│                              │
│ ┌────────────────────────┐   │
│ │ nike.com           (1) │   │
│ │ ⚠ No benefactor set    │   │
│ │                 [+ Add]│   │
│ └────────────────────────┘   │
└──────────────────────────────┘
  [Links]  [Benefactors]  [⚙️]
```

### Tab 3: Settings
```
┌──────────────────────────────┐
│ ⚙️ Settings                  │
├──────────────────────────────┤
│ APPEARANCE                   │
│ ├── Theme         [System ▾] │
├──────────────────────────────┤
│ DATA                         │
│ ├── Export Data          [→] │
│ ├── Import Data          [→] │
│ ├── Clear All Data       [→] │
├──────────────────────────────┤
│ ABOUT                        │
│ ├── Version              1.0 │
│ ├── Privacy Policy       [→] │
│ └── Send Feedback        [→] │
└──────────────────────────────┘
  [Links]  [Benefactors]  [⚙️]
```

### Add/Edit Benefactor Sheet
```
┌──────────────────────────────┐
│ [Cancel]  Add Code   [Save]  │
├──────────────────────────────┤
│        🛒 amazon.com         │
│          5 links             │
├──────────────────────────────┤
│ Creator Name                 │
│ ┌──────────────────────────┐ │
│ │ MKBHD                    │ │
│ └──────────────────────────┘ │
│                              │
│ Code                         │
│ ┌──────────────────────────┐ │
│ │ TECH20                   │ │
│ └──────────────────────────┘ │
│                              │
│ Type                         │
│ [Affiliate ▾]                │
│                              │
│ Notes (optional)             │
│ ┌──────────────────────────┐ │
│ │ 20% off electronics      │ │
│ └──────────────────────────┘ │
│                              │
│ 💡 Find codes in creator's   │
│    video descriptions        │
└──────────────────────────────┘
```

---

## What to Keep From Current Mockups

✅ **Keep:**
- Overall iOS styling (beautiful!)
- Phone frame presentation
- Light/dark mode variations
- Onboarding flow (pages 1-3)
- Share extension (variations A, B, C)
- Empty states
- Link detail view
- Search bar styling
- Card styling
- Color scheme

❌ **Remove/Simplify:**
- Home dashboard (merge into Links tab)
- Benefactor list/grid (replace with merchant list)
- Benefactor detail page
- "Multiple benefactors" share extension
- Stats beyond simple counts
- V1+ settings

---

## Summary of Changes

| Screen | Action |
|--------|--------|
| **Tab Bar** | Change to 3 tabs: Links, Benefactors, Settings |
| **Home** | Remove - Links tab is home |
| **Links** | Add quick stats at top, grouped view is primary |
| **Merchants** | Rename to "Benefactors", keep merchant-centric |
| **Benefactors (old)** | Remove standalone benefactor management |
| **Settings** | Simplify, remove auto-apply toggle |
| **Share Extension** | Remove "multiple benefactors" variation |
| **Onboarding** | Keep as-is, minor copy tweaks |

---

## Next Steps

1. Update the HTML mockups with these changes
2. Or: Use these recommendations to build the actual React prototype
3. The existing mockups can serve as a style guide for colors/spacing/fonts
