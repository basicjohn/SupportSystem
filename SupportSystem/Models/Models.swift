// =============================================================================
// SUPPORT SYSTEM - SwiftData Models
// =============================================================================
// Local-first data architecture for iOS 17+
// All data stored on-device, user owns their data
// =============================================================================

import Foundation
import SwiftData

// MARK: - Saved Link
/// A product URL the user has saved for later purchase
/// Displayed in: Links List, Link Detail View
@Model
final class SavedLink {
    // MARK: Identity
    /// Unique identifier (auto-generated)
    @Attribute(.unique) var id: UUID

    /// The full product URL
    var url: String

    /// SHA256 hash of normalized URL for deduplication
    @Attribute(.unique) var urlHash: String

    // MARK: Merchant Info (extracted from URL)
    /// Domain extracted from URL, e.g., "amazon.com"
    var merchantDomain: String

    /// Cached display name, e.g., "Amazon"
    var merchantDisplayName: String?

    // MARK: Product Metadata (fetched asynchronously)
    /// Product title, e.g., "Sony WH-1000XM5"
    var title: String?

    /// Product tagline/subtitle
    var subtitle: String?

    /// Full product description
    var productDescription: String?

    /// Product image URL
    var imageURL: String?

    /// Price at time of save
    var price: Decimal?

    /// Currency code, defaults to USD
    var priceCurrency: String

    /// Product category, e.g., "Electronics"
    var category: String?

    // MARK: Commission (cached from server for Est. Support calc)
    /// Merchant commission rate (percentage), e.g., 4.0 for 4%
    var commissionRate: Decimal?

    /// Estimated support amount (price * commissionRate / 100)
    var estimatedSupport: Decimal? {
        guard let price = price, let rate = commissionRate else { return nil }
        return price * rate / 100
    }

    // MARK: Benefactor Assignment
    /// The benefactor assigned to this link (optional)
    var benefactor: Benefactor?

    /// Was a code detected in the original shared URL?
    var benefactorDetected: Bool

    /// The code found in URL, if any
    var detectedCode: String?

    /// CodeType raw value of detected code
    var detectedCodeType: String?
    /// Where the code was found: "queryParam", "pathSegment"
    var detectedCodeSource: String?
    /// The URL param or path keyword the code was in
    var detectedCodeParam: String?

    // MARK: Status
    /// Current state: active, archived, or purchased
    var status: LinkStatus

    /// User wants price drop notifications
    var isPriceAlertEnabled: Bool

    /// Target price for alert
    var targetPrice: Decimal?

    // MARK: Timestamps
    var createdAt: Date
    var updatedAt: Date
    var viewedAt: Date?
    var archivedAt: Date?
    var purchasedAt: Date?

    // MARK: Initializer
    init(
        url: String,
        urlHash: String,
        merchantDomain: String,
        merchantDisplayName: String? = nil
    ) {
        self.id = UUID()
        self.url = url
        self.urlHash = urlHash
        self.merchantDomain = merchantDomain
        self.merchantDisplayName = merchantDisplayName
        self.priceCurrency = "USD"
        self.benefactorDetected = false
        self.status = .active
        self.isPriceAlertEnabled = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Link Status
enum LinkStatus: String, Codable, CaseIterable {
    /// Visible in main list
    case active
    /// Hidden but recoverable
    case archived
    /// User bought this item
    case purchased
}


// MARK: - Benefactor
/// A creator's affiliate/referral code assigned to a merchant
/// Displayed in: Benefactors Tab, Link Detail View
@Model
final class Benefactor {
    // MARK: Identity
    @Attribute(.unique) var id: UUID

    // MARK: Merchant
    /// The store domain this benefactor applies to, e.g., "amazon.com"
    var merchantDomain: String

    /// Cached display name, e.g., "Amazon"
    var merchantDisplayName: String?

    // MARK: Creator Info
    /// Creator display name, e.g., "MKBHD"
    var creatorName: String

    /// Optional avatar/profile image URL
    var creatorAvatarURL: String?

    // MARK: The Code
    /// The affiliate/referral code, e.g., "TECH20"
    var code: String

    /// Type of code
    var codeType: CodeType

    // MARK: User Notes
    /// Optional notes, e.g., "20% off first order"
    var notes: String?

    // MARK: Priority & Status
    /// Priority for multiple codes per merchant (1 = primary)
    var priority: Int

    /// User can disable without deleting
    var isActive: Bool

    /// false = using SupportSystem default
    var isUserDefined: Bool

    /// How the code was added
    var source: BenefactorSource

    // MARK: Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?

    // MARK: Relationships
    /// Links using this benefactor
    @Relationship(deleteRule: .nullify, inverse: \SavedLink.benefactor)
    var links: [SavedLink]?

    // MARK: Initializer
    init(
        merchantDomain: String,
        creatorName: String,
        code: String,
        codeType: CodeType = .affiliate,
        isUserDefined: Bool = true,
        source: BenefactorSource = .manual
    ) {
        self.id = UUID()
        self.merchantDomain = merchantDomain
        self.creatorName = creatorName
        self.code = code
        self.codeType = codeType
        self.priority = 1
        self.isActive = true
        self.isUserDefined = isUserDefined
        self.source = source
        self.createdAt = Date()
        self.updatedAt = Date()
        self.links = []
    }
}

// MARK: - Code Type
enum CodeType: String, Codable, CaseIterable {
    /// URL parameter (e.g., Amazon Associates tag)
    case affiliate
    /// Referral code/link
    case referral
    /// Discount/promo code
    case coupon
    /// Platform-specific code (e.g., Epic Games)
    case creatorCode = "creator_code"
}

// MARK: - Benefactor Source
enum BenefactorSource: String, Codable, CaseIterable {
    /// User typed it in manually
    case manual
    /// Extracted from a shared link URL
    case detected
    /// From data import
    case imported
    /// SupportSystem fallback
    case defaultFallback = "default_fallback"
}


// MARK: - App Settings
/// Key-value store for user preferences
/// Uses SwiftData for persistence, simple key-value pattern
@Model
final class AppSetting {
    @Attribute(.unique) var key: String
    var value: String
    var updatedAt: Date

    init(key: String, value: String) {
        self.key = key
        self.value = value
        self.updatedAt = Date()
    }
}

// MARK: - Settings Keys
/// Type-safe settings keys
enum SettingKey: String {
    case theme = "theme"
    case onboardingCompleted = "onboarding_completed"
    case useDefaultBenefactor = "use_default_benefactor"
    case deviceID = "device_id"
    case lastExportAt = "last_export_at"
    case lastImportAt = "last_import_at"
    case appVersion = "app_version"
}

// MARK: - Theme
enum AppTheme: String, Codable, CaseIterable {
    case system
    case light
    case dark
}


// MARK: - Onboarding Progress
/// Tracks the 3-step onboarding flow
@Model
final class OnboardingProgress {
    @Attribute(.unique) var id: Int // Always 1, single row

    /// 0 = not started, 1-3 = current step, 4 = complete
    var currentStep: Int

    var step1Completed: Bool // Welcome - Support Your Favorites
    var step2Completed: Bool // Save Links
    var step3Completed: Bool // Add Benefactors

    var completedAt: Date?
    var skipped: Bool

    init() {
        self.id = 1
        self.currentStep = 0
        self.step1Completed = false
        self.step2Completed = false
        self.step3Completed = false
        self.skipped = false
    }
}
