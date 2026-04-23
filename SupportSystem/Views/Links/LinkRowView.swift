import SwiftUI

struct LinkRowView: View {
    let link: SavedLink

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(link.title ?? link.merchantDisplayName ?? link.merchantDomain)
                        .font(AppTypography.linkTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if let price = link.price {
                        Text(price.currencyFormatted(code: link.priceCurrency))
                            .font(AppTypography.linkPrice)
                            .foregroundStyle(.secondary)
                    }
                }

                if let subtitle = link.subtitle {
                    Text(subtitle)
                        .font(AppTypography.linkSubtitle)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(1)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .contentShape(Rectangle())
    }
}
