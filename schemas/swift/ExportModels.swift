// =============================================================================
// SUPPORT SYSTEM - Export/Import Data Models
// =============================================================================
// Codable structures for user data export and import
// Allows users to own and backup their data as JSON files
// =============================================================================

import Foundation

// MARK: - Export Container
/// Top-level container for full data export
/// User can save this as a JSON file they own
struct SupportSystemExport: Codable {
    /// Export format version for future compatibility
    let version: String

    /// When this export was created
    let exportedAt: Date

    /// App version that created this export
    let appVersion: String

    /// User's saved links
    let links: [LinkExport]

    /// User's benefactor assignments
    let benefactors: [BenefactorExport]

    /// User's app settings
    let settings: [SettingExport]

    /// Onboarding state
    let onboarding: OnboardingExport?

    enum CodingKeys: String, CodingKey {
        case version
        case exportedAt = "exported_at"
        case appVersion = "app_version"
        case links
        case benefactors
        case settings
        case onboarding
    }

    /// Current export format version
    static let currentVersion = "1.0"
}


// MARK: - Link Export
/// Exportable representation of a SavedLink
struct LinkExport: Codable, Identifiable {
    let id: String
    let url: String
    let merchantDomain: String
    let merchantDisplayName: String?

    // Product metadata
    let title: String?
    let subtitle: String?
    let description: String?
    let imageURL: String?
    let price: String?  // String to preserve decimal precision
    let priceCurrency: String
    let category: String?

    // Benefactor (just the ID reference)
    let benefactorID: String?
    let benefactorDetected: Bool
    let detectedCode: String?

    // Status
    let status: String
    let isPriceAlertEnabled: Bool
    let targetPrice: String?

    // Timestamps (ISO 8601)
    let createdAt: String
    let updatedAt: String
    let viewedAt: String?
    let archivedAt: String?
    let purchasedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, url
        case merchantDomain = "merchant_domain"
        case merchantDisplayName = "merchant_display_name"
        case title, subtitle, description
        case imageURL = "image_url"
        case price
        case priceCurrency = "price_currency"
        case category
        case benefactorID = "benefactor_id"
        case benefactorDetected = "benefactor_detected"
        case detectedCode = "detected_code"
        case status
        case isPriceAlertEnabled = "is_price_alert_enabled"
        case targetPrice = "target_price"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case viewedAt = "viewed_at"
        case archivedAt = "archived_at"
        case purchasedAt = "purchased_at"
    }
}


// MARK: - Benefactor Export
/// Exportable representation of a Benefactor
struct BenefactorExport: Codable, Identifiable {
    let id: String
    let merchantDomain: String
    let merchantDisplayName: String?
    let creatorName: String
    let creatorAvatarURL: String?
    let code: String
    let codeType: String
    let notes: String?
    let priority: Int
    let isActive: Bool
    let isUserDefined: Bool
    let source: String
    let createdAt: String
    let updatedAt: String
    let lastUsedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case merchantDomain = "merchant_domain"
        case merchantDisplayName = "merchant_display_name"
        case creatorName = "creator_name"
        case creatorAvatarURL = "creator_avatar_url"
        case code
        case codeType = "code_type"
        case notes
        case priority
        case isActive = "is_active"
        case isUserDefined = "is_user_defined"
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastUsedAt = "last_used_at"
    }
}


// MARK: - Setting Export
/// Exportable representation of an AppSetting
struct SettingExport: Codable {
    let key: String
    let value: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case key
        case value
        case updatedAt = "updated_at"
    }
}


// MARK: - Onboarding Export
/// Exportable representation of OnboardingProgress
struct OnboardingExport: Codable {
    let currentStep: Int
    let step1Completed: Bool
    let step2Completed: Bool
    let step3Completed: Bool
    let completedAt: String?
    let skipped: Bool

    enum CodingKeys: String, CodingKey {
        case currentStep = "current_step"
        case step1Completed = "step1_completed"
        case step2Completed = "step2_completed"
        case step3Completed = "step3_completed"
        case completedAt = "completed_at"
        case skipped
    }
}


// MARK: - Import Result
/// Result of importing data
struct ImportResult {
    let linksImported: Int
    let linksSkipped: Int  // Already existed
    let linksFailed: Int

    let benefactorsImported: Int
    let benefactorsSkipped: Int
    let benefactorsFailed: Int

    let settingsImported: Int

    var totalImported: Int {
        linksImported + benefactorsImported + settingsImported
    }

    var hasErrors: Bool {
        linksFailed > 0 || benefactorsFailed > 0
    }
}


// MARK: - Conversion Extensions

extension SavedLink {
    /// Convert to exportable format
    func toExport() -> LinkExport {
        let formatter = ISO8601DateFormatter()

        return LinkExport(
            id: id.uuidString,
            url: url,
            merchantDomain: merchantDomain,
            merchantDisplayName: merchantDisplayName,
            title: title,
            subtitle: subtitle,
            description: productDescription,
            imageURL: imageURL,
            price: price.map { "\($0)" },
            priceCurrency: priceCurrency,
            category: category,
            benefactorID: benefactor?.id.uuidString,
            benefactorDetected: benefactorDetected,
            detectedCode: detectedCode,
            status: status.rawValue,
            isPriceAlertEnabled: isPriceAlertEnabled,
            targetPrice: targetPrice.map { "\($0)" },
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt),
            viewedAt: viewedAt.map { formatter.string(from: $0) },
            archivedAt: archivedAt.map { formatter.string(from: $0) },
            purchasedAt: purchasedAt.map { formatter.string(from: $0) }
        )
    }
}

extension Benefactor {
    /// Convert to exportable format
    func toExport() -> BenefactorExport {
        let formatter = ISO8601DateFormatter()

        return BenefactorExport(
            id: id.uuidString,
            merchantDomain: merchantDomain,
            merchantDisplayName: merchantDisplayName,
            creatorName: creatorName,
            creatorAvatarURL: creatorAvatarURL,
            code: code,
            codeType: codeType.rawValue,
            notes: notes,
            priority: priority,
            isActive: isActive,
            isUserDefined: isUserDefined,
            source: source.rawValue,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt),
            lastUsedAt: lastUsedAt.map { formatter.string(from: $0) }
        )
    }
}

extension AppSetting {
    /// Convert to exportable format
    func toExport() -> SettingExport {
        let formatter = ISO8601DateFormatter()

        return SettingExport(
            key: key,
            value: value,
            updatedAt: formatter.string(from: updatedAt)
        )
    }
}

extension OnboardingProgress {
    /// Convert to exportable format
    func toExport() -> OnboardingExport {
        let formatter = ISO8601DateFormatter()

        return OnboardingExport(
            currentStep: currentStep,
            step1Completed: step1Completed,
            step2Completed: step2Completed,
            step3Completed: step3Completed,
            completedAt: completedAt.map { formatter.string(from: $0) },
            skipped: skipped
        )
    }
}
