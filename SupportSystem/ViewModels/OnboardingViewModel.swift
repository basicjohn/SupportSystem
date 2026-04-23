import SwiftUI
import SwiftData

@Observable
final class OnboardingViewModel {
    var currentStep: Int = 1

    func advance(modelContext: ModelContext) {
        if currentStep < 3 {
            currentStep += 1
        } else {
            complete(modelContext: modelContext)
        }
    }

    func skip(modelContext: ModelContext) {
        let progress = getOrCreateProgress(modelContext: modelContext)
        progress.skipped = true
        progress.currentStep = 4
        try? modelContext.save()
    }

    func complete(modelContext: ModelContext) {
        let progress = getOrCreateProgress(modelContext: modelContext)
        progress.step1Completed = true
        progress.step2Completed = true
        progress.step3Completed = true
        progress.currentStep = 4
        progress.completedAt = Date()
        try? modelContext.save()
    }

    private func getOrCreateProgress(modelContext: ModelContext) -> OnboardingProgress {
        let descriptor = FetchDescriptor<OnboardingProgress>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let progress = OnboardingProgress()
        modelContext.insert(progress)
        return progress
    }
}
