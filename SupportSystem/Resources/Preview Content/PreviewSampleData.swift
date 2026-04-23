import SwiftUI
import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: SavedLink.self, Benefactor.self, AppSetting.self, OnboardingProgress.self,
        configurations: config
    )

    // Mark onboarding complete for previews
    let onboarding = OnboardingProgress()
    onboarding.currentStep = 4
    onboarding.step1Completed = true
    onboarding.step2Completed = true
    onboarding.step3Completed = true
    onboarding.completedAt = Date()
    container.mainContext.insert(onboarding)

    // Sample benefactors
    let mkbhdAmazon = Benefactor(merchantDomain: "amazon.com", creatorName: "MKBHD", code: "TECH20", codeType: .affiliate)
    mkbhdAmazon.merchantDisplayName = "Amazon"
    container.mainContext.insert(mkbhdAmazon)

    let linusBestBuy = Benefactor(merchantDomain: "bestbuy.com", creatorName: "LinusTech", code: "LINUS15", codeType: .referral)
    linusBestBuy.merchantDisplayName = "Best Buy"
    container.mainContext.insert(linusBestBuy)

    // Sample links - Amazon
    let link1 = SavedLink(url: "https://amazon.com/dp/B09XS7JWHH", urlHash: "hash1", merchantDomain: "amazon.com", merchantDisplayName: "Amazon")
    link1.title = "Sony WH-1000XM5"
    link1.subtitle = "Silence the world. Premium noise-canceling bliss."
    link1.price = 349.99
    link1.benefactor = mkbhdAmazon
    container.mainContext.insert(link1)

    let link2 = SavedLink(url: "https://amazon.com/dp/B0CKJV2Q2T", urlHash: "hash2", merchantDomain: "amazon.com", merchantDisplayName: "Amazon")
    link2.title = "Mechanical Keyboard"
    link2.subtitle = "Every keystroke a symphony. RGB brilliance."
    link2.price = 129.00
    link2.benefactor = mkbhdAmazon
    container.mainContext.insert(link2)

    let link3 = SavedLink(url: "https://amazon.com/dp/B08H4SLQ8M", urlHash: "hash3", merchantDomain: "amazon.com", merchantDisplayName: "Amazon")
    link3.title = "USB-C Hub"
    link3.subtitle = "Unlimited connectivity. One elegant solution."
    link3.price = 45.00
    link3.benefactor = mkbhdAmazon
    container.mainContext.insert(link3)

    // Sample links - Nike
    let link4 = SavedLink(url: "https://nike.com/t/air-max-90", urlHash: "hash4", merchantDomain: "nike.com", merchantDisplayName: "Nike")
    link4.title = "Air Max 90"
    link4.subtitle = "Legendary comfort. Street-ready icon."
    link4.price = 130.00
    container.mainContext.insert(link4)

    // Sample links - Best Buy
    let link5 = SavedLink(url: "https://bestbuy.com/4k-monitor", urlHash: "hash5", merchantDomain: "bestbuy.com", merchantDisplayName: "Best Buy")
    link5.title = "4K Gaming Monitor"
    link5.subtitle = "Cinematic glory. Every pixel perfected."
    link5.price = 449.99
    link5.benefactor = linusBestBuy
    container.mainContext.insert(link5)

    return container
}()
