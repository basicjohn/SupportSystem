import SwiftUI

struct LinkSavedSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddLinkViewModel

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Success icon
            Circle()
                .fill(Color.appGreen)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(spacing: AppSpacing.xs) {
                Text("Link Saved!")
                    .font(.system(size: 18, weight: .bold))

                if let link = viewModel.savedLink {
                    Text(link.title ?? link.url)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(link.merchantDisplayName ?? link.merchantDomain)
                        .font(AppTypography.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            // Benefactor info
            if let benefactor = viewModel.existingBenefactor ?? viewModel.savedLink?.benefactor {
                VStack(spacing: AppSpacing.xs) {
                    Text("Benefactor")
                        .font(AppTypography.sectionHeader)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(.secondary)

                    Text(benefactor.creatorName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.appGreen)
                }
                .padding(AppSpacing.lg)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(AppTypography.buttonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(Color.appBrand)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
            }
            .padding(.bottom, AppSpacing.xxl)
        }
        .padding(.horizontal, AppSpacing.xl)
        .navigationBarBackButtonHidden()
    }
}
