import SwiftUI
import SwiftData

struct BenefactorsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLinks: [SavedLink]

    @Query private var benefactors: [Benefactor]

    private var links: [SavedLink] {
        allLinks.filter { $0.status == .active }
    }

    @State private var viewModel = BenefactorsViewModel()
    @State private var searchText = ""

    private var allMerchants: [BenefactorsViewModel.MerchantBenefactorInfo] {
        viewModel.merchantList(links: links, benefactors: benefactors)
    }

    private var filteredMerchants: [BenefactorsViewModel.MerchantBenefactorInfo] {
        guard !searchText.isEmpty else { return allMerchants }
        let query = searchText.lowercased()
        return allMerchants.filter { merchant in
            merchant.displayName.lowercased().contains(query) ||
            merchant.domain.lowercased().contains(query) ||
            merchant.benefactors.contains { b in
                b.creatorName.lowercased().contains(query) ||
                b.code.lowercased().contains(query)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allMerchants.isEmpty {
                    BenefactorsEmptyStateView {
                        viewModel.showingAddBenefactor = true
                    }
                } else if !searchText.isEmpty && filteredMerchants.isEmpty {
                    VStack {
                        Spacer()
                        AppEmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "No benefactors match \"\(searchText)\""
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            ForEach(filteredMerchants) { merchant in
                                Section {
                                    if merchant.benefactors.isEmpty {
                                        // No user-defined benefactor — show default row
                                        DefaultBenefactorRowView(
                                            merchantDisplayName: merchant.displayName
                                        ) {
                                            viewModel.selectedMerchantDomain = merchant.domain
                                            viewModel.showingAddBenefactor = true
                                        }
                                    } else {
                                        // Show each benefactor as a row
                                        ForEach(merchant.benefactors) { benefactor in
                                            BenefactorRowView(benefactor: benefactor) {
                                                viewModel.selectedMerchantDomain = merchant.domain
                                                viewModel.showingAddBenefactor = true
                                            }
                                        }
                                    }
                                } header: {
                                    SectionHeader(
                                        merchant.displayName,
                                        style: .darkBar,
                                        accentColor: AppColors.merchantAccent(for: merchant.domain)
                                    ) {
                                        BenefactorBadge(isActive: merchant.hasBenefactor)
                                            .foregroundStyle(
                                                merchant.hasBenefactor
                                                    ? .white.opacity(0.8)
                                                    : .white.opacity(0.4)
                                            )
                                    }
                                }
                            }

                            if searchText.isEmpty {
                                let s = viewModel.stats(benefactors: benefactors, links: links)
                                SummaryStatsView(
                                    title: "Your Support Network",
                                    stats: [
                                        StatItem(value: "\(s.benefactors)", label: "Benefactors"),
                                        StatItem(value: "\(s.stores)", label: "Stores"),
                                    ]
                                )
                                .padding(.top, AppSpacing.xl)
                                .padding(.bottom, AppSpacing.xxl)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Benefactors")
            .searchable(text: $searchText, prompt: "Search benefactors...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddButton {
                        viewModel.selectedMerchantDomain = nil
                        viewModel.showingAddBenefactor = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddBenefactor) {
                BenefactorFormView(merchantDomain: viewModel.selectedMerchantDomain)
            }
        }
    }
}
