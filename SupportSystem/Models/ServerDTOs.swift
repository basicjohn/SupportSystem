// =============================================================================
// SUPPORT SYSTEM - Server API Data Transfer Objects
// =============================================================================
// Codable structs for communicating with the server API
// These do NOT get stored locally - just used for API requests/responses
// =============================================================================

import Foundation

// MARK: - Merchant (Server Response)
/// Merchant data fetched from server
/// Used for: Merchant lookup, logo/name resolution, code suggestions
struct MerchantDTO: Codable, Identifiable, Hashable {
    let id: String
    let domain: String
    let displayName: String
    let logoURL: String?
    let category: String?
    let alternateDomains: [String]?
    let isActive: Bool

    // Commission info for Est. Support calculation
    let commissionRate: Double?      // e.g., 4.0 for 4%
    let commissionType: String?      // "percentage", "flat", "tiered"

    enum CodingKeys: String, CodingKey {
        case id
        case domain
        case displayName = "display_name"
        case logoURL = "logo_url"
        case category
        case alternateDomains = "alternate_domains"
        case isActive = "is_active"
        case commissionRate = "commission_rate"
        case commissionType = "commission_type"
    }
}

// MARK: - Default Benefactor (Server Response)
/// SupportSystem's fallback affiliate codes
/// Fetched when user has no benefactor for a merchant
struct DefaultBenefactorDTO: Codable, Identifiable {
    let id: String
    let merchantID: String
    let code: String
    let codeType: String
    let label: String

    enum CodingKeys: String, CodingKey {
        case id
        case merchantID = "merchant_id"
        case code
        case codeType = "code_type"
        case label
    }
}

// MARK: - Popular Creator (Server Response)
/// Known creators for autocomplete/suggestions
struct PopularCreatorDTO: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String?
    let avatarURL: String?
    let isVerified: Bool
    let timesSelected: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case avatarURL = "avatar_url"
        case isVerified = "is_verified"
        case timesSelected = "times_selected"
    }
}

// MARK: - Creator Code (Server Response)
/// Known affiliate codes for creators by merchant
struct CreatorCodeDTO: Codable, Identifiable {
    let id: String
    let creatorID: String
    let creatorName: String
    let merchantID: String
    let merchantDomain: String
    let code: String
    let codeType: String
    let isVerified: Bool
    let successRate: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case creatorID = "creator_id"
        case creatorName = "creator_name"
        case merchantID = "merchant_id"
        case merchantDomain = "merchant_domain"
        case code
        case codeType = "code_type"
        case isVerified = "is_verified"
        case successRate = "success_rate"
    }
}


// MARK: - API Request Bodies

/// Request to look up merchant by domain
struct MerchantLookupRequest: Codable {
    let domain: String
}

/// Request to search creators for autocomplete
struct CreatorSearchRequest: Codable {
    let query: String
    let merchantDomain: String?
    let limit: Int

    enum CodingKeys: String, CodingKey {
        case query
        case merchantDomain = "merchant_domain"
        case limit
    }
}

/// Request to get creator codes for a merchant
struct CreatorCodesRequest: Codable {
    let merchantDomain: String
    let creatorName: String?

    enum CodingKeys: String, CodingKey {
        case merchantDomain = "merchant_domain"
        case creatorName = "creator_name"
    }
}


// MARK: - Analytics Events (Privacy-Preserving)

/// Anonymous event sent to server for product analytics
/// Contains NO personally identifiable information
struct AnalyticsEventDTO: Codable {
    let eventType: String
    let eventData: [String: String]?
    let deviceHash: String       // SHA256 of device ID
    let sessionID: String
    let merchantDomain: String?  // Only domain, not full URL
    let appVersion: String
    let platform: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case eventData = "event_data"
        case deviceHash = "device_hash"
        case sessionID = "session_id"
        case merchantDomain = "merchant_domain"
        case appVersion = "app_version"
        case platform
        case timestamp
    }
}

/// Event types for analytics
enum AnalyticsEventType: String, Codable {
    // Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingStepCompleted = "onboarding_step_completed"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"

    // Links (only counts, no URLs or product info)
    case linkSaved = "link_saved"
    case linkViewed = "link_viewed"
    case linkOpenedExternal = "link_opened_external"
    case linkArchived = "link_archived"
    case linkPurchased = "link_purchased"

    // Benefactors (no code values sent)
    case benefactorAdded = "benefactor_added"
    case benefactorChanged = "benefactor_changed"
    case benefactorCodeCopied = "benefactor_code_copied"

    // App lifecycle
    case appOpened = "app_opened"
    case shareExtensionUsed = "share_extension_used"

    // Settings
    case themeChanged = "theme_changed"
    case dataExported = "data_exported"
    case dataImported = "data_imported"
}


// MARK: - API Responses

/// Generic API response wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIError?
}

/// API error details
struct APIError: Codable, Error {
    let code: String
    let message: String
}

/// Paginated response for lists
struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case items
        case total
        case page
        case pageSize = "page_size"
        case hasMore = "has_more"
    }
}
