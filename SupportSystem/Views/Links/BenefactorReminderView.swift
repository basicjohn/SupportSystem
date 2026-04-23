import SwiftUI

/// User's chosen action from the benefactor-code reminder modal.
/// The presenting view acts on this in its `.sheet(onDismiss:)` so navigation
/// happens after the sheet has finished animating out — no timer guesswork.
enum ReminderOutcome {
    /// User chose to copy the code and then open the store.
    case copyAndOpen
    /// User chose to skip the code and open the store anyway.
    case openWithoutCode
    /// User dismissed without choosing (swipe down, tap outside).
    case dismissed
}

struct BenefactorReminderView: View {
    let creatorName: String
    let code: String
    /// Called once, with the button the user tapped. The presenter stores the
    /// outcome and acts on it in `.sheet(onDismiss:)`.
    var onSelect: (ReminderOutcome) -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Capsule()
                .fill(.quaternary)
                .frame(width: 36, height: 5)
                .padding(.top, AppSpacing.md)

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.green)
                .padding(.top, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                Text("Don't forget to use")
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                Text("\(creatorName)'s code!")
                    .font(.system(size: 20, weight: .bold))
            }

            Text(code)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.lg)
                .frame(maxWidth: .infinity)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                .padding(.horizontal, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                Button { onSelect(.copyAndOpen) } label: {
                    Text("Copy Code & Shop")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(Color.appBrand)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }

                Button { onSelect(.openWithoutCode) } label: {
                    Text("Shop Without Code")
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

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
