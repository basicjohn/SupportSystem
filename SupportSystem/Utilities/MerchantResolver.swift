import Foundation

enum MerchantResolver {
    /// Convert a domain to a human-readable display name.
    static func displayName(for domain: String) -> String {
        if let known = knownMerchants[domain.lowercased()] {
            return known
        }
        // Fallback: capitalize the first part of the domain
        let name = domain.components(separatedBy: ".").first ?? domain
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    static let knownMerchants: [String: String] = [
        "amazon.com": "Amazon",
        "amazon.co.uk": "Amazon UK",
        "amazon.ca": "Amazon CA",
        "bestbuy.com": "Best Buy",
        "target.com": "Target",
        "walmart.com": "Walmart",
        "apple.com": "Apple",
        "nike.com": "Nike",
        "adidas.com": "Adidas",
        "newegg.com": "Newegg",
        "bhphotovideo.com": "B&H Photo",
        "adorama.com": "Adorama",
        "ebay.com": "eBay",
        "etsy.com": "Etsy",
        "costco.com": "Costco",
        "homedepot.com": "Home Depot",
        "lowes.com": "Lowe's",
        "ikea.com": "IKEA",
        "wayfair.com": "Wayfair",
        "nordstrom.com": "Nordstrom",
        "macys.com": "Macy's",
        "zappos.com": "Zappos",
        "rei.com": "REI",
        "sephora.com": "Sephora",
        "ulta.com": "Ulta Beauty",
        "gamestop.com": "GameStop",
        "microcenter.com": "Micro Center",
        "myprotein.com": "MyProtein",
        "gymshark.com": "Gymshark",
        "underarmour.com": "Under Armour",
        "puma.com": "Puma",
        "newbalance.com": "New Balance",
        "samsung.com": "Samsung",
        "dell.com": "Dell",
        "hp.com": "HP",
        "lenovo.com": "Lenovo",
        "microsoft.com": "Microsoft",
        "google.com": "Google Store",
        "sonos.com": "Sonos",
        "bose.com": "Bose",
        "razer.com": "Razer",
        "logitech.com": "Logitech",
        "corsair.com": "Corsair",
        "steelseries.com": "SteelSeries",
        "dbrand.com": "dbrand",
        "casetify.com": "CASETiFY",
        "anker.com": "Anker",
        "peakdesign.com": "Peak Design",
        "notion.so": "Notion",
        "audible.com": "Audible",
    ]
}
