# Support System - Development Plan

> Help users support their favorite creators through affiliate/referral codes

---

## Vision

**Support System** evolves through 4 stages:

| Stage | What it does |
|-------|--------------|
| **MVP** | Save links, organize by merchant, assign benefactor codes |
| **V1** | Browser extension auto-applies codes at checkout |
| **V2** | Scraped/community codes as fallbacks when user has no code set |
| **V3** | Creator dashboard - creators manage their own verified codes |

👉 See [DATA_ARCHITECTURE.md](./DATA_ARCHITECTURE.md) for full data model

---

## Core Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  User saves │ ──▶ │   Extract   │ ──▶ │ User assigns│ ──▶ │  Code used  │
│    link     │     │   domain    │     │  benefactor │     │ at checkout │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

**Future (V2):** If user has no benefactor set → fallback to community code

---

## MVP Scope

### Features
- [ ] Add links (paste URL or share sheet)
- [ ] Auto-extract domain/merchant
- [ ] View links grouped by merchant
- [ ] Delete/archive links
- [ ] Add benefactor code to merchant
- [ ] View benefactor when clicking link
- [ ] Local storage persistence

### Screens

```
┌─────────────────────────────────────────────────────┐
│                   SUPPORT SYSTEM                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  TAB 1: Links                                        │
│  ├── All saved links                                │
│  ├── Grouped by merchant/domain                     │
│  ├── Shows benefactor badge if assigned             │
│  └── Quick actions (open, delete)                   │
│                                                      │
│  TAB 2: Benefactors                                 │
│  ├── List of merchants (auto-populated from links) │
│  ├── Each merchant shows benefactor (if assigned)  │
│  ├── Link count per merchant                        │
│  └── Tap to add/edit benefactor code               │
│                                                      │
│  TAB 3: Settings                                    │
│  └── Basic preferences                              │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## MVP Data Model

```typescript
interface Link {
  id: string;
  url: string;
  domain: string;
  title?: string;
  createdAt: string;
  status: 'active' | 'archived';
}

interface Benefactor {
  id: string;
  merchantDomain: string;  // Key linking to merchant
  creatorName: string;     // "MKBHD"
  code: string;            // "MKBHD20"
  codeType: 'affiliate' | 'referral' | 'coupon';
  notes?: string;
}
```

**Reserved fields for future** (not in MVP, but designed in schema):
- `Link.purchasedAt`, `Link.codeUsed` → V2 purchase tracking
- `Benefactor.priority` → V1 multiple codes per merchant
- `Benefactor.creatorId` → V3 link to verified creator

---

## Tech Stack

### Prototype (Web App)
- **Framework**: React + TypeScript
- **Styling**: Tailwind CSS
- **Build**: Vite
- **Storage**: localStorage (Supabase later)

### Why Web First
- Fastest iteration cycle
- No app store approval needed
- Works everywhere (phone, desktop)
- Browser extension is natural V1 addition
- Can add native apps later if needed

---

## Sprint Plan

### Sprint 1: Link Management (3-4 days)
- [ ] Project setup (Vite + React + TS + Tailwind)
- [ ] URL input component (paste)
- [ ] Domain extraction utility
- [ ] Link list (grouped by domain)
- [ ] Local storage hook
- [ ] Add/delete links

### Sprint 2: Benefactor System (3-4 days)
- [ ] Merchant list view (derived from links)
- [ ] Benefactor form (add/edit)
- [ ] Display benefactor on merchant card
- [ ] Show reminder when opening link

### Sprint 3: Polish (2-3 days)
- [ ] Link metadata fetching (title, favicon)
- [ ] Search/filter links
- [ ] Empty states
- [ ] Responsive design
- [ ] Bookmarklet for easy link saving

---

## Future Roadmap

### V1: Browser Extension
- Chrome extension detects shopping sites
- Shows popup with benefactor code
- Option to auto-apply code at checkout
- Syncs with web app data
- **Requires:** `Merchant.codeInjectionPattern` in data model

### V2: Community Codes
- Scraping service finds creator codes from:
  - YouTube video descriptions
  - Podcast show notes
  - Creator websites & social bios
- Fallback when user has no code set
- Quality scoring (success rate, recency, verification)
- **Requires:** `CommunityCode` table

### V3: Creator Platform
- Creators claim and verify profiles
- Manage their own codes across merchants
- See supporter counts and analytics
- Direct relationship with supporters
- **Requires:** `CreatorProfile` table

---

## File Structure (Web Prototype)

```
support-system/
├── src/
│   ├── components/
│   │   ├── ui/                 # Shadcn/Tailwind primitives
│   │   ├── LinkInput.tsx       # URL paste input
│   │   ├── LinkCard.tsx        # Single link display
│   │   ├── LinkList.tsx        # Grouped link list
│   │   ├── MerchantCard.tsx    # Merchant with benefactor
│   │   ├── MerchantList.tsx    # All merchants view
│   │   ├── BenefactorForm.tsx  # Add/edit benefactor
│   │   └── BenefactorBadge.tsx # Code display chip
│   │
│   ├── hooks/
│   │   ├── useLinks.ts         # Link CRUD + storage
│   │   ├── useBenefactors.ts   # Benefactor CRUD + storage
│   │   └── useLocalStorage.ts  # Generic localStorage hook
│   │
│   ├── lib/
│   │   ├── types.ts            # TypeScript interfaces
│   │   ├── storage.ts          # localStorage abstraction
│   │   ├── url.ts              # URL parsing/normalization
│   │   └── utils.ts            # General utilities
│   │
│   ├── pages/
│   │   ├── LinksPage.tsx       # Tab 1: Links
│   │   ├── BenefactorsPage.tsx # Tab 2: Benefactors
│   │   └── SettingsPage.tsx    # Tab 3: Settings
│   │
│   ├── App.tsx                 # Router + tab navigation
│   └── main.tsx                # Entry point
│
├── public/
├── index.html
├── package.json
├── tailwind.config.js
├── tsconfig.json
└── vite.config.ts
```

---

## Key UI Mockups

### Links Tab
```
┌──────────────────────────────┐
│ 🔗 Links                     │
├──────────────────────────────┤
│ [+] Paste a link...          │
├──────────────────────────────┤
│                              │
│ ▼ amazon.com (5)        👤   │
│   ├── Sony headphones    ✕   │
│   ├── USB-C cable        ✕   │
│   └── + 3 more               │
│                              │
│ ▼ bestbuy.com (2)            │
│   ├── 4K Monitor         ✕   │
│   └── HDMI cable         ✕   │
│                              │
│ ▼ newegg.com (1)        👤   │
│   └── RAM kit            ✕   │
│                              │
└──────────────────────────────┘
  [Links]  [Benefactors]  [⚙️]
