import SwiftUI

struct CodeTypeBadge: View {
    let type: CodeType

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch type {
        case .affiliate: "AFFILIATE"
        case .coupon: "COUPON"
        case .creatorCode: "CREATOR CODE"
        case .referral: "REFERRAL"
        }
    }

    private var color: Color {
        switch type {
        case .affiliate: .appBrand
        case .coupon: AppColors.blue
        case .creatorCode: AppColors.green
        case .referral: AppColors.orange
        }
    }
}
