import SwiftUI
import SwiftData

struct PasteLinkStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: AddLinkViewModel

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Icon
            Circle()
                .fill(Color.appBrand)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(spacing: AppSpacing.xs) {
                Text("Add a Link")
                    .font(.system(size: 16, weight: .bold))
                Text("Paste a product link to save it")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            // URL Input
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Link URL")
                    .font(AppTypography.sectionHeader)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("https://amazon.com/product...", text: $viewModel.urlText)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(AppTypography.body)
                        .padding(AppSpacing.md)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

                    Button {
                        viewModel.pasteFromClipboard()
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 16))
                            Text("Paste")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppTypography.footnote)
                        .foregroundStyle(Color.appRed)
                }
            }

            Button {
                viewModel.processURL(modelContext: modelContext)
            } label: {
                Text("Continue")
                    .font(AppTypography.buttonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(viewModel.urlText.isEmpty ? Color.appBrand.opacity(0.5) : Color.appBrand)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
            }
            .disabled(viewModel.urlText.isEmpty)

            // Tip
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("Tip: Share from the apps you use to save links to Support System")
                    .font(AppTypography.footnote)
                    .foregroundStyle(.secondary)
                    .italic()
            }
            .padding(AppSpacing.md)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
        .navigationTitle("Add Link")
        .navigationBarTitleDisplayMode(.inline)
    }
}
