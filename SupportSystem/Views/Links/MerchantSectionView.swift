import SwiftUI

struct MerchantSectionView: View {
    let group: LinksViewModel.MerchantGroup

    private var accentColor: Color {
        AppColors.merchantAccent(for: group.domain)
    }

    var body: some View {
        Section {
            ForEach(group.links) { link in
                NavigationLink(value: link) {
                    LinkRowView(link: link)
                }
                .buttonStyle(.plain)
            }
        } header: {
            SectionHeader(group.displayName, style: .darkBar, accentColor: accentColor) {
                BenefactorBadge(isActive: group.hasBenefactor)
                    .foregroundStyle(group.hasBenefactor ? .white.opacity(0.8) : .white.opacity(0.4))
            }
        }
    }
}
