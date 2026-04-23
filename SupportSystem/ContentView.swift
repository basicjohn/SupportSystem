import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var onboardingProgress: [OnboardingProgress]
    @Query private var settings: [AppSetting]

    @State private var selectedTab: AppTab = .links

    private var isOnboardingComplete: Bool {
        guard let progress = onboardingProgress.first else { return false }
        return progress.currentStep >= 4 || progress.skipped
    }

    private var preferredColorScheme: ColorScheme? {
        guard let themeSetting = settings.first(where: { $0.key == SettingKey.theme.rawValue }),
              let theme = AppTheme(rawValue: themeSetting.value) else {
            return nil
        }
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var body: some View {
        Group {
            if isOnboardingComplete {
                TabView(selection: $selectedTab) {
                    Tab("Links", systemImage: "link", value: .links) {
                        LinksTabView()
                    }
                    Tab("Benefactors", systemImage: "chart.line.uptrend.xyaxis", value: .benefactors) {
                        BenefactorsTabView()
                    }
                    Tab("Settings", systemImage: "gearshape", value: .settings) {
                        SettingsTabView()
                    }
                }
            } else {
                OnboardingContainerView()
            }
        }
        .tint(Color(.label))
        .preferredColorScheme(preferredColorScheme)
    }
}

enum AppTab: Hashable {
    case links
    case benefactors
    case settings
}
