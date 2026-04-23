import SwiftUI
import SwiftData

struct BenefactorDetectionStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: AddLinkViewModel

    private var hasDetectedCode: Bool {
        viewModel.detectedCode != nil || viewModel.existingBenefactor != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Status banner
                if let detected = viewModel.detectedCode {
                    StatusBanner(
                        style: .success,
                        title: "Benefactor Detected",
                        subtitle: "This link supports a benefactor"
                    )

                    // Detected code display
                    VStack(spacing: AppSpacing.xs) {
                        Text("Benefactor Found")
                            .font(AppTypography.sectionHeader)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(.secondary)

                        HStack(spacing: AppSpacing.sm) {
                            Text(detected.code)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.appGreen)

                            if let first = viewModel.detectedCodes.first {
                                CodeTypeBadge(type: first.type)
                            }
                        }

                        // Source label
                        if let first = viewModel.detectedCodes.first {
                            Text(sourceLabel(for: first.source))
                                .font(AppTypography.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Text("will receive your support")
                            .font(AppTypography.footnote)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    .padding(AppSpacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(.quaternary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

                    // Other detected codes disclosure
                    if viewModel.detectedCodes.count > 1 {
                        DisclosureGroup("Other detected codes (\(viewModel.detectedCodes.count - 1))") {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                ForEach(Array(viewModel.detectedCodes.dropFirst().enumerated()), id: \.offset) { _, code in
                                    HStack(spacing: AppSpacing.sm) {
                                        Text(code.code)
                                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        CodeTypeBadge(type: code.type)
                                        Spacer()
                                        Text(sourceLabel(for: code.source))
                                            .font(AppTypography.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.top, AppSpacing.sm)
                        }
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .padding(AppSpacing.md)
                        .background(.quaternary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                    }

                } else if let benefactor = viewModel.existingBenefactor {
                    StatusBanner(
                        style: .success,
                        title: "Benefactor Set",
                        subtitle: "You have a code for this merchant"
                    )

                    VStack(spacing: AppSpacing.xs) {
                        Text(benefactor.creatorName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.appGreen)

                        Text("Code: \(benefactor.code)")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(AppSpacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(.quaternary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

                } else {
                    StatusBanner(
                        style: .info,
                        title: "No Benefactor Detected",
                        subtitle: "You can add one on the Benefactors tab"
                    )
                }

                Spacer().frame(height: AppSpacing.md)

                // Save button
                Button {
                    Task { await viewModel.saveLink(modelContext: modelContext) }
                } label: {
                    Text(hasDetectedCode ? "Save & Support This Benefactor" : "Save Link")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(Color.appBrand)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
        }
        .navigationTitle("Benefactor")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func sourceLabel(for source: DetectedCode.CodeSource) -> String {
        switch source {
        case .queryParam: "Found in URL"
        case .pathSegment: "Found in link path"
        case .subdomain: "Found in subdomain"
        }
    }
}
