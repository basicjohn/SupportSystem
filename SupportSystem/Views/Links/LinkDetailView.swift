import SwiftUI
import SwiftData

struct LinkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let link: SavedLink
    @State private var viewModel = LinkDetailViewModel()
    @State private var showingBenefactorReminder = false
    /// Captured when the user taps a button in the reminder sheet; acted on in
    /// the sheet's `onDismiss` so navigation waits for the dismiss animation
    /// to finish (replaces the old 0.3s `asyncAfter` timer).
    @State private var pendingReminderOutcome: ReminderOutcome = .dismissed
    @State private var showingShareSheet = false

    private var merchantDisplayName: String {
        link.merchantDisplayName ?? MerchantResolver.displayName(for: link.merchantDomain)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Merchant header (dark bar style matching mockup)
                SectionHeader(
                    merchantDisplayName,
                    style: .darkBar,
                    accentColor: AppColors.merchantAccent(for: link.merchantDomain)
                ) {
                    BenefactorBadge(isActive: link.benefactor != nil)
                        .foregroundStyle(link.benefactor != nil ? .white.opacity(0.8) : .white.opacity(0.4))
                }

                // Product info — title, price, subtitle
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(alignment: .top) {
                        Text(link.title ?? merchantDisplayName)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(2)
                        Spacer()
                        if let price = link.price {
                            Text(price.currencyFormatted(code: link.priceCurrency))
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let subtitle = link.subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

                Divider().padding(.horizontal, AppSpacing.lg)

                // Description
                if let description = link.productDescription {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Description")
                            .font(AppTypography.sectionHeader)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(.secondary)

                        Text(description)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)

                    Divider().padding(.horizontal, AppSpacing.lg)
                }

                // Benefactor info
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Benefactor")
                        .font(AppTypography.sectionHeader)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(.secondary)

                    if let benefactor = link.benefactor {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(Color.appGreen)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(benefactor.creatorName)
                                    .font(.system(size: 13, weight: .bold))
                                Text("Code: \(benefactor.code)")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No code set for this merchant")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

                Divider().padding(.horizontal, AppSpacing.lg)

                // Metadata
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Text("Saved")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(link.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(AppTypography.caption)
                    }

                    if let category = link.category {
                        HStack {
                            Text("Category")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(category)
                                .font(AppTypography.caption)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

                // Action buttons
                VStack(spacing: AppSpacing.sm) {
                    Button {
                        if link.shouldRemindBeforeShopping {
                            pendingReminderOutcome = .dismissed
                            showingBenefactorReminder = true
                        } else {
                            viewModel.openInSafari(link: link)
                        }
                    } label: {
                        Text("Shop Now")
                            .font(AppTypography.buttonLabel)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                            .background(Color.appBrand)
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                    }

                    Button {
                        viewModel.copyLink(link)
                    } label: {
                        Text("Copy Link")
                            .font(AppTypography.buttonLabel)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .sheet(
            isPresented: $showingBenefactorReminder,
            onDismiss: {
                // Runs after the sheet finishes animating away, regardless of
                // whether dismissal was via button or swipe-down. The outcome
                // captured in the button handler decides what we do next.
                switch pendingReminderOutcome {
                case .copyAndOpen:
                    if let benefactor = link.benefactor {
                        viewModel.copyCode(benefactor)
                    }
                    viewModel.openInSafari(link: link)
                case .openWithoutCode:
                    viewModel.openInSafari(link: link)
                case .dismissed:
                    // User swiped the sheet away — do nothing, matches prior
                    // behavior where only explicit buttons triggered Safari.
                    break
                }
            }
        ) {
            if let benefactor = link.benefactor {
                BenefactorReminderView(
                    creatorName: benefactor.creatorName,
                    code: benefactor.code,
                    onSelect: { outcome in
                        pendingReminderOutcome = outcome
                        showingBenefactorReminder = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = viewModel.shareLink(link) {
                ShareSheetView(activityItems: [url])
            }
        }
        .navigationTitle("Link Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Mark as Purchased
                    Button {
                        viewModel.markAsPurchased(link, modelContext: modelContext)
                        dismiss()
                    } label: {
                        Label("Mark as Purchased", systemImage: "checkmark")
                    }

                    // Archive
                    Button {
                        viewModel.archiveLink(link, modelContext: modelContext)
                        dismiss()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }

                    // Share Link
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share Link", systemImage: "square.and.arrow.up")
                    }

                    // Copy Code (if benefactor exists)
                    if let benefactor = link.benefactor {
                        Button { viewModel.copyCode(benefactor) } label: {
                            Label("Copy Code", systemImage: "tag")
                        }
                    }

                    Divider()

                    // Delete
                    Button(role: .destructive) {
                        viewModel.deleteLink(link, modelContext: modelContext)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}

// MARK: - Share Sheet UIKit Wrapper
struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
