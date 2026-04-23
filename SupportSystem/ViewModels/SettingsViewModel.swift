import SwiftUI
import SwiftData

@Observable
final class SettingsViewModel {
    var showingExport = false
    var showingImport = false
    var showingClearConfirmation = false
    var showingThemePicker = false

    var currentTheme: AppTheme = .system

    func loadTheme(modelContext: ModelContext) {
        let key = SettingKey.theme.rawValue
        let descriptor = FetchDescriptor<AppSetting>(
            predicate: #Predicate { $0.key == key }
        )
        if let setting = try? modelContext.fetch(descriptor).first,
           let theme = AppTheme(rawValue: setting.value) {
            currentTheme = theme
        }
    }

    func setTheme(_ theme: AppTheme, modelContext: ModelContext) {
        currentTheme = theme

        let key = SettingKey.theme.rawValue
        let descriptor = FetchDescriptor<AppSetting>(
            predicate: #Predicate { $0.key == key }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.value = theme.rawValue
            existing.updatedAt = Date()
        } else {
            let setting = AppSetting(key: SettingKey.theme.rawValue, value: theme.rawValue)
            modelContext.insert(setting)
        }
        try? modelContext.save()
    }

    func clearAllData(modelContext: ModelContext) {
        try? modelContext.delete(model: SavedLink.self)
        try? modelContext.delete(model: Benefactor.self)
        try? modelContext.save()
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
