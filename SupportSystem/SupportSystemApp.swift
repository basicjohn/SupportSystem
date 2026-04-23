import SwiftUI
import SwiftData

@main
struct SupportSystemApp: App {
    @State private var container: ModelContainer?
    @State private var loadError: Error?

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    ContentView()
                        .modelContainer(container)
                } else if let loadError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Unable to load data")
                            .font(.headline)
                        Text(loadError.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                }
            }
            .task {
                await createContainer()
            }
        }
    }

    private func createContainer() async {
        do {
            let newContainer = try SharedContainer.makeContainer()
            regenerateTaglines(in: newContainer)
            await MainActor.run {
                self.container = newContainer
            }
        } catch {
            await MainActor.run {
                self.loadError = error
            }
        }
    }

    /// One-time migration: replace scraped subtitles with generated taglines.
    private func regenerateTaglines(in container: ModelContainer) {
        let context = ModelContext(container)
        let migrationKey = "taglines_migrated_v1"

        let descriptor = FetchDescriptor<AppSetting>(
            predicate: #Predicate { $0.key == migrationKey }
        )
        if (try? context.fetch(descriptor))?.first != nil { return }

        let linksDescriptor = FetchDescriptor<SavedLink>()
        guard let links = try? context.fetch(linksDescriptor) else { return }

        for link in links {
            link.subtitle = TaglineGenerator.generateFallback(
                title: link.title,
                category: link.category,
                price: link.price,
                merchantDomain: link.merchantDomain,
                merchantName: link.merchantDisplayName
            )
        }

        context.insert(AppSetting(key: migrationKey, value: "true"))
        try? context.save()
    }
}
