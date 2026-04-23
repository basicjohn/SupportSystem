import SwiftUI

struct StatItem: Identifiable {
    let id = UUID()
    let value: String
    let label: String
    var isHighlighted: Bool = false
}

struct SummaryStatsView: View {
    let title: String
    let stats: [StatItem]
    var tagline: String?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text(title)
                .font(AppTypography.sectionHeader)
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(stats) { stat in
                    VStack(spacing: AppSpacing.xs) {
                        Text(stat.value)
                            .font(AppTypography.statValue)
                            .foregroundStyle(stat.isHighlighted ? Color.appGreen : .primary)
                        Text(stat.label)
                            .font(AppTypography.statLabel)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if let tagline {
                Text(tagline)
                    .font(AppTypography.footnote)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding(AppSpacing.lg)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
        .padding(.horizontal, AppSpacing.lg)
    }
}
