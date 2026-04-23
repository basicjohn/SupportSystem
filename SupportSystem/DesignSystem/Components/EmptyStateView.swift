import SwiftUI

struct AppEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Circle()
                .fill(.quaternary)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                }

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
            }

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.appBrand)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }
            }
        }
        .padding(AppSpacing.xxl)
    }
}
