import SwiftUI

struct BenefactorsEmptyStateView: View {
    var onAdd: () -> Void

    var body: some View {
        VStack {
            Spacer()
            AppEmptyStateView(
                icon: "chart.line.uptrend.xyaxis",
                title: "No Benefactors Yet",
                message: "Add your favorite creators' affiliate codes to support them when you shop. Until then, SupportSystem is the default benefactor.",
                buttonTitle: "Add a Benefactor",
                action: onAdd
            )
            Spacer()
        }
    }
}
