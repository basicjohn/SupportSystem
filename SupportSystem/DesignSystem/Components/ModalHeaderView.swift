import SwiftUI

struct ModalHeaderView: View {
    var leadingText: String?
    var leadingAction: (() -> Void)?
    let title: String
    var trailingText: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack {
            if let leadingText, let leadingAction {
                Button(action: leadingAction) {
                    Text(leadingText)
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)
                }
            } else {
                Spacer().frame(width: 60)
            }

            Spacer()

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()

            if let trailingText, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailingText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            } else {
                Spacer().frame(width: 60)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }
}
