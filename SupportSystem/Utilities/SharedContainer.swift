import SwiftData
import Foundation

enum SharedContainer {
    static let appGroupIdentifier = "group.com.supportsystem.app"

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            SavedLink.self,
            Benefactor.self,
            AppSetting.self,
            OnboardingProgress.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true
        )

        return try ModelContainer(for: schema, configurations: [config])
    }

    static var storeURL: URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            // Fallback to default location if App Group not configured
            // (e.g., running in Simulator without entitlements)
            let defaultURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return defaultURL.appendingPathComponent("SupportSystem.store")
        }
        return containerURL.appendingPathComponent("SupportSystem.store")
    }
}
