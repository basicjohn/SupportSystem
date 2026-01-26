# Support System - Data Architecture

> Future-proof data model supporting MVP through full platform evolution

---

## Evolution Stages

| Stage | Description | Key Features |
|-------|-------------|--------------|
| **MVP** | Personal link organizer | Save links, assign benefactors to merchants |
| **V1** | Browser extension | Auto-apply codes at checkout |
| **V2** | Community codes | Scraped/crowdsourced fallback codes |
| **V3** | Creator platform | Creator dashboards, verified profiles |

---

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SUPPORT SYSTEM DATA MODEL                          │
└─────────────────────────────────────────────────────────────────────────────┘

                                    ┌──────────────┐
                                    │    User      │
                                    │──────────────│
                                    │ id           │
                                    │ email        │
                                    │ createdAt    │
                                    └──────┬───────┘
                                           │
                       ┌───────────────────┼───────────────────┐
                       │                   │                   │
                       ▼                   ▼                   ▼
              ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
              │  SavedLink   │    │ UserCode     │    │ CreatorProfile│
              │──────────────│    │ (Benefactor) │    │ (Future V3)  │
              │ id           │    │──────────────│    │──────────────│
              │ userId       │    │ id           │    │ id           │
              │ url          │    │ userId       │    │ userId       │
              │ merchantId   │    │ merchantId   │    │ displayName  │
              │ title        │    │ creatorId*   │    │ verified     │
              │ status       │    │ code         │    │ avatarUrl    │
              └──────┬───────┘    │ priority     │    │ bio          │
                     │            └──────┬───────┘    └──────────────┘
                     │                   │
                     ▼                   ▼
              ┌─────────────────────────────────────┐
              │              Merchant               │
              │─────────────────────────────────────│
              │ id                                  │
              │ domain (unique)                     │
              │ displayName                         │
              │ logoUrl                             │
              │ affiliateNetwork*                   │
              │ codeInjectionPattern*               │
              └─────────────────────────────────────┘
                                 │
                                 ▼
              ┌─────────────────────────────────────┐
              │          CommunityCode              │
              │        (Future V2 - Scraped)        │
              │─────────────────────────────────────│
              │ id                                  │
              │ merchantId                          │
              │ code                                │
              │ creatorName                         │
              │ source (scraped | submitted)        │
              │ lastVerified                        │
              │ useCount                            │
              │ successRate                         │
              └─────────────────────────────────────┘
```

---

## Core Entities

### 1. User
The person using the app.

```typescript
interface User {
  // Identity
  id: string;                    // UUID
  email: string;                 // Unique

  // Profile
  displayName?: string;
  avatarUrl?: string;

  // Settings
  preferences: UserPreferences;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
  lastActiveAt?: Date;

  // Future: Creator features
  isCreator?: boolean;           // V3: Has a creator profile
  creatorProfileId?: string;     // V3: Link to CreatorProfile
}

interface UserPreferences {
  defaultCodePriority: 'user' | 'community';  // Which code to prefer
  autoApplyEnabled: boolean;                   // V1: Browser extension setting
  notificationsEnabled: boolean;
}
```

**MVP:** Can be anonymous (just a local ID)
**V1+:** Email-based accounts for sync

---

### 2. Merchant
A store/website where codes can be used.

```typescript
interface Merchant {
  // Identity
  id: string;                    // UUID
  domain: string;                // Unique, e.g., "amazon.com"

  // Display
  displayName: string;           // e.g., "Amazon"
  logoUrl?: string;              // Favicon or logo
  category?: string;             // e.g., "Electronics", "Fashion"

  // Code application (V1+)
  affiliateNetwork?: AffiliateNetwork;
  codeInjectionPattern?: CodeInjectionPattern;

  // Metadata
  isActive: boolean;             // Can we apply codes here?
  lastScrapedAt?: Date;          // V2: When we last found codes

  // Stats (computed)
  totalCodes?: number;           // How many community codes exist
  activeUsers?: number;          // How many users have links here

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
}

// V1+: How to apply codes at checkout
interface CodeInjectionPattern {
  type: 'url_param' | 'cookie' | 'form_field' | 'manual';

  // For url_param type
  paramName?: string;            // e.g., "ref", "tag", "code"
  paramPosition?: 'query' | 'path';

  // For cookie type
  cookieName?: string;
  cookieDomain?: string;

  // For form_field type
  formSelector?: string;         // CSS selector for promo code input
  submitSelector?: string;       // CSS selector for apply button

  // Instructions for manual
  instructions?: string;         // "Enter code at checkout"
}

type AffiliateNetwork =
  | 'amazon_associates'
  | 'shareasale'
  | 'cj_affiliate'
  | 'rakuten'
  | 'impact'
  | 'partnerize'
  | 'awin'
  | 'custom'
  | 'unknown';
