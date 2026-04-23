import SwiftUI

struct LinksEmptyStateView: View {
    var onAddLink: () -> Void

    var body: some View {
        VStack {
            Spacer()
            AppEmptyStateView(
                icon: "link",
                title: "No Links Yet",
                message: "Save a product link from any app or browser to start supporting your favorite creators.",
                buttonTitle: "How to Save Links",
                action: onAddLink
            )
            Spacer()
        }
    }
}
