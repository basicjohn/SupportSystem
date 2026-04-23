import SwiftUI
import SwiftData

@Observable
final class BenefactorsViewModel {
    var showingAddBenefactor = false
    var selectedMerchantDomain: String?

    struct MerchantBenefactorInfo: Identifiable {
        let id: String  // merchantDomain
        let domain: String
        let displayName: String
        let linkCount: Int
        let benefactors: [Benefactor]

        var hasBenefactor: Bool { !benefactors.isEmpty }
        var primaryBenefactor: Benefactor? { benefactors.first }

        // Backward compat
        var benefactor: Benefactor? { primaryBenefactor }
    }

    func merchantList(links: [SavedLink], benefactors: [Benefactor]) -> [MerchantBenefactorInfo] {
        let linksByDomain = Dictionary(grouping: links) { $0.merchantDomain }
        let benefactorsByDomain = Dictionary(grouping: benefactors.filter(\.isActive)) { $0.merchantDomain }

        // All domains from both links and benefactors
        let allDomains = Set(linksByDomain.keys).union(benefactorsByDomain.keys)

        return allDomains.map { domain in
            let domainLinks = linksByDomain[domain] ?? []
            let domainBenefactors = benefactorsByDomain[domain] ?? []

            return MerchantBenefactorInfo(
                id: domain,
                domain: domain,
                displayName: MerchantResolver.displayName(for: domain),
                linkCount: domainLinks.count,
                benefactors: domainBenefactors.sorted { $0.priority < $1.priority }
            )
        }
        .sorted { ($0.hasBenefactor ? 0 : 1, $1.linkCount) < ($1.hasBenefactor ? 0 : 1, $0.linkCount) }
    }

    func stats(benefactors: [Benefactor], links: [SavedLink]) -> (benefactors: Int, stores: Int) {
        let activeBenefactors = benefactors.filter(\.isActive)
        let uniqueCreators = Set(activeBenefactors.map(\.creatorName)).count
        let merchantDomains = Set(links.map(\.merchantDomain))
        return (uniqueCreators, merchantDomains.count)
    }

    func deleteBenefactor(_ benefactor: Benefactor, modelContext: ModelContext) {
        modelContext.delete(benefactor)
        try? modelContext.save()
    }
}
