import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Step content
            Group {
                switch viewModel.currentStep {
                case 1:
                    OnboardingStepView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Support Your Favorites",
                        description: "Every purchase is a chance to support the creators you love. Save links, add benefactors, and give back at no extra cost to you."
                    )
                case 2:
                    OnboardingStepView(
                        icon: "link",
                        title: "Save Links for Later",
                        description: "Found something you might want to buy? Save it to Support System from Safari or any app. We'll organize your links by store and keep them ready for when you decide to purchase."
                    )
                case 3:
                    OnboardingStepView(
                        icon: "heart.fill",
                        title: "Add Benefactors",
                        description: "Your favorite YouTubers, podcasters, and creators share affiliate links. Add their codes here, and when you purchase through your saved links, they earn a commission."
                    )
                default:
                    EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

            Spacer()

            // Page dots
            HStack(spacing: AppSpacing.sm) {
                ForEach(1...3, id: \.self) { step in
                    Circle()
                        .fill(step == viewModel.currentStep ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, AppSpacing.xl)

            // Buttons
            VStack(spacing: AppSpacing.md) {
                Button {
                    withAnimation {
                        viewModel.advance(modelContext: modelContext)
                    }
                } label: {
                    Text(viewModel.currentStep == 3 ? "Start Saving Links" : viewModel.currentStep == 1 ? "Get Started" : "Continue")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(Color.appBrand)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }

                if viewModel.currentStep < 3 {
                    Button {
                        viewModel.skip(modelContext: modelContext)
                    } label: {
                        Text("Skip")
                            .font(AppTypography.buttonLabel)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxl)
        }
    }
}
