import Foundation
import SwiftData

enum DataExporter {
    static func exportAll(modelContext: ModelContext) throws -> Data {
        let links = try modelContext.fetch(FetchDescriptor<SavedLink>())
        let benefactors = try modelContext.fetch(FetchDescriptor<Benefactor>())
        let settings = try modelContext.fetch(FetchDescriptor<AppSetting>())
        let onboarding = try modelContext.fetch(FetchDescriptor<OnboardingProgress>()).first

        let export = SupportSystemExport(
            version: SupportSystemExport.currentVersion,
            exportedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            links: links.map { $0.toExport() },
            benefactors: benefactors.map { $0.toExport() },
            settings: settings.map { $0.toExport() },
            onboarding: onboarding?.toExport()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    static func exportURL(data: Data) throws -> URL {
        let fileName = "SupportSystem-Export-\(Date().formatted(.iso8601.year().month().day())).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)
        return tempURL
    }
}
