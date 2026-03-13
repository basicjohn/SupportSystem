import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Share Extension Flow Steps
enum ShareFlowStep {
    case loading
    case linkInfo
    case benefactor
    case success
    case error
}

// MARK: - Main Share Extension View
struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext

    @State private var currentStep: ShareFlowStep = .loading

    // Link data
    @State private var sharedURL: String?
    @State private var extractedDomain: String?
    @State private var merchantName: String?
    @State private var detectedCodes: [DetectedCode] = []
    private var detectedCode: (code: String, type: CodeType)? {
        detectedCodes.first.map { ($0.code, $0.type) }
    }

    // Scraped metadata
    @State private var scrapedTitle: String?
    @State private var scrapedSubtitle: String?
    @State private var scrapedDescription: String?
    @State private var scrapedImageURL: String?
    @State private var scrapedPrice: Decimal?
    @State private var scrapedPriceCurrency: String?
    @State private var scrapedCategory: String?
    @State private var isFetchingMetadata = false

    // Benefactor data
    @State private var existingBenefactor: Benefactor?
    @State private var availableBenefactors: [Benefactor] = []
    @State private var selectedBenefactor: Benefactor?
    @State private var showBenefactorList = false

    // Add new benefactor inline
    @State private var showAddBenefactor = false
    @State private var newCreatorName = ""
    @State private var newCode = ""

    // Save state
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var container: ModelContainer?

    var body: some View {
        VStack(spacing: 0) {
            switch currentStep {
            case .loading:
                loadingView
            case .linkInfo:
                linkInfoView
            case .benefactor:
                benefactorView
            case .success:
                successView
            case .error:
                errorView
            }
        }
        .task {
            await loadSharedURL()
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Processing link...")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
                .padding(.top, AppSpacing.sm)
            Spacer()
        }
    }

    // MARK: - Screen 1: Link Info
    private var linkInfoView: some View {
        VStack(spacing: 0) {
            // Header: Cancel ... SUPPORT SYSTEM
            shareHeader(title: "SUPPORT SYSTEM", showBack: false)

            // Merchant accent bar
            if let merchantName {
                merchantAccentBar(name: merchantName)
            }

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Product info card
                    productInfoCard

                    // Continue button
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep = .benefactor
                        }
                    } label: {
                        Text("Continue")
                            .font(AppTypography.buttonLabel)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                            .background(Color.appBrand)
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
    }

    // MARK: - Merchant Accent Bar
    private func merchantAccentBar(name: String) -> some View {
        let accentColor = extractedDomain.flatMap { AppColors.merchantAccents[$0] } ?? AppColors.gray

        return HStack {
            Text(name.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .tracking(0.5)
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(accentColor)
    }

    // MARK: - Product Info Card
    private var productInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Product title & price
            let displayTitle = scrapedTitle ?? extractTitleFromURL(sharedURL ?? "")

            if let title = displayTitle, !title.isEmpty {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(2)
                    Spacer()
                    if let price = scrapedPrice {
                        Text(price.currencyFormatted(code: scrapedPriceCurrency))
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let subtitle = scrapedSubtitle {
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(2)
            }

            Divider()

            // Description section
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("DESCRIPTION")
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                if isFetchingMetadata {
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Fetching product details...")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let description = scrapedDescription {
                    Text(description)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                } else {
                    Text("Product link from \(merchantName ?? "store").")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Category & URL
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Text("Category")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(scrapedCategory ?? categoryForDomain(extractedDomain ?? ""))
                        .font(AppTypography.caption)
                }

                if let url = sharedURL {
                    HStack {
                        Text("URL")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(truncatedURL(url))
                            .font(AppTypography.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
    }

    // MARK: - Screen 2: Benefactor
    private var benefactorView: some View {
        VStack(spacing: 0) {
            // Header: Back ... BENEFACTOR
            shareHeader(title: "BENEFACTOR", showBack: true)

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if !showBenefactorList, detectedCode != nil, let benefactor = existingBenefactor {
                        // Code Detected state — matching benefactor found
                        codeDetectedView(benefactor: benefactor)
                    } else if !showBenefactorList, detectedCode != nil, existingBenefactor == nil {
                        // Code detected but no matching benefactor
                        codeDetectedNoMatchView
                    } else {
                        // No code found OR user tapped "Use Different Benefactor"
                        noCodeFoundView
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
    }

    // MARK: - Code Detected View
    private func codeDetectedView(benefactor: Benefactor) -> some View {
        VStack(spacing: AppSpacing.lg) {
            // Green success banner
            StatusBanner(
                style: .success,
                title: "Benefactor Detected",
                subtitle: "This link supports a benefactor"
            )

            // Code display card
            VStack(spacing: AppSpacing.sm) {
                Text("BENEFACTOR FOUND")
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Text(detectedCode?.code.uppercased() ?? benefactor.code.uppercased())
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColors.green)

                Text("will receive your support")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xl)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

            // Info text
            Text("This link already supports a benefactor. Your purchase will help support them.")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity)
                .background(.quaternary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

            // Save button
            Button {
                selectedBenefactor = benefactor
                saveLink()
            } label: {
                Text(isSaving ? "Saving..." : "Save & Support This Benefactor")
                    .font(AppTypography.buttonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(Color.appBrand)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
            }
            .disabled(isSaving)

            // Use different benefactor link
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showBenefactorList = true
                }
            } label: {
                Text("Use Different Benefactor")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Code Detected But No Matching Benefactor
    private var codeDetectedNoMatchView: some View {
        VStack(spacing: AppSpacing.lg) {
            StatusBanner(
                style: .success,
                title: "Code Detected",
                subtitle: "Code \"\(detectedCode?.code ?? "")\" found in URL"
            )

            Button {
                saveLink()
            } label: {
                Text(isSaving ? "Saving..." : "Save Link")
                    .font(AppTypography.buttonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(Color.appBrand)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
            }
            .disabled(isSaving)

            if !availableBenefactors.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showBenefactorList = true
                    }
                } label: {
                    Text("Choose a Benefactor")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - No Code Found / Benefactor List View
    private var noCodeFoundView: some View {
        VStack(spacing: AppSpacing.lg) {
            // Blue info banner
            StatusBanner(
                style: .info,
                title: "No Benefactor Detected",
                subtitle: "Choose a benefactor or add a new one"
            )

            if !availableBenefactors.isEmpty {
                // Benefactor selection list
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("YOUR BENEFACTORS FOR \(merchantName?.uppercased() ?? "THIS STORE")")
                        .font(AppTypography.sectionHeader)
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    VStack(spacing: 0) {
                        ForEach(availableBenefactors, id: \.id) { benefactor in
                            Button {
                                showAddBenefactor = false
                                selectedBenefactor = benefactor
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(benefactor.creatorName)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.primary)

                                        Text(benefactor.isUserDefined
                                            ? "Code: \(benefactor.code)"
                                            : "Default fallback")
                                            .font(AppTypography.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: !showAddBenefactor && selectedBenefactor?.id == benefactor.id
                                        ? "circle.inset.filled"
                                        : "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(!showAddBenefactor && selectedBenefactor?.id == benefactor.id
                                            ? Color.primary : .secondary)
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.md)
                            }

                            if benefactor.id != availableBenefactors.last?.id {
                                Divider()
                                    .padding(.horizontal, AppSpacing.md)
                            }
                        }
                    }
                    .background(.quaternary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }
            }

            // Add new benefactor section
            if showAddBenefactor {
                addBenefactorForm
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAddBenefactor = true
                        selectedBenefactor = nil
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add New Benefactor")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                }
            }

            // Save button
            Button {
                if showAddBenefactor && !newCreatorName.isEmpty && !newCode.isEmpty {
                    createAndSelectBenefactor()
                }
                saveLink()
            } label: {
                Text(isSaving ? "Saving..." : "Save Link")
                    .font(AppTypography.buttonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(Color.appBrand)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
            }
            .disabled(isSaving)
        }
    }

    // MARK: - Screen 3: Success
    private var successView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.green)

            Text("Link Saved!")
                .font(.system(size: 20, weight: .bold))

            if let merchantName {
                Text("Saved to \(merchantName)")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            if let benefactor = selectedBenefactor ?? existingBenefactor {
                Text("\(benefactor.creatorName)'s code will be used")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.green)
            }
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                done()
            }
        }
    }

    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 0) {
            shareHeader(title: "SUPPORT SYSTEM", showBack: false)

            VStack(spacing: AppSpacing.lg) {
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("Unable to Save")
                    .font(.system(size: 18, weight: .bold))
                Text(errorMessage ?? "An unknown error occurred")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                Spacer()
            }
        }
    }

    // MARK: - Shared Header Component
    private func shareHeader(title: String, showBack: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                if showBack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showBenefactorList = false
                            currentStep = .linkInfo
                        }
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(.primary)
                    }
                } else {
                    Button("Cancel") { cancel() }
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)

                Spacer()

                // Invisible balance spacer
                if showBack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .hidden()
                } else {
                    Button("Cancel") { }
                        .font(.system(size: 16))
                        .hidden()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Divider()
        }
    }

    // MARK: - Add Benefactor Form
    private var addBenefactorForm: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("NEW BENEFACTOR FOR \(merchantName?.uppercased() ?? "THIS STORE")")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(.secondary)
                .tracking(0.5)

            VStack(spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Creator Name")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. MKBHD", text: $newCreatorName)
                        .font(AppTypography.body)
                        .padding(AppSpacing.md)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Code / Affiliate Tag")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. TECH20", text: $newCode)
                        .font(AppTypography.body)
                        .padding(AppSpacing.md)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
        }
    }

    // MARK: - Create Benefactor

    private func createAndSelectBenefactor() {
        guard let container,
              let domain = extractedDomain,
              !newCreatorName.isEmpty,
              !newCode.isEmpty else { return }

        let context = ModelContext(container)
        let benefactor = Benefactor(
            merchantDomain: domain,
            creatorName: newCreatorName.trimmingCharacters(in: .whitespaces),
            code: newCode.trimmingCharacters(in: .whitespaces),
            codeType: .affiliate,
            isUserDefined: true,
            source: .manual
        )
        benefactor.merchantDisplayName = merchantName
        context.insert(benefactor)
        try? context.save()

        // Set this as the selected benefactor for the link save
        selectedBenefactor = benefactor
    }

    // MARK: - Helpers

    private func extractTitleFromURL(_ url: String) -> String? {
        guard let components = URLComponents(string: url) else { return nil }
        let segments = components.path
            .split(separator: "/")
            .map(String.init)
            .filter { segment in
                // Skip short segments that are likely IDs
                segment.count > 3 &&
                !segment.allSatisfy({ $0.isNumber || $0 == "-" })
            }

        guard let last = segments.last else { return nil }
        let cleaned = last
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: ".html", with: "")
            .replacingOccurrences(of: ".htm", with: "")

        // Capitalize each word
        return cleaned
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    private func truncatedURL(_ url: String) -> String {
        guard let components = URLComponents(string: url),
              let host = components.host else {
            return url
        }
        let path = components.path
        let truncatedPath = path.count > 20
            ? String(path.prefix(8)) + "..." + String(path.suffix(8))
            : path
        return host + truncatedPath
    }

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
        ]
        return categories[domain] ?? "Shopping"
    }

    // MARK: - Data Loading

    private func loadSharedURL() async {
        do {
            container = try SharedContainer.makeContainer()
        } catch {
            errorMessage = "Could not access database"
            currentStep = .error
            return
        }

        guard let items = extensionContext.inputItems as? [NSExtensionItem] else {
            errorMessage = "No content shared"
            currentStep = .error
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                // Try URL type first
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    do {
                        let loadedItem = try await provider.loadItem(
                            forTypeIdentifier: UTType.url.identifier
                        )
                        if let url = loadedItem as? URL {
                            processURL(url.absoluteString)
                            return
                        }
                    } catch { continue }
                }
                // Fall back to plain text
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    do {
                        let loadedItem = try await provider.loadItem(
                            forTypeIdentifier: UTType.plainText.identifier
                        )
                        if let text = loadedItem as? String, text.withHTTPS.isValidURL {
                            processURL(text.withHTTPS)
                            return
                        }
                    } catch { continue }
                }
            }
        }

        errorMessage = "No valid URL found in shared content"
        currentStep = .error
    }

    private func processURL(_ urlString: String) {
        sharedURL = urlString

        guard let domain = URLUtilities.extractDomain(from: urlString) else {
            errorMessage = "Could not extract domain from URL"
            currentStep = .error
            return
        }

        extractedDomain = domain
        merchantName = MerchantResolver.displayName(for: domain)
        detectedCodes = URLUtilities.detectAffiliateCodes(in: urlString)
        scrapedCategory = categoryForDomain(domain)

        // Look up existing benefactors for this merchant
        if let container {
            let context = ModelContext(container)
            let fetchDomain = domain
            let descriptor = FetchDescriptor<Benefactor>(
                predicate: #Predicate { $0.merchantDomain == fetchDomain && $0.isActive }
            )
            if let benefactors = try? context.fetch(descriptor) {
                availableBenefactors = benefactors
                existingBenefactor = benefactors.first
                selectedBenefactor = benefactors.first
            }
        }

        currentStep = .linkInfo

        // Start async metadata fetch (with short link resolution)
        isFetchingMetadata = true
        Task {
            var effectiveURL = urlString

            // Resolve short links first
            if URLResolver.isKnownShortener(urlString) {
                let resolved = await URLResolver.resolve(urlString)
                effectiveURL = resolved

                // Re-detect codes on resolved URL
                detectedCodes = URLUtilities.detectAffiliateCodes(in: resolved)

                // Update domain if changed
                if let newDomain = URLUtilities.extractDomain(from: resolved),
                   newDomain != extractedDomain {
                    extractedDomain = newDomain
                    merchantName = MerchantResolver.displayName(for: newDomain)
                }
            }

            if let metadata = await MetadataFetcher.fetch(from: effectiveURL) {
                scrapedTitle = metadata.title
                scrapedDescription = metadata.description
                scrapedImageURL = metadata.imageURL
                scrapedPrice = metadata.price
                scrapedPriceCurrency = metadata.priceCurrency ?? "USD"

                // Generate subtitle from description
                if let desc = metadata.description, let title = metadata.title {
                    let firstSentence = desc.components(separatedBy: ". ").first ?? desc
                    if firstSentence != title {
                        scrapedSubtitle = String(firstSentence.prefix(100))
                    }
                }
            }
            isFetchingMetadata = false
        }
    }

    // MARK: - Save

    private func saveLink() {
        guard let urlString = sharedURL,
              let domain = extractedDomain,
              let urlHash = URLUtilities.hashURL(urlString),
              let container else { return }

        isSaving = true

        let context = ModelContext(container)

        // Check for duplicate
        let descriptor = FetchDescriptor<SavedLink>(
            predicate: #Predicate { $0.urlHash == urlHash }
        )
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            errorMessage = "This link has already been saved"
            currentStep = .error
            isSaving = false
            return
        }

        let link = SavedLink(
            url: urlString,
            urlHash: urlHash,
            merchantDomain: domain,
            merchantDisplayName: merchantName
        )

        // Populate scraped metadata
        link.title = scrapedTitle
        link.subtitle = scrapedSubtitle
        link.productDescription = scrapedDescription
        link.imageURL = scrapedImageURL
        link.price = scrapedPrice
        link.priceCurrency = scrapedPriceCurrency ?? "USD"
        link.category = scrapedCategory

        // Attach selected benefactor (re-fetched in this context)
        if let benefactor = selectedBenefactor ?? existingBenefactor {
            let benefactorID = benefactor.id
            let bDescriptor = FetchDescriptor<Benefactor>(
                predicate: #Predicate { $0.id == benefactorID }
            )
            if let localBenefactor = try? context.fetch(bDescriptor).first {
                link.benefactor = localBenefactor
            }
        }

        if let detected = detectedCode {
            link.benefactorDetected = true
            link.detectedCode = detected.code
        }

        context.insert(link)

        do {
            try context.save()
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStep = .success
            }
        } catch {
            errorMessage = "Failed to save link"
            currentStep = .error
        }

        isSaving = false
    }

    // MARK: - Navigation

    private func cancel() {
        extensionContext.cancelRequest(withError: NSError(
            domain: "com.supportsystem.share",
            code: 0
        ))
    }

    private func done() {
        extensionContext.completeRequest(returningItems: nil)
    }
}
