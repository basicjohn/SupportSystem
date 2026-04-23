import SwiftUI

/// Row displaying a single benefactor's info (creator name, code, chevron)
struct BenefactorRowView: View {
    let benefactor: Benefactor
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(benefactor.creatorName)
                        .font(AppTypography.linkTitle)
                        .foregroundStyle(.primary)

                    Text("Code: \(benefactor.code)")
                        .font(AppTypography.linkSubtitle)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                BenefactorBadge(isActive: true)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Row for a merchant that has no user-defined benefactor (using default)
struct DefaultBenefactorRowView: View {
    let merchantDisplayName: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SupportSystem")
                        .font(AppTypography.linkTitle)
                        .foregroundStyle(.primary)

                    Text("Default fallback")
                        .font(AppTypography.linkSubtitle)
                        .foregroundStyle(.tertiary)
                        .italic()
                }

                Spacer()

                BenefactorBadge(isActive: false)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
