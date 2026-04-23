import SwiftUI

enum BannerStyle {
    case success
    case info
    case warning

    var color: Color {
        switch self {
        case .success: Color.appGreen
        case .info: Color.appBlue
        case .warning: Color.appOrange
        }
    }

    var icon: String {
        switch self {
        case .success: "checkmark"
        case .info: "magnifyingglass"
        case .warning: "exclamationmark.triangle"
        }
    }
}

struct StatusBanner: View {
    let style: BannerStyle
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: style.icon)
                .font(.system(size: 14))
                .foregroundStyle(style.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(style.color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .strokeBorder(style.color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
    }
}
