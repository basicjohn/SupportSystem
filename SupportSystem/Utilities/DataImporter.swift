import Foundation
import SwiftData

enum DataImporter {
    static func importData(from data: Data, modelContext: ModelContext) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(SupportSystemExport.self, from: data)

        var linksImported = 0
        var linksSkipped = 0
        var benefactorsImported = 0
        var benefactorsSkipped = 0

        // Import links
        for linkExport in export.links {
            // Check for duplicate by URL
            let url = linkExport.url
            let descriptor = FetchDescriptor<SavedLink>(
                predicate: #Predicate { $0.url == url }
            )
            if (try? modelContext.fetch(descriptor))?.isEmpty == false {
                linksSkipped += 1
                continue
            }

            let urlHash = URLUtilities.hashURL(linkExport.url) ?? UUID().uuidString
            let link = SavedLink(
                url: linkExport.url,
                urlHash: urlHash,
                merchantDomain: linkExport.merchantDomain,
                merchantDisplayName: linkExport.merchantDisplayName
            )
            link.title = linkExport.title
            link.subtitle = linkExport.subtitle
            link.productDescription = linkExport.description
            link.imageURL = linkExport.imageURL
            link.category = linkExport.category

            if let priceStr = linkExport.price, let price = Decimal(string: priceStr) {
                link.price = price
            }

            modelContext.insert(link)
            linksImported += 1
        }

        // Import benefactors
        for bExport in export.benefactors {
            let domain = bExport.merchantDomain
            let code = bExport.code
            let descriptor = FetchDescriptor<Benefactor>(
                predicate: #Predicate { $0.merchantDomain == domain && $0.code == code }
            )
            if (try? modelContext.fetch(descriptor))?.isEmpty == false {
                benefactorsSkipped += 1
                continue
            }

            let codeType = CodeType(rawValue: bExport.codeType) ?? .affiliate
            let benefactor = Benefactor(
                merchantDomain: bExport.merchantDomain,
                creatorName: bExport.creatorName,
                code: bExport.code,
                codeType: codeType
            )
            benefactor.merchantDisplayName = bExport.merchantDisplayName
            benefactor.notes = bExport.notes

            modelContext.insert(benefactor)
            benefactorsImported += 1
        }

        try modelContext.save()

        return ImportResult(
            linksImported: linksImported,
            linksSkipped: linksSkipped,
            linksFailed: 0,
            benefactorsImported: benefactorsImported,
            benefactorsSkipped: benefactorsSkipped,
            benefactorsFailed: 0,
            settingsImported: 0
        )
    }
}