```

**MVP:** Just domain + displayName
**V1:** Add injection patterns for browser extension
**V2:** Add scraping metadata

---

### 3. SavedLink
A URL the user has saved.

```typescript
interface SavedLink {
  // Identity
  id: string;                    // UUID
  userId: string;                // Owner

  // Link data
  url: string;                   // Full URL
  urlHash: string;               // SHA256 of normalized URL (for dedup)
  merchantId: string;            // Extracted from domain

  // Metadata (fetched async)
  title?: string;
  description?: string;
  imageUrl?: string;
  faviconUrl?: string;

  // User data
  note?: string;                 // User's personal note
  tags?: string[];               // Future: User tags

  // Status tracking
  status: LinkStatus;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
  viewedAt?: Date;
  archivedAt?: Date;

  // Future: Purchase tracking (V2+)
  purchasedAt?: Date;
  purchaseAmount?: number;
  codeUsed?: string;             // Which code was applied
}

type LinkStatus =
  | 'active'                     // In the list
  | 'archived'                   // Soft deleted
  | 'purchased';                 // User bought this (future)
```

**MVP:** Basic link storage
**V2+:** Purchase tracking for analytics

---

### 4. UserCode (Benefactor Assignment)
A user's chosen code for a specific merchant. This is the "benefactor" concept.

```typescript
interface UserCode {
  // Identity
  id: string;                    // UUID
  userId: string;                // Owner
  merchantId: string;            // Which store

  // The benefactor
  creatorName: string;           // e.g., "MKBHD", "Linus Tech Tips"
  creatorId?: string;            // V3: Link to verified CreatorProfile

  // The code
  code: string;                  // The actual code/tag
  codeType: CodeType;

  // Application
  priority: number;              // 1 = primary, 2+ = fallbacks
  isActive: boolean;             // User can disable without deleting

  // User notes
  notes?: string;                // "Use at checkout", "20% off"

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
  lastUsedAt?: Date;

  // Future: Stats (V2+)
  useCount?: number;
  estimatedSupport?: number;     // $ sent to creator
}

type CodeType =
  | 'affiliate'                  // Tag added to URL (e.g., Amazon tag)
  | 'referral'                   // Referral link/code
  | 'coupon'                     // Promo/discount code
  | 'creator_code';              // In-game or platform-specific
```

**MVP:** One code per merchant per user
**V1+:** Multiple codes with priority (fallbacks)

---

### 5. CommunityCode (Future V2)
Codes discovered through scraping or community submission.

```typescript
interface CommunityCode {
  // Identity
  id: string;                    // UUID
  merchantId: string;            // Which store

  // The code
  code: string;
  codeType: CodeType;

  // Attribution
  creatorName: string;           // Who this supports
  creatorId?: string;            // V3: Verified creator link

  // Source
  source: CodeSource;
  sourceUrl?: string;            // Where we found it
  submittedBy?: string;          // UserId if community submitted

  // Verification
  status: CodeStatus;
  lastVerifiedAt?: Date;
  verificationMethod?: 'manual' | 'automated' | 'community';

  // Quality signals
  useCount: number;              // Times applied
  successCount: number;          // Times confirmed working
  successRate: number;           // Computed: success/use
  reportCount: number;           // Times reported broken

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
  expiresAt?: Date;              // Some codes expire
}

type CodeSource =
  | 'scraped_youtube'            // Found in YouTube description
  | 'scraped_podcast'            // Found in podcast notes
  | 'scraped_website'            // Found on creator's website
  | 'scraped_social'             // Found on social media
  | 'community_submitted'        // User submitted
  | 'creator_verified';          // V3: Creator added directly

type CodeStatus =
  | 'active'                     // Working
  | 'unverified'                 // Not yet tested
  | 'expired'                    // Known expired
  | 'reported'                   // Multiple reports of not working
  | 'disabled';                  // Manually disabled
```

**V2:** Populated by scraping service
**V3:** Creators can verify their own codes

---

### 6. CreatorProfile (Future V3)
Verified creator accounts who can manage their codes.

```typescript
interface CreatorProfile {
  // Identity
  id: string;                    // UUID
  userId: string;                // Link to User account

  // Profile
  displayName: string;           // Public name
  slug: string;                  // URL-friendly: "mkbhd"
  bio?: string;
  avatarUrl?: string;
  bannerUrl?: string;

  // Verification
  isVerified: boolean;
  verifiedAt?: Date;
  verificationMethod?: 'manual' | 'social_link' | 'domain';

  // Social links (for verification & display)
  links: {
    youtube?: string;
    twitter?: string;
    instagram?: string;
    tiktok?: string;
    website?: string;
    podcast?: string;
  };

  // Stats (computed)
  totalSupporters?: number;      // Users with their codes set
  totalMerchants?: number;       // Merchants they have codes for

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
}
```

**V3:** Full creator economy features

---

## Code Resolution Logic

When a user visits a merchant, which code should be applied?

```typescript
interface CodeResolution {
  merchantId: string;

