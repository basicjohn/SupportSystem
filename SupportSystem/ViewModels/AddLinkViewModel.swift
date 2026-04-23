import SwiftUI
import SwiftData

@MainActor
@Observable
final class AddLinkViewModel {
    var urlText: String = ""
    var currentStep: AddLinkStep = .pasteLink
    var errorMessage: String?

    // Extracted data
    var extractedDomain: String?
    var extractedDisplayName: String?
    var detectedCodes: [DetectedCode] = []
    var detectedCode: (code: String, type: CodeType)? {
        detectedCodes.first.map { ($0.code, $0.type) }
    }
    var savedLink: SavedLink?
    var existingBenefactor: Benefactor?

    // URL resolution
    var resolvedURL: String?

    // Scraped metadata
    var isFetchingMetadata = false
    var scrapedTitle: String?
    var scrapedSubtitle: String?
    var scrapedDescription: String?
    var scrapedImageURL: String?
    var scrapedPrice: Decimal?
    var scrapedPriceCurrency: String?
    var scrapedCategory: String?

    enum AddLinkStep {
        case pasteLink
        case linkInfo
        case benefactorDetection
        case success
    }

    func pasteFromClipboard() {
        if let clipboard = UIPasteboard.general.string, clipboard.withHTTPS.isValidURL {
            urlText = clipboard.withHTTPS
        }
    }

    func processURL(modelContext: ModelContext) {
        let url = urlText.withHTTPS
        guard url.isValidURL else {
            errorMessage = "Please enter a valid URL"
            return
        }

        errorMessage = nil

        // Extract domain
        guard let domain = URLUtilities.extractDomain(from: url) else {
            errorMessage = "Could not extract domain from URL"
            return
        }

        extractedDomain = domain
        extractedDisplayName = MerchantResolver.displayName(for: domain)

        // Check for affiliate codes in URL
        detectedCodes = URLUtilities.detectAffiliateCodes(in: url)

        // Check for existing benefactor
        let fetchDomain = domain
        let descriptor = FetchDescriptor<Benefactor>(
            predicate: #Predicate { $0.merchantDomain == fetchDomain && $0.isActive }
        )
        existingBenefactor = try? modelContext.fetch(descriptor).first

        // Set a default category based on domain
        scrapedCategory = categoryForDomain(domain)

        // Move to link info immediately (metadata loads async)
        currentStep = .linkInfo

        // Start async metadata fetch (with short link resolution)
        isFetchingMetadata = true
        Task {
            var effectiveURL = url

            // Resolve short links first
            if URLResolver.isKnownShortener(url) {
                let resolved = await URLResolver.resolve(url)
                resolvedURL = resolved
                effectiveURL = resolved

                // Re-detect codes on the resolved URL
                detectedCodes = URLUtilities.detectAffiliateCodes(in: resolved)

                // Update domain if it changed
                if let newDomain = URLUtilities.extractDomain(from: resolved),
                   newDomain != extractedDomain {
                    extractedDomain = newDomain
                    extractedDisplayName = MerchantResolver.displayName(for: newDomain)
                }
            }

            if let metadata = await MetadataFetcher.fetch(from: effectiveURL) {
                scrapedTitle = metadata.title
                scrapedDescription = metadata.description
                scrapedImageURL = metadata.imageURL
                scrapedPrice = metadata.price
                scrapedPriceCurrency = metadata.priceCurrency ?? "USD"

                // Generate subtitle from description if we have a title
                if let desc = metadata.description, let title = metadata.title {
                    // Use first sentence or first 80 chars as subtitle
                    let firstSentence = desc.components(separatedBy: ". ").first ?? desc
                    if firstSentence != title {
                        scrapedSubtitle = String(firstSentence.prefix(100))
                    }
                }
            }
            isFetchingMetadata = false
        }
    }

    func proceedToBenefactor() {
        currentStep = .benefactorDetection
    }

    func saveLink(modelContext: ModelContext) async {
        let url = urlText.withHTTPS
        guard let domain = extractedDomain,
              let urlHash = URLUtilities.hashURL(url) else {
            return
        }

        let link = SavedLink(
            url: url,
            urlHash: urlHash,
            merchantDomain: domain,
            merchantDisplayName: extractedDisplayName
        )

        // Populate scraped metadata
        link.title = scrapedTitle
        link.subtitle = await TaglineGenerator.generate(
            title: scrapedTitle,
            category: scrapedCategory,
            price: scrapedPrice,
            merchantDomain: domain,
            merchantName: extractedDisplayName
        )
        link.productDescription = scrapedDescription
        link.imageURL = scrapedImageURL
        link.price = scrapedPrice
        link.priceCurrency = scrapedPriceCurrency ?? "USD"
        link.category = scrapedCategory

        // Attach existing benefactor if available
        if let benefactor = existingBenefactor {
            link.benefactor = benefactor
        }

        // Record detected code with metadata
        if let detected = detectedCodes.first {
            link.benefactorDetected = true
            link.detectedCode = detected.code
            link.detectedCodeType = detected.type.rawValue
            link.detectedCodeSource = detected.source.rawValue
            link.detectedCodeParam = detected.paramName
        }

        modelContext.insert(link)
        try? modelContext.save()

        savedLink = link
        currentStep = .success
    }

    func reset() {
        urlText = ""
        currentStep = .pasteLink
        errorMessage = nil
        extractedDomain = nil
        extractedDisplayName = nil
        detectedCodes = []
        resolvedURL = nil
        savedLink = nil
        existingBenefactor = nil
        isFetchingMetadata = false
        scrapedTitle = nil
        scrapedSubtitle = nil
        scrapedDescription = nil
        scrapedImageURL = nil
        scrapedPrice = nil
        scrapedPriceCurrency = nil
        scrapedCategory = nil
    }

    // MARK: - Helpers

    private func categoryForDomain(_ domain: String) -> String {
        let categories: [String: String] = [
            "amazon.com": "General",
            "bestbuy.com": "Electronics",
            "target.com": "General",
            "walmart.com": "General",
            "apple.com": "Electronics",
            "nike.com": "Apparel",
            "adidas.com": "Apparel",
            "newegg.com": "Electronics",
            "bhphotovideo.com": "Electronics",
            "sephora.com": "Beauty",
            "ulta.com": "Beauty",
            "homedepot.com": "Home",
            "lowes.com": "Home",
            "ikea.com": "Home",
            "wayfair.com": "Home",
            "rei.com": "Outdoors",
            "myprotein.com": "Health",
            "gymshark.com": "Apparel",
            "samsung.com": "Electronics",
            "dell.com": "Electronics",
            "sonos.com": "Electronics",
            "bose.com": "Electronics",
        ]
        return categories[domain] ?? "Shopping"
    }
}
