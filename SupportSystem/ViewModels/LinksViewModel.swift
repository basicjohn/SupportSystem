import SwiftUI
import SwiftData

@Observable
final class LinksViewModel {
    var showingAddLink = false

    struct MerchantGroup: Identifiable {
        let id: String  // merchantDomain
        let domain: String
        let displayName: String
        let links: [SavedLink]
        let benefactor: Benefactor?

        var hasBenefactor: Bool { benefactor != nil }
    }

    func groupedLinks(links: [SavedLink], benefactors: [Benefactor]) -> [MerchantGroup] {
        let grouped = Dictionary(grouping: links) { $0.merchantDomain }

        return grouped.map { domain, links in
            let benefactor = benefactors.first { $0.merchantDomain == domain && $0.isActive }
            return MerchantGroup(
                id: domain,
                domain: domain,
                displayName: links.first?.merchantDisplayName ?? MerchantResolver.displayName(for: domain),
                links: links.sorted { $0.createdAt > $1.createdAt },
                benefactor: benefactor
            )
        }
        .sorted { $0.links.count > $1.links.count }
    }

    func stats(links: [SavedLink], benefactors: [Benefactor]) -> (links: Int, merchants: Int, withCodes: Int) {
        let merchantDomains = Set(links.map(\.merchantDomain))
        let benefactorDomains = Set(benefactors.filter(\.isActive).map(\.merchantDomain))
        let withCodes = merchantDomains.intersection(benefactorDomains).count
        return (links.count, merchantDomains.count, withCodes)
    }

    func deleteLink(_ link: SavedLink, modelContext: ModelContext) {
        modelContext.delete(link)
        try? modelContext.save()
    }

    func archiveLink(_ link: SavedLink, modelContext: ModelContext) {
        link.status = .archived
        link.archivedAt = Date()
        link.updatedAt = Date()
        try? modelContext.save()
    }
}