  // Priority order (configurable per user)
  resolution: [
    'user_primary',      // User's #1 choice for this merchant
    'user_fallback',     // User's backup codes
    'community_best',    // Highest success rate community code
    'community_recent',  // Most recently verified
    'none'               // No code available
  ];

  // The selected code
  selectedCode?: {
    code: string;
    source: 'user' | 'community';
    creatorName: string;
    confidence: number;  // 0-1 based on verification
  };
}
```

---

## MVP Data Model (Simplified)

For the prototype, we only need these fields:

```typescript
// MVP Types - localStorage version

interface Link {
  id: string;
  url: string;
  domain: string;        // Extracted from URL
  title?: string;
  createdAt: string;     // ISO date
  status: 'active' | 'archived';
}

interface Merchant {
  domain: string;        // Primary key
  displayName: string;
  linkCount: number;     // Computed
}

interface Benefactor {
  id: string;
  merchantDomain: string;
  creatorName: string;
  code: string;
  codeType: 'affiliate' | 'referral' | 'coupon';
  notes?: string;
}

// localStorage schema
interface AppState {
  links: Link[];
  benefactors: Benefactor[];
  // Merchants are computed from links
}
```

---

## Database Schema (Supabase - Future)

```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  display_name TEXT,
  preferences JSONB DEFAULT '{}',
  is_creator BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Merchants (shared across all users)
CREATE TABLE merchants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  domain TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  logo_url TEXT,
  category TEXT,
  affiliate_network TEXT,
  code_injection_pattern JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_merchants_domain ON merchants(domain);

-- User's saved links
CREATE TABLE saved_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  merchant_id UUID REFERENCES merchants(id),
  url TEXT NOT NULL,
  url_hash TEXT NOT NULL,
  title TEXT,
  description TEXT,
  image_url TEXT,
  note TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  viewed_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ,

  UNIQUE(user_id, url_hash)
);

CREATE INDEX idx_links_user ON saved_links(user_id);
CREATE INDEX idx_links_merchant ON saved_links(merchant_id);
CREATE INDEX idx_links_status ON saved_links(status);

-- User's benefactor codes
CREATE TABLE user_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  merchant_id UUID REFERENCES merchants(id),
  creator_name TEXT NOT NULL,
  creator_id UUID,  -- Future: FK to creator_profiles
  code TEXT NOT NULL,
  code_type TEXT NOT NULL,
  priority INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,

  UNIQUE(user_id, merchant_id, code)
);

CREATE INDEX idx_user_codes_user ON user_codes(user_id);
CREATE INDEX idx_user_codes_merchant ON user_codes(merchant_id);

-- Community codes (V2)
CREATE TABLE community_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID REFERENCES merchants(id),
  code TEXT NOT NULL,
  code_type TEXT NOT NULL,
  creator_name TEXT NOT NULL,
  creator_id UUID,
  source TEXT NOT NULL,
  source_url TEXT,
  submitted_by UUID REFERENCES users(id),
  status TEXT DEFAULT 'unverified',
  last_verified_at TIMESTAMPTZ,
  use_count INTEGER DEFAULT 0,
  success_count INTEGER DEFAULT 0,
  report_count INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(merchant_id, code)
);

CREATE INDEX idx_community_codes_merchant ON community_codes(merchant_id);
CREATE INDEX idx_community_codes_status ON community_codes(status);

-- Creator profiles (V3)
CREATE TABLE creator_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  display_name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  banner_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  social_links JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_creator_profiles_slug ON creator_profiles(slug);
```

---

## Migration Path

### MVP → V1 (Browser Extension)
- Add `code_injection_pattern` to merchants
- No schema changes needed for user data

### V1 → V2 (Community Codes)
- Add `community_codes` table
- Add scraping service to populate codes
- Add `preferences.defaultCodePriority` to users

### V2 → V3 (Creator Platform)
- Add `creator_profiles` table
- Add `creator_id` FK to `user_codes` and `community_codes`
- Add `is_creator` flag to users

---

## Key Design Decisions

1. **Merchant is shared, codes are per-user**
   - Merchants table is global (one Amazon entry)
   - UserCodes table links users to their chosen benefactors

2. **Support multiple codes per merchant**
   - `priority` field allows fallback codes
   - User can have MKBHD as primary, LTT as backup

3. **Community codes are separate from user codes**
   - User codes = explicit user choice
   - Community codes = discovered/scraped fallbacks
   - Clear separation for trust/quality

4. **Creator profiles are optional layer**
   - Works without verified creators
   - Verification adds trust signals later

5. **URL hash for deduplication**
   - Normalized URL → SHA256 hash
   - Prevents duplicate links efficiently
