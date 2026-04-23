import SwiftUI

struct BenefactorBadge: View {
    let isActive: Bool

    var body: some View {
        Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.system(size: 10))
            .foregroundStyle(isActive ? Color.appGreen : Color.appGray)
    }

    private var appGray: Color { AppColors.gray }
}

private extension Color {
    static var appGray: Color { AppColors.gray }
}
