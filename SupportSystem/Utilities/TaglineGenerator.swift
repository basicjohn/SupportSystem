import Foundation
import FoundationModels

/// Generates semi-satirical one-liner taglines for saved links.
///
/// **Primary:** Uses Apple Intelligence on-device model via Foundation Models framework.
/// **Fallback:** Hardcoded tagline banks for devices without Apple Intelligence support.
enum TaglineGenerator {

    // MARK: - Generable Output

    @Generable
    struct GeneratedTagline {
        @Guide(description: "A short witty semi-satirical one-liner (under 15 words) about saving this link. Self-aware, playful tone about consumer culture or internet habits. No hashtags, no emojis.")
        var tagline: String
    }

    // MARK: - Public API (async — prefers on-device model)

    /// Generate a tagline using Apple Intelligence when available, falling back to hardcoded banks.
    static func generate(
        title: String? = nil,
        category: String? = nil,
        price: Decimal? = nil,
        merchantDomain: String? = nil,
        merchantName: String? = nil
    ) async -> String {
        if let aiTagline = await generateWithAI(
            title: title,
            category: category,
            price: price,
            merchantDomain: merchantDomain,
            merchantName: merchantName
        ) {
            return aiTagline
        }
        return generateFallback(
            title: title,
            category: category,
            price: price,
            merchantDomain: merchantDomain,
            merchantName: merchantName
        )
    }

    // MARK: - Synchronous Fallback API

    /// Generate a tagline using only hardcoded banks. Use when async is not available (e.g. migrations).
    static func generateFallback(
        title: String? = nil,
        category: String? = nil,
        price: Decimal? = nil,
        merchantDomain: String? = nil,
        merchantName: String? = nil
    ) -> String {
        if let line = categoryTagline(category: category, title: title) { return line }
        if let line = priceTagline(price: price) { return line }
        if let line = merchantTagline(domain: merchantDomain, name: merchantName) { return line }
        return genericTaglines.randomElement()!
    }

    // MARK: - Apple Intelligence Generation

