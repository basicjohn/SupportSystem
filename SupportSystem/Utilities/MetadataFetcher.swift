import Foundation

/// Fetches product metadata from a URL by scraping HTML meta tags (Open Graph, Twitter Cards, standard meta).
/// Used when saving links to populate title, description, price, image, etc.
enum MetadataFetcher {

    /// The scraped result
    struct PageMetadata: Sendable {
        var title: String?
        var subtitle: String?
        var description: String?
        var imageURL: String?
        var price: Decimal?
        var priceCurrency: String?
        var siteName: String?
    }

    /// Fetch metadata from a URL string. Returns nil on failure.
    static func fetch(from urlString: String) async -> PageMetadata? {
        // Resolve short links before fetching
        var effectiveURL = urlString
        if URLResolver.isKnownShortener(urlString) {
            effectiveURL = await URLResolver.resolve(urlString)
        }
        guard let url = URL(string: effectiveURL) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Pretend to be Safari so sites don't block us
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Only parse HTML responses
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...399).contains(httpResponse.statusCode) else { return nil }
            }

            guard let html = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .ascii) else {
                return nil
            }

            return parse(html: html)
        } catch {
            return nil
        }
    }

    // MARK: - HTML Parsing

    static func parse(html: String) -> PageMetadata {
        var meta = PageMetadata()

        // --- Open Graph ---
        meta.title = extractMetaContent(html: html, property: "og:title")
        meta.description = extractMetaContent(html: html, property: "og:description")
        meta.imageURL = extractMetaContent(html: html, property: "og:image")
        meta.siteName = extractMetaContent(html: html, property: "og:site_name")

        // --- Twitter Cards fallback ---
        if meta.title == nil {
            meta.title = extractMetaContent(html: html, name: "twitter:title")
        }
        if meta.description == nil {
            meta.description = extractMetaContent(html: html, name: "twitter:description")
        }
        if meta.imageURL == nil {
            meta.imageURL = extractMetaContent(html: html, name: "twitter:image")
        }

        // --- Standard meta fallback ---
        if meta.description == nil {
            meta.description = extractMetaContent(html: html, name: "description")
        }

        // --- HTML <title> fallback ---
        if meta.title == nil {
            meta.title = extractHTMLTitle(html: html)
        }

        // --- Price extraction ---
        // Try product:price:amount (standard e-commerce OG tag)
        if let priceStr = extractMetaContent(html: html, property: "product:price:amount")
            ?? extractMetaContent(html: html, property: "og:price:amount") {
            meta.price = parsePrice(priceStr)
        }

        // Currency
        meta.priceCurrency = extractMetaContent(html: html, property: "product:price:currency")
            ?? extractMetaContent(html: html, property: "og:price:currency")

        // If no OG price, try JSON-LD
        if meta.price == nil {
            if let jsonLDPrice = extractJSONLDPrice(html: html) {
                meta.price = jsonLDPrice.price
                if meta.priceCurrency == nil {
                    meta.priceCurrency = jsonLDPrice.currency
                }
            }
        }

        // Clean social media junk from descriptions (likes, comments, followers, etc.)
        if let description = meta.description {
            let cleaned = cleanDescription(description)
            meta.description = cleaned.isEmpty ? nil : cleaned
        }

        // Generate subtitle from title if it's long
        // Many product pages have "Product Name - Store Name" or "Product | Details"
        if let title = meta.title {
            let cleanTitle = cleanProductTitle(title, siteName: meta.siteName)
            if cleanTitle != title {
                meta.title = cleanTitle
            }
        }

        return meta
    }

    // MARK: - Extraction Helpers

    /// Extract content from <meta property="X" content="Y"> tags
    private static func extractMetaContent(html: String, property: String) -> String? {
        // Match: <meta property="og:title" content="...">
        // Also handles: <meta property='og:title' content='...'>
        // And reversed order: <meta content="..." property="og:title">
        let patterns = [
            #"<meta[^>]*property\s*=\s*["']\#(property)["'][^>]*content\s*=\s*["']([^"']+)["']"#,
            #"<meta[^>]*content\s*=\s*["']([^"']+)["'][^>]*property\s*=\s*["']\#(property)["']"#
        ]

        for pattern in patterns {
            if let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matched = String(html[match])
                // Extract the content value
                if let contentMatch = matched.range(of: #"content\s*=\s*["']([^"']+)["']"#, options: .regularExpression) {
                    let contentStr = String(matched[contentMatch])
                    // Strip content=" and trailing "
                    if let valueStart = contentStr.range(of: #"["']"#, options: .regularExpression),
                       let openQuote = contentStr[valueStart].first {
                        let afterQuote = contentStr[valueStart.upperBound...]
                        let closeChar = String(openQuote)
                        if let valueEnd = afterQuote.range(of: closeChar) {
                            let value = String(afterQuote[..<valueEnd.lowerBound])
                            let decoded = decodeHTMLEntities(value)
                            return decoded.isEmpty ? nil : decoded
                        }
                    }
                }
            }
        }
        return nil
    }

    /// Extract content from <meta name="X" content="Y"> tags
    private static func extractMetaContent(html: String, name: String) -> String? {
        let patterns = [
            #"<meta[^>]*name\s*=\s*["']\#(name)["'][^>]*content\s*=\s*["']([^"']+)["']"#,
            #"<meta[^>]*content\s*=\s*["']([^"']+)["'][^>]*name\s*=\s*["']\#(name)["']"#
        ]

        for pattern in patterns {
            if let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matched = String(html[match])
                if let contentMatch = matched.range(of: #"content\s*=\s*["']([^"']+)["']"#, options: .regularExpression) {
                    let contentStr = String(matched[contentMatch])
                    if let valueStart = contentStr.range(of: #"["']"#, options: .regularExpression),
                       let openQuote = contentStr[valueStart].first {
                        let afterQuote = contentStr[valueStart.upperBound...]
                        let closeChar = String(openQuote)
                        if let valueEnd = afterQuote.range(of: closeChar) {
                            let value = String(afterQuote[..<valueEnd.lowerBound])
                            let decoded = decodeHTMLEntities(value)
                            return decoded.isEmpty ? nil : decoded
                        }
                    }
                }
            }
        }
        return nil
    }

    /// Extract <title>...</title>
    private static func extractHTMLTitle(html: String) -> String? {
        let pattern = #"<title[^>]*>([^<]+)</title>"#
        guard let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]) else {
            return nil
        }
        let matched = String(html[match])
        // Strip <title> and </title>
        guard let start = matched.range(of: ">"),
              let end = matched.range(of: "</", options: .backwards) else {
            return nil
        }
        let value = String(matched[start.upperBound..<end.lowerBound])
        let decoded = decodeHTMLEntities(value).trimmingCharacters(in: .whitespacesAndNewlines)
        return decoded.isEmpty ? nil : decoded
    }

    /// Try to extract price from JSON-LD structured data
    private static func extractJSONLDPrice(html: String) -> (price: Decimal, currency: String?)? {
        // Look for "price" in JSON-LD scripts
        let pattern = #"<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>([\s\S]*?)</script>"#

        var searchRange = html.startIndex..<html.endIndex
        while let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive], range: searchRange) {
            let jsonBlock = String(html[match])

            // Extract the JSON content between > and </script>
            if let start = jsonBlock.range(of: ">"),
               let end = jsonBlock.range(of: "</script>", options: .caseInsensitive) {
                let jsonStr = String(jsonBlock[start.upperBound..<end.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let data = jsonStr.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) {

                    if let result = findPriceInJSON(json) {
                        return result
                    }
                }
            }

            searchRange = match.upperBound..<html.endIndex
        }

        return nil
    }

    /// Recursively search JSON for price/priceCurrency
    private static func findPriceInJSON(_ json: Any) -> (price: Decimal, currency: String?)? {
        if let dict = json as? [String: Any] {
            // Check for "offers" with "price"
            if let offers = dict["offers"] {
                if let result = findPriceInJSON(offers) {
                    return result
                }
            }

            // Check direct price field
            if let priceValue = dict["price"] {
                let currency = dict["priceCurrency"] as? String
                if let priceStr = priceValue as? String, let price = parsePrice(priceStr) {
                    return (price, currency)
                } else if let priceNum = priceValue as? NSNumber {
                    return (Decimal(priceNum.doubleValue), currency)
                }
            }

            // Check lowPrice as fallback
            if let priceValue = dict["lowPrice"] {
                let currency = dict["priceCurrency"] as? String
                if let priceStr = priceValue as? String, let price = parsePrice(priceStr) {
                    return (price, currency)
                } else if let priceNum = priceValue as? NSNumber {
                    return (Decimal(priceNum.doubleValue), currency)
                }
            }
        } else if let array = json as? [Any] {
            for item in array {
                if let result = findPriceInJSON(item) {
                    return result
                }
            }
        }
        return nil
    }

    // MARK: - Utility

    /// Parse a price string like "$349.99" or "349.99" into Decimal
    private static func parsePrice(_ string: String) -> Decimal? {
        let cleaned = string.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Decimal(string: cleaned)
    }

    /// Clean social media engagement metrics from descriptions.
    /// Strips patterns like "123 Likes, 45 Comments", "1.2M Followers", "Shared by 500 people", etc.
    private static func cleanDescription(_ description: String) -> String {
        var cleaned = description

        // Patterns for social media metrics (case-insensitive)
        let patterns: [String] = [
            // "123 Likes, 45 Comments" or "123 likes, 45 comments - Author"
            #"\d[\d,.]*[KkMm]?\s*(likes?|Likes?)\s*[,·•\-–—]\s*\d[\d,.]*[KkMm]?\s*(comments?|Comments?)"#,
            // "123 Comments, 45 Likes" (reversed order)
            #"\d[\d,.]*[KkMm]?\s*(comments?|Comments?)\s*[,·•\-–—]\s*\d[\d,.]*[KkMm]?\s*(likes?|Likes?)"#,
            // Standalone "X Likes" or "X likes"
            #"\d[\d,.]*[KkMm]?\s+[Ll]ikes?\b"#,
            // Standalone "X Comments" or "X comments"
            #"\d[\d,.]*[KkMm]?\s+[Cc]omments?\b"#,
            // "X Followers" or "X followers"
            #"\d[\d,.]*[KkMm]?\s+[Ff]ollowers?\b"#,
            // "X Following"
            #"\d[\d,.]*[KkMm]?\s+[Ff]ollowing\b"#,
            // "X Shares" or "X shares"
            #"\d[\d,.]*[KkMm]?\s+[Ss]hares?\b"#,
            // "X Reposts" / "X retweets" / "X reposts"
            #"\d[\d,.]*[KkMm]?\s+([Rr]eposts?|[Rr]etweets?|[Rr]eplies)\b"#,
            // "X Views" or "X views"
            #"\d[\d,.]*[KkMm]?\s+[Vv]iews?\b"#,
            // "X Posts" (social media context)
            #"\d[\d,.]*[KkMm]?\s+[Pp]osts?\b"#,
            // "Shared by X people"
            #"[Ss]hared by \d[\d,.]*[KkMm]?\s*people"#,
            // "X people like this"
            #"\d[\d,.]*[KkMm]?\s+people like this"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsRange = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
                cleaned = regex.stringByReplacingMatches(in: cleaned, range: nsRange, withTemplate: "")
            }
        }

        // Clean up leftover separators and whitespace
        // Replace multiple spaces/commas/dashes left by removals
        cleaned = cleaned.replacingOccurrences(of: #"\s*[,·•]\s*[,·•]\s*"#, with: ", ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\s*[,·•\-–—]\s*$"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"^\s*[,·•\-–—]\s*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Clean product title by removing site name suffix
    /// "Sony WH-1000XM5 - Amazon.com" → "Sony WH-1000XM5"
    private static func cleanProductTitle(_ title: String, siteName: String?) -> String {
        var cleaned = title

        // Remove " - SiteName", " | SiteName", " : SiteName" patterns
        let separators = [" - ", " | ", " : ", " — ", " – "]
        for separator in separators {
            if let range = cleaned.range(of: separator, options: .backwards) {
                let suffix = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                // Only strip if the suffix matches the site name or common store names
                if let site = siteName, suffix.localizedCaseInsensitiveContains(site) {
                    cleaned = String(cleaned[..<range.lowerBound])
                } else if isStoreName(suffix) {
                    cleaned = String(cleaned[..<range.lowerBound])
                }
            }
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isStoreName(_ name: String) -> Bool {
        let storeNames = [
            "amazon", "amazon.com", "best buy", "bestbuy.com", "target", "target.com",
            "walmart", "walmart.com", "nike", "nike.com", "apple", "ebay", "etsy",
            "home depot", "lowes", "ikea", "wayfair", "sephora", "ulta",
            "newegg", "b&h photo", "rei", "gamestop", "samsung", "dell",
        ]
        return storeNames.contains { name.localizedCaseInsensitiveContains($0) }
    }

    /// Decode common HTML entities
    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&#x27;": "'",
            "&#x2F;": "/",
            "&nbsp;": " ",
            "&#8211;": "–",
            "&#8212;": "—",
            "&#8216;": "'",
            "&#8217;": "'",
            "&#8220;": "\"",
            "&#8221;": "\"",
            "&trade;": "™",
            "&reg;": "®",
            "&copy;": "©",
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        // Handle numeric entities like &#123;
        let numericPattern = #"&#(\d+);"#
        if let regex = try? NSRegularExpression(pattern: numericPattern) {
            let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)
            let matches = regex.matches(in: result, range: nsRange)
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: result),
                   let code = UInt32(result[range]),
                   let scalar = Unicode.Scalar(code) {
                    let charRange = Range(match.range, in: result)!
                    result.replaceSubrange(charRange, with: String(scalar))
                }
            }
        }
        return result
    }
}