```

### Benefactors Tab
```
┌──────────────────────────────┐
│ 👤 Benefactors               │
├──────────────────────────────┤
│                              │
│ ┌──────────────────────────┐ │
│ │ 🛒 amazon.com       (5)  │ │
│ │ 👤 MKBHD                 │ │
│ │ Code: MKBHD20            │ │
│ │ Type: Affiliate    [Edit]│ │
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ 🏪 bestbuy.com      (2)  │ │
│ │ No benefactor set        │ │
│ │              [+ Add]     │ │
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ 💻 newegg.com       (1)  │ │
│ │ 👤 Linus Tech Tips       │ │
│ │ Code: LINUS              │ │
│ │ Type: Referral     [Edit]│ │
│ └──────────────────────────┘ │
│                              │
└──────────────────────────────┘
  [Links]  [Benefactors]  [⚙️]
```

### Add Benefactor Sheet
```
┌──────────────────────────────┐
│ Add Benefactor               │
│ for amazon.com               │
├──────────────────────────────┤
│                              │
│ Creator Name                 │
│ ┌──────────────────────────┐ │
│ │ MKBHD                    │ │
│ └──────────────────────────┘ │
│                              │
│ Code                         │
│ ┌──────────────────────────┐ │
│ │ MKBHD20                  │ │
│ └──────────────────────────┘ │
│                              │
│ Type                         │
│ (○) Affiliate                │
│ ( ) Referral                 │
│ ( ) Coupon                   │
│                              │
│ Notes (optional)             │
│ ┌──────────────────────────┐ │
│ │ 20% off first order      │ │
│ └──────────────────────────┘ │
│                              │
│ [Cancel]          [Save]     │
└──────────────────────────────┘
```

---

## Open Questions

1. **One or multiple benefactors per merchant?**
   - MVP: One benefactor per merchant (simpler)
   - V1+: Multiple with priority (fallbacks)

2. **Code application method?**
   - MVP: Just show/copy the code
   - V1: Browser extension auto-applies

3. **Cloud sync timing?**
   - MVP: localStorage only
   - Post-MVP: Supabase when needed

---

## Next Steps

1. ✅ Define data architecture
2. ⬜ Set up project scaffold
3. ⬜ Build Sprint 1 (Link Management)
4. ⬜ Build Sprint 2 (Benefactor System)
5. ⬜ Polish and iterate
