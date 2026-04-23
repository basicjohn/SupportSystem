import SwiftUI

struct ListRow<Trailing: View>: View {
    let title: String
    var subtitle: String?
    var trailingText: String?
    var showChevron: Bool = true
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        trailingText: String? = nil,
        showChevron: Bool = true,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingText = trailingText
        self.showChevron = showChevron
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.linkTitle)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.linkSubtitle)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }

            Spacer()

            trailing()

            if let trailingText {
                Text(trailingText)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .contentShape(Rectangle())
    }
}