    private static func generateWithAI(
        title: String?,
        category: String?,
        price: Decimal?,
        merchantDomain: String?,
        merchantName: String?
    ) async -> String? {
        let model = SystemLanguageModel.default
        guard model.availability == .available else { return nil }

        var contextParts: [String] = []
        if let title { contextParts.append("Title: \(title)") }
        if let category { contextParts.append("Category: \(category)") }
        if let price { contextParts.append("Price: $\(price)") }
        if let merchantName { contextParts.append("Store: \(merchantName)") }
        else if let merchantDomain { contextParts.append("From: \(merchantDomain)") }

        let context = contextParts.isEmpty ? "a link someone wanted to save" : contextParts.joined(separator: ", ")

        let prompt = """
        Generate a witty, semi-satirical one-liner tagline for a saved link.
        Context: \(context)

        The tagline should be self-aware and playful — poking fun at consumer culture, \
        internet habits, or the act of saving links. Keep it under 15 words. \
        No emojis. No hashtags. Just a clever quip.
        """

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt, generating: GeneratedTagline.self)
            let tagline = response.content.tagline.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            guard !tagline.isEmpty else { return nil }
            return tagline
        } catch {
            return nil
        }
    }

    // MARK: - Category-Based

    private static func categoryTagline(category: String?, title: String?) -> String? {
        let cat = category?.lowercased() ?? ""
        let t = title?.lowercased() ?? ""

        if cat.containsAny("electronics", "tech", "computer", "audio", "phone", "gaming") ||
           t.containsAny("keyboard", "mouse", "monitor", "headphone", "speaker", "cable", "hub", "charger", "adapter") {
            return techTaglines.randomElement()
        }

        if cat.containsAny("clothing", "apparel", "fashion", "shoes", "footwear", "accessories") ||
           t.containsAny("shirt", "shoe", "sneaker", "jacket", "hoodie", "pants", "dress", "hat", "ring", "wallet", "bag") {
            return fashionTaglines.randomElement()
        }

        if cat.containsAny("home", "kitchen", "furniture", "decor", "garden") ||
           t.containsAny("pillow", "blanket", "candle", "mug", "lamp", "shelf", "desk") {
            return homeTaglines.randomElement()
        }

        if cat.containsAny("food", "drink", "beverage", "coffee", "snack", "grocery") ||
           t.containsAny("coffee", "tea", "sauce", "snack", "chocolate", "wine", "beer") {
            return foodTaglines.randomElement()
        }

        if cat.containsAny("beauty", "skincare", "personal care", "grooming", "cosmetic") ||
           t.containsAny("serum", "moisturizer", "shampoo", "razor", "cologne", "perfume") {
            return beautyTaglines.randomElement()
        }

        if cat.containsAny("book", "media", "music", "movie", "game") ||
           t.containsAny("book", "novel", "vinyl", "album", "game") {
            return mediaTaglines.randomElement()
        }

        if cat.containsAny("article", "news", "blog", "opinion", "editorial") ||
           t.containsAny("how to", "guide", "tutorial", "review", "why") {
            return articlesTaglines.randomElement()
        }

        if cat.containsAny("recipe", "cooking", "baking") ||
           t.containsAny("recipe", "cook", "bake", "ingredient") {
            return recipeTaglines.randomElement()
        }

        if cat.containsAny("software", "developer", "programming", "code", "tool") ||
           t.containsAny("github", "api", "framework", "library", "plugin", "extension", "repo") {
            return devToolsTaglines.randomElement()
        }

        if cat.containsAny("travel", "hotel", "flight", "vacation", "trip") ||
           t.containsAny("travel", "hotel", "airbnb", "flight", "booking", "destination") {
            return travelTaglines.randomElement()
        }

        if cat.containsAny("fitness", "health", "workout", "wellness", "sport") ||
           t.containsAny("workout", "exercise", "gym", "yoga", "running", "protein") {
            return fitnessTaglines.randomElement()
        }

        if cat.containsAny("education", "course", "learning", "class", "tutorial") ||
           t.containsAny("course", "learn", "class", "certification", "lesson", "masterclass") {
            return educationTaglines.randomElement()
        }

        if cat.containsAny("design", "creative", "art", "photography") ||
           t.containsAny("font", "template", "mockup", "icon", "illustration", "photo") {
            return designTaglines.randomElement()
        }

        if cat.containsAny("finance", "invest", "money", "crypto", "stock") ||
           t.containsAny("invest", "stock", "crypto", "budget", "savings", "portfolio") {
            return financeTaglines.randomElement()
        }

        if cat.containsAny("subscription", "service", "saas", "membership") ||
           t.containsAny("subscription", "plan", "membership", "premium", "pro") {
            return subscriptionTaglines.randomElement()
        }

        return nil
    }

    // MARK: - Price-Based

    private static func priceTagline(price: Decimal?) -> String? {
        guard let price else { return nil }
        switch price {
        case ..<10:
            return cheapTaglines.randomElement()
        case 10..<50:
            return nil
        case 50..<200:
            return midRangeTaglines.randomElement()
        case 200..<500:
            return premiumTaglines.randomElement()
        default:
            return luxuryTaglines.randomElement()
        }
    }

    // MARK: - Merchant-Based

    private static func merchantTagline(domain: String?, name: String?) -> String? {
        let d = domain?.lowercased() ?? ""
        let n = name?.lowercased() ?? ""

        if d.contains("amazon") || n.contains("amazon") {
            return amazonTaglines.randomElement()
        }
        if d.contains("instagram") || d.contains("tiktok") || d.contains("youtube") {
            return socialTaglines.randomElement()
        }
        if d.contains("etsy") {
            return etsyTaglines.randomElement()
        }

        return nil
    }

    // MARK: - Category Tagline Banks

    private static let techTaglines = [
        "Another device to charge. Worth it.",
        "Your desk called. It wants this.",
        "Dopamine, delivered via USB-C.",
        "Because your current setup is 'fine.'",
        "One step closer to a command center.",
        "Future you says thanks.",
        "Productivity? Sure, let's call it that.",
        "Peak performance. Desk envy guaranteed.",
        "The missing piece you didn't know was missing.",
        "Finally, a justifiable impulse.",
        "Specs don't lie. Neither does FOMO.",
        "Your old one still works. That's not the point.",
    ]

    private static let fashionTaglines = [
        "Main character energy. On sale.",
        "Dress for the life you're manifesting.",
        "Looking good is a public service.",
        "Your closet has been expecting this.",
        "Retail therapy, but make it fashion.",
        "Bold choice. Perfect choice.",
        "Because you deserve nice things.",
        "Outfit of the day, loading...",
        "Street-ready. Couch-ready. Everything-ready.",
        "Step up or step aside.",
    ]

    private static let homeTaglines = [
        "Nesting instinct: activated.",
        "Your space, but better.",
        "A small upgrade with big energy.",
        "Home is where this thing is.",
        "Interior design via impulse. Respect.",
        "Cozy just got an upgrade.",
        "Your apartment called. It's ready.",
        "Living your best curated life.",
    ]

    private static let foodTaglines = [
        "Calories don't count if it's artisanal.",
        "Your taste buds sent a request.",
        "Self-care you can eat.",
        "Gourmet on a Tuesday. Why not.",
        "Snack game: elevated.",
        "Treat yourself. It's basically health food.",
        "Life's too short for boring snacks.",
    ]

    private static let beautyTaglines = [
        "Glow up in progress.",
        "Self-care is non-negotiable.",
        "Your skin will thank you later.",
        "Bathroom shelf prestige: unlocked.",
        "Beauty routine, optimized.",
        "Mirror, mirror, meet your match.",
        "Invest in the canvas.",
    ]

    private static let mediaTaglines = [
        "For your ever-growing collection.",
        "Knowledge is power. Also, fun.",
        "Culture: acquired.",
        "Your shelf just got more interesting.",
        "A personality, one item at a time.",
        "Enrichment, delivered.",
    ]

    private static let articlesTaglines = [
        "Read it later. Or never. No judgment.",
        "Saving articles is a lifestyle.",
        "Your reading list just got deeper.",
        "Intellectually curious. Chronically busy.",
        "Filed under: things you'll definitely read.",
        "Another tab closed, another link saved.",
        "Knowledge hoarding at its finest.",
        "You'll get to it. Eventually.",
    ]

    private static let recipeTaglines = [
        "Chef mode: pending.",
        "Saved it. Cooked it? TBD.",
        "Your kitchen has potential. This proves it.",
        "Ambitious cooking energy, saved for later.",
        "Somewhere between takeout and this recipe.",
        "A home-cooked dream, bookmarked.",
        "Gordon Ramsay would be... cautiously optimistic.",
    ]

    private static let devToolsTaglines = [
        "Another tool for the toolchain.",
        "README: read eventually.",
        "Starring repos is a personality trait.",
        "One dependency closer to greatness.",
        "Your side project needs this. Probably.",
        "Open source, open heart.",
        "Will integrate. Someday. Maybe.",
        "Stack Overflow led you here, didn't it.",
    ]

    private static let travelTaglines = [
        "Wanderlust, bookmarked.",
        "Your future self is already packing.",
        "Out of office energy: activated.",
        "Saving this is basically planning.",
        "The trip starts with a saved link.",
        "Adventure awaits. Budget pending.",
        "Dreaming in destinations.",
    ]

    private static let fitnessTaglines = [
        "New year, new you. Any day now.",
        "Gains start with a saved link, right?",
        "Motivation: bookmarked.",
        "Your body will thank you. Probably.",
        "Aspirational fitness, digitally archived.",
        "One link closer to that glow-up.",
        "Sweat equity starts here.",
    ]

    private static let educationTaglines = [
        "Investing in your brain.",
        "Future skills, loading...",
        "Learning is a flex.",
        "Your resume just perked up.",
        "Knowledge: add to cart.",
        "Leveling up, one link at a time.",
        "Curiosity saved the link.",
    ]

    private static let designTaglines = [
        "Pixel-perfect taste.",
        "Your mood board approves.",
        "Aesthetic archived.",
        "Creative assets: stockpiling.",
        "Design inspiration, safely filed away.",
        "Making things pretty, professionally.",
        "Your creative toolkit grows.",
    ]

    private static let financeTaglines = [
        "Making money moves. Literally.",
        "Your portfolio called. It's interested.",
        "Fiscal responsibility starts with research.",
        "Invest in the research phase.",
        "Money talks. This link whispers.",
        "Financial literacy, one link at a time.",
        "Wealth-building: the saved-link era.",
    ]

    private static let subscriptionTaglines = [
        "Another monthly charge to forget about.",
        "Subscribe first, evaluate later.",
        "Your recurring payments have a new friend.",
        "Premium everything. Budget nothing.",
        "Auto-renew your commitment issues.",
        "The subscription life chose you.",
        "One more won't hurt. Probably.",
    ]

    // MARK: - Price-Based Tagline Banks

    private static let cheapTaglines = [
        "A bargain with character.",
        "Under ten bucks? Basically free.",
        "Small price, big energy.",
        "The budget-friendly flex.",
        "Pocket change well spent.",
    ]

    private static let midRangeTaglines = [
        "Reasonable and yet... irresistible.",
        "A considered purchase. Mostly.",
        "Not cheap, not crazy. Just right.",
        "The sweet spot of spending.",
    ]

    private static let premiumTaglines = [
        "You have good taste. Expensive taste.",
        "An investment in happiness, really.",
        "Premium picks for premium people.",
        "Worth every penny. Probably.",
    ]

    private static let luxuryTaglines = [
        "Go big or go home. You chose big.",
        "Your bank account looked away.",
        "Luxury is a mindset. And a price tag.",
        "Bold move. We support it.",
        "Living large, one link at a time.",
    ]

    // MARK: - Merchant-Based Tagline Banks

    private static let amazonTaglines = [
        "Prime obsession. No shame.",
        "Another box headed your way.",
        "The everything store strikes again.",
        "Add to cart. Add to life.",
    ]

    private static let socialTaglines = [
        "The algorithm knows you too well.",
        "Spotted in the wild. Must have.",
        "Scroll, see, save. The cycle continues.",
        "Your feed has good taste.",
        "Influenced? You prefer 'inspired.'",
    ]

    private static let etsyTaglines = [
        "Handmade with someone's whole heart.",
        "Supporting small. Living large.",
        "Artisan vibes. Mass market who?",
        "Unique finds for unique people.",
    ]

    // MARK: - Generic Tagline Banks (universal — works for any link type)

    private static let genericTaglines = [
        // Saving / bookmarking self-awareness
        "A fine addition to your collection.",
        "You saw it. You wanted it. Here we are.",
        "Saved for later. Revisited? We'll see.",
        "Supporting the economy, one link at a time.",
        "Good things come to those who save links.",
        "Bookmarked with intent.",
        "Another one for the queue.",
        "Want, meet plan.",
        "Curated by you. Judged by no one.",
        "Your saved links have a theme. It's you.",
        "Saving links is free. That's the dangerous part.",
        "This one sparked something.",
        "Filed under: things that caught your eye.",
        "One tap. Infinite possibilities.",
        "Digitally hoarding with purpose.",
        "Not all heroes wear capes. Some save links.",
        "The collection grows stronger.",
        "Organized chaos, one link at a time.",
        "Proof that you have taste.",
        "Your future self sends regards.",
        "Noted. Saved. Moving on.",
        "The internet is vast. You chose this.",
        "A moment of clarity in the endless scroll.",
        "This one made the cut.",
        "Saved, sealed, delivered.",
        "Your link library appreciates the donation.",
        "Adding to the archive of intent.",
        "You'll come back to this. Probably.",
        "Link saved. Dopamine received.",
        "Because bookmarks are a love language.",
        "Smart move. Or impulse. Either works.",
        "Captured for future reference.",
        "Your taste is showing.",
        "The save button was made for this moment.",
        "Into the vault it goes.",
        "This one has potential.",
        "A link worth remembering.",
        "Collecting things you care about.",
        "Saved with conviction.",
        "Your digital scrapbook grows.",
    ]
}

// MARK: - String Helper

private extension String {
    func containsAny(_ terms: String...) -> Bool {
        terms.contains { self.contains($0) }
    }
}
