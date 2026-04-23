import SwiftUI

struct LinkInfoStepView: View {
    @Bindable var viewModel: AddLinkViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Merchant header (dark bar style matching mockup)
                if let domain = viewModel.extractedDomain {
                    SectionHeader(
                        viewModel.extractedDisplayName ?? domain,
                        style: .darkBar,
                        accentColor: AppColors.merchantAccent(for: domain)
                    ) {
                        if viewModel.existingBenefactor != nil {
                            BenefactorBadge(isActive: true)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }

                // Product info: title, price, subtitle
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(alignment: .top) {
                        if viewModel.isFetchingMetadata && viewModel.scrapedTitle == nil {
                            HStack(spacing: AppSpacing.sm) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Fetching product info...")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text(viewModel.scrapedTitle ?? viewModel.extractedDisplayName ?? "Product Link")
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(2)
                        }

                        Spacer()

                        if let price = viewModel.scrapedPrice {
                            Text(price.currencyFormatted(code: viewModel.scrapedPriceCurrency))
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let subtitle = viewModel.scrapedSubtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

                Divider().padding(.horizontal, AppSpacing.lg)

                // Description
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Description")
                        .font(AppTypography.sectionHeader)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(.secondary)

                    if viewModel.isFetchingMetadata && viewModel.scrapedDescription == nil {
                        HStack(spacing: AppSpacing.sm) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading...")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if let description = viewModel.scrapedDescription {
                        Text(description)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .lineLimit(6)
                    } else {
                        Text("Product link from \(viewModel.extractedDisplayName ?? "store").")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

                Divider().padding(.horizontal, AppSpacing.lg)

                // Additional details: Category & URL
                VStack(spacing: AppSpacing.sm) {
                    if let category = viewModel.scrapedCategory {
                        HStack {
                            Text("Category")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(category)
                                .font(AppTypography.caption)
                        }
                    }

                    HStack {
                        Text("URL")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(truncatedURL(viewModel.urlText))
                            .font(AppTypography.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

                Spacer().frame(height: AppSpacing.xl)

                // Continue button
                Button {
                    viewModel.proceedToBenefactor()
                } label: {
                    Text("Continue")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(Color.appBrand)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .navigationTitle("Link Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

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
}
