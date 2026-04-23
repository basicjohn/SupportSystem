import SwiftUI
import SwiftData

struct AddLinkFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddLinkViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .pasteLink:
                    PasteLinkStepView(viewModel: viewModel)
                case .linkInfo:
                    LinkInfoStepView(viewModel: viewModel)
                case .benefactorDetection:
                    BenefactorDetectionStepView(viewModel: viewModel)
                case .success:
                    LinkSavedSuccessView(viewModel: viewModel)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.currentStep != .success {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .environment(\.modelContext, modelContext)
            .onDisappear {
                viewModel.reset()
            }
        }
    }
}
