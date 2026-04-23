import SwiftUI

// MARK: - Section Header Styles
enum SectionHeaderStyle {
    /// Subtle header: small uppercase text with optional accent pip (original style)
    case subtle
    /// Dark bar header: #323232 background, white uppercase text, optional accent top border
    case darkBar
}

struct SectionHeader: View {
    let title: String
    var style: SectionHeaderStyle
    var accentColor: Color?
    var trailing: AnyView?

    // MARK: - Subtle style init (backward compatible)
    init(
        _ title: String,
        accentColor: Color? = nil,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.style = .subtle
        self.accentColor = accentColor
        self.trailing = AnyView(trailing())
    }

    // MARK: - Explicit style init
    init(
        _ title: String,
        style: SectionHeaderStyle,
        accentColor: Color? = nil,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.style = style
        self.accentColor = accentColor
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        switch style {
        case .subtle:
            subtleHeader
        case .darkBar:
            darkBarHeader
        }
    }

    // MARK: - Subtle Header (original)
    private var subtleHeader: some View {
        HStack(spacing: 0) {
            if let accent = accentColor {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 3, height: 14)
                    .padding(.trailing, AppSpacing.sm)
            }

            Text(title)
                .font(AppTypography.sectionHeader)
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(.secondary)

            Spacer()

            trailing
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Dark Bar Header (new — matches mockup v3)
    private var darkBarHeader: some View {
        VStack(spacing: 0) {
            // Optional accent color top border
            if let accent = accentColor {
                Rectangle()
                    .fill(accent)
                    .frame(height: 2)
            }

            // Dark bar
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(0.5)

                Spacer()

                trailing
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, 6)
            .background(Color.appBrand)
        }
        .textCase(nil)
    }
}
