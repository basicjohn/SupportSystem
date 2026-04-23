import Foundation

// MARK: - DetectedCode

/// A code found in a URL by the detection engine
struct DetectedCode {
    let code: String
    let type: CodeType
    let source: CodeSource
    let paramName: String?      // nil for path-based
    let confidence: Confidence

    enum CodeSource: String, Codable {
        case queryParam, pathSegment, subdomain
    }

    enum Confidence: Int, Comparable {
        case low = 1, medium = 2, high = 3
        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }
}

// MARK: - CodeDetector

enum CodeDetector {

    /// Detect all affiliate/referral/coupon codes in a URL.
    /// Returns results sorted by confidence descending, deduplicated by code value.
    static func detect(in urlString: String) -> [DetectedCode] {
        guard let components = URLComponents(string: urlString) else { return [] }

        var results: [DetectedCode] = []

        // Layer 1: Query param detection
        results.append(contentsOf: detectQueryParams(in: components))

        // Layer 2: Path-based detection
        results.append(contentsOf: detectPathSegments(in: components))

        // Deduplicate by code value (keep highest confidence)
        var seen = Set<String>()
        var deduped: [DetectedCode] = []
        // Already sorted by confidence desc
        let sorted = results.sorted { $0.confidence > $1.confidence }
        for result in sorted {
            let key = result.code.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                deduped.append(result)
            }
        }

