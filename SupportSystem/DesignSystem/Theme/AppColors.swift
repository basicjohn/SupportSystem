import SwiftUI

enum AppColors {
    // MARK: - iOS System Colors
    static let blue = Color(red: 0/255, green: 122/255, blue: 255/255)
    static let green = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let orange = Color(red: 255/255, green: 149/255, blue: 0/255)
    static let red = Color(red: 255/255, green: 59/255, blue: 48/255)

    // MARK: - Gray Scale
    static let gray = Color(red: 142/255, green: 142/255, blue: 147/255)
    static let gray2 = Color(red: 99/255, green: 99/255, blue: 102/255)
    static let gray3 = Color(red: 72/255, green: 72/255, blue: 74/255)
    static let gray4 = Color(red: 58/255, green: 58/255, blue: 60/255)
    static let gray5 = Color(red: 44/255, green: 44/255, blue: 46/255)
    static let gray6 = Color(red: 28/255, green: 28/255, blue: 30/255)

    // MARK: - App Brand
    static let brand = Color(red: 50/255, green: 50/255, blue: 50/255)         // #323232
    static let brandBackground = Color(red: 245/255, green: 245/255, blue: 240/255) // #f5f5f0

    // MARK: - Merchant Accent Colors
    static let merchantAccents: [String: Color] = [
        "amazon.com": Color(red: 255/255, green: 153/255, blue: 0/255),       // #FF9900
        "bestbuy.com": Color(red: 0/255, green: 70/255, blue: 190/255),       // #0046BE
        "target.com": Color(red: 204/255, green: 0/255, blue: 0/255),         // #CC0000
        "walmart.com": Color(red: 0/255, green: 113/255, blue: 197/255),      // #0071C5
        "apple.com": Color(red: 0/255, green: 0/255, blue: 0/255),            // #000000
        "nike.com": Color(red: 0/255, green: 0/255, blue: 0/255),             // #000000
        "newegg.com": Color(red: 224/255, green: 131/255, blue: 37/255),      // #E08325
        "bhphotovideo.com": Color(red: 0/255, green: 100/255, blue: 175/255), // #0064AF
        "adorama.com": Color(red: 171/255, green: 31/255, blue: 37/255),      // #AB1F25
        "ebay.com": Color(red: 230/255, green: 36/255, blue: 60/255),         // #E6243C
        "costco.com": Color(red: 0/255, green: 83/255, blue: 159/255),        // #00539F
        "homedepot.com": Color(red: 246/255, green: 100/255, blue: 2/255),    // #F66402
        "lowes.com": Color(red: 0/255, green: 68/255, blue: 156/255),         // #00449C
        "myprotein.com": Color(red: 0/255, green: 90/255, blue: 170/255),     // #005AAA
    ]

    static func merchantAccent(for domain: String) -> Color {
        merchantAccents[domain] ?? gray
    }
}
