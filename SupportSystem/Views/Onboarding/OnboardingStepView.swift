import SwiftUI

struct OnboardingStepView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.appBrand)

            VStack(spacing: AppSpacing.md) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, AppSpacing.xxl)
    }
}