        return deduped
    }

    // MARK: - Layer 1: Query Param Detection

    private static func detectQueryParams(in components: URLComponents) -> [DetectedCode] {
        guard let queryItems = components.queryItems else { return [] }

        var results: [DetectedCode] = []

        for item in queryItems {
            guard let value = item.value, isValidCodeValue(value) else { continue }

            let paramLower = item.name.lowercased()

            // High confidence — network-specific params
            if let type = highConfidenceParams[paramLower] {
                results.append(DetectedCode(
                    code: value, type: type, source: .queryParam,
                    paramName: item.name, confidence: .high
                ))
                continue
            }

            // Medium confidence — common generic params
            if let type = mediumConfidenceParams[paramLower] {
                results.append(DetectedCode(
                    code: value, type: type, source: .queryParam,
                    paramName: item.name, confidence: .medium
                ))
                continue
            }

            // Low confidence — fuzzy suffix matching
            if looksLikeCodeParam(paramLower) && looksLikeCodeValue(value) {
                results.append(DetectedCode(
                    code: value, type: .affiliate, source: .queryParam,
                    paramName: item.name, confidence: .low
                ))
            }
        }

        return results
    }

    // MARK: - High Confidence Params

    private static let highConfidenceParams: [String: CodeType] = [
        // Amazon Associates
        "tag": .affiliate,
        // ShareASale
        "sscid": .affiliate,
        "afftrack": .affiliate,
        // CJ Affiliate
        "cjevent": .affiliate,
        // Impact
        "irclickid": .affiliate,
        "irgwc": .affiliate,
        // Rakuten
        "ranmid": .affiliate,
        "ransiteid": .affiliate,
        "raneaid": .affiliate,
        // ClickBank
        "hop": .affiliate,
        // Skimlinks
        "xs": .affiliate,
        // Partnerize
        "pcid": .affiliate,
        "data_s_cid": .affiliate,
        // Various networks
        "subid": .affiliate,
        "sub_id": .affiliate,
        // Partnerize/PepperJam
        "clickref": .affiliate,
        // Offer IDs
        "offerid": .affiliate,
        "offer_id": .affiliate,
        // Affiliate IDs
        "affid": .affiliate,
        "aff_id": .affiliate,
        "affiliate_id": .affiliate,
        // Publisher IDs
        "pid": .affiliate,
        "publisherid": .affiliate,
        "publisher_id": .affiliate,
        // Site IDs
        "sid": .affiliate,
        "site_id": .affiliate,
    ]

    // MARK: - Medium Confidence Params

    private static let mediumConfidenceParams: [String: CodeType] = [
        // Referral
        "ref": .referral,
        "referral": .referral,
        "referrer": .referral,
        "via": .referral,
        "share": .referral,
        "shared_by": .referral,
        "invite": .referral,
        "invite_code": .referral,
        // Affiliate
        "aff": .affiliate,
        "affiliate": .affiliate,
        "partner": .affiliate,
        // Creator
        "influencer": .creatorCode,
        "creator": .creatorCode,
        "source_creator": .creatorCode,
        "creator_code": .creatorCode,
        // Coupon
        "code": .coupon,
        "coupon": .coupon,
        "promo": .coupon,
        "discount": .coupon,
        "voucher": .coupon,
        "offer": .coupon,
        "deal": .coupon,
        "cc": .coupon,
        "promo_code": .coupon,
        "coupon_code": .coupon,
        "discount_code": .coupon,
        "promocode": .coupon,
    ]

    // MARK: - Low Confidence: Fuzzy Suffix Matching

    private static let codeSuffixes = ["_ref", "_aff", "_tag", "_code", "_id"]

    private static func looksLikeCodeParam(_ param: String) -> Bool {
        codeSuffixes.contains(where: { param.hasSuffix($0) })
    }

    /// Value looks like a code: alphanumeric, 3-30 chars, not pure number, not UUID
    private static func looksLikeCodeValue(_ value: String) -> Bool {
        guard (3...30).contains(value.count) else { return false }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        guard value.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }

        // Not a pure number
        if value.allSatisfy({ $0.isNumber }) { return false }

        // Not a UUID
        if isUUID(value) { return false }

        // Not a pure hex hash (>20 chars all hex)
        if isPureHexHash(value) { return false }

        return true
    }

    // MARK: - Layer 2: Path-Based Detection

    private static let pathPatterns: [(keyword: String, type: CodeType, confidence: DetectedCode.Confidence)] = [
        ("shop", .creatorCode, .high),
        ("discount", .coupon, .high),
        ("coupon", .coupon, .high),
        ("voucher", .coupon, .medium),
        ("ref", .referral, .medium),
        ("referral", .referral, .medium),
        ("promo", .coupon, .medium),
        ("a", .affiliate, .low),
        ("go", .affiliate, .low),
        ("r", .referral, .low),
    ]

    private static let structuralKeywords: Set<String> = [
        "products", "product", "collections", "collection", "pages", "page",
        "blogs", "blog", "categories", "category", "search", "cart", "checkout",
        "account", "dp", "gp", "b", "s", "p", "ip", "itm", "i", "item", "items",
        "index", "home", "about", "contact", "help", "faq", "terms", "privacy",
        "login", "register", "profile", "settings", "orders", "wishlist", "favorites",
    ]

    private static func detectPathSegments(in components: URLComponents) -> [DetectedCode] {
        let segments = components.path
            .split(separator: "/")
            .map(String.init)

        var results: [DetectedCode] = []

        for (index, segment) in segments.enumerated() {
            let segmentLower = segment.lowercased()
            for pattern in pathPatterns {
                if segmentLower == pattern.keyword,
                   index + 1 < segments.count {
                    let code = segments[index + 1]
                    if isValidPathCode(code) {
                        results.append(DetectedCode(
                            code: code, type: pattern.type, source: .pathSegment,
                            paramName: pattern.keyword, confidence: pattern.confidence
                        ))
                    }
                }
            }
        }

        return results
    }

    private static func isValidPathCode(_ code: String) -> Bool {
        guard (2...50).contains(code.count) else { return false }

        // Not a structural keyword
        if structuralKeywords.contains(code.lowercased()) { return false }

        // Not a pure number
        if code.allSatisfy({ $0.isNumber }) { return false }

        return true
    }

    // MARK: - Value Filtering

    private static func isValidCodeValue(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        guard (2...50).contains(value.count) else { return false }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        guard value.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }

        // Not a UUID (contains 4 hyphens in 8-4-4-4-12 pattern)
        if isUUID(value) { return false }

        // Not a pure number > 10 digits
        if value.allSatisfy({ $0.isNumber }) && value.count > 10 { return false }

        // Not a pure hex hash > 20 chars
        if isPureHexHash(value) { return false }

        return true
    }

    private static func isUUID(_ value: String) -> Bool {
        let hyphens = value.filter { $0 == "-" }.count
        return hyphens == 4 && value.count == 36
    }

    private static func isPureHexHash(_ value: String) -> Bool {
        guard value.count > 20 else { return false }
        let hexChars = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return value.unicodeScalars.allSatisfy { hexChars.contains($0) }
    }
}
