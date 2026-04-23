import SwiftUI
import SwiftData

struct LinksTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedLink.createdAt, order: .reverse)
    private var allLinks: [SavedLink]

    @Query private var benefactors: [Benefactor]

    private var links: [SavedLink] {
        allLinks.filter { $0.status == .active }
    }

    private var filteredLinks: [SavedLink] {
        guard !searchText.isEmpty else { return links }
        let query = searchText.lowercased()
        return links.filter { link in
            (link.title?.lowercased().contains(query) ?? false) ||
            (link.subtitle?.lowercased().contains(query) ?? false) ||
            link.url.lowercased().contains(query) ||
            (link.merchantDisplayName?.lowercased().contains(query) ?? false) ||
            link.merchantDomain.lowercased().contains(query) ||
            (link.benefactor?.creatorName.lowercased().contains(query) ?? false)
        }
    }

    private var activeBenefactors: [Benefactor] {
        benefactors.filter(\.isActive)
    }

    @State private var viewModel = LinksViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if links.isEmpty {
                    LinksEmptyStateView {
                        viewModel.showingAddLink = true
                    }
                } else if !searchText.isEmpty && filteredLinks.isEmpty {
                    VStack {
                        Spacer()
                        AppEmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "No links match \"\(searchText)\""
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            let groups = viewModel.groupedLinks(links: filteredLinks, benefactors: activeBenefactors)

                            ForEach(groups) { group in
                                MerchantSectionView(group: group)
                            }

                            if searchText.isEmpty {
                                let s = viewModel.stats(links: links, benefactors: activeBenefactors)
                                SummaryStatsView(
                                    title: "Your Impact",
                                    stats: [
                                        StatItem(value: "\(s.links)", label: "Links Saved"),
                                        StatItem(value: "\(s.merchants)", label: "Merchants"),
                                        StatItem(value: "\(s.withCodes)", label: "With Codes"),
                                    ],
                                    tagline: "Every click counts. Keep building your support network."
                                )
                                .padding(.top, AppSpacing.xl)
                                .padding(.bottom, AppSpacing.xxl)
                            }
                        }
                    }
                    .navigationDestination(for: SavedLink.self) { link in
                        LinkDetailView(link: link)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                VStack(spacing: AppSpacing.sm) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: -4) {
                            Text("Support")
                            Text("System")
                        }
                        .font(.system(size: 32, weight: .bold))

                        Spacer()

                        AddButton { viewModel.showingAddLink = true }
                            .padding(.top, 4)
                    }

                    if !links.isEmpty {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            TextField("Search links...", text: $searchText)
                                .font(AppTypography.body)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, AppSpacing.sm)
            }
            .sheet(isPresented: $viewModel.showingAddLink) {
                AddLinkFlowView()
            }
        }
    }
}
