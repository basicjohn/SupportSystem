import SwiftUI
import SwiftData

@MainActor
@Observable
final class LinkDetailViewModel {
    var showingMenu = false

    func openInSafari(link: SavedLink) {
        guard let url = URL(string: link.url) else { return }
        link.viewedAt = Date()
        UIApplication.shared.open(url)
    }

    func copyLink(_ link: SavedLink) {
        UIPasteboard.general.string = link.url
    }

    func copyCode(_ benefactor: Benefactor) {
        UIPasteboard.general.string = benefactor.code
        benefactor.lastUsedAt = Date()
    }

    func markAsPurchased(_ link: SavedLink, modelContext: ModelContext) {
        link.status = .purchased
        link.purchasedAt = Date()
        link.updatedAt = Date()
        try? modelContext.save()
    }

    func archiveLink(_ link: SavedLink, modelContext: ModelContext) {
        link.status = .archived
        link.archivedAt = Date()
        link.updatedAt = Date()
        try? modelContext.save()
    }

    func deleteLink(_ link: SavedLink, modelContext: ModelContext) {
        modelContext.delete(link)
        try? modelContext.save()
    }

    func shareLink(_ link: SavedLink) -> URL? {
        URL(string: link.url)
    }
}
