import Foundation
import CryptoKit

enum URLUtilities {
    /// Extract the merchant domain from a URL string.
    /// "https://www.amazon.com/dp/B09XS7JWHH?tag=mkbhd-20" -> "amazon.com"
    static func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host(percentEncoded: false)?.lowercased() else {
            return nil
        }

        var domain = host

        // Strip common prefixes
        let prefixes = ["www.", "m.", "shop.", "store.", "buy."]
        for prefix in prefixes {
            if domain.hasPrefix(prefix) {
                domain = String(domain.dropFirst(prefix.count))
                break
            }
        }

        // Handle known subdomain mappings
        let subdomainMappings: [String: String] = [
            "smile.amazon.com": "amazon.com",
            "music.amazon.com": "amazon.com",
            "prime.amazon.com": "amazon.com",
        ]

        if let mapped = subdomainMappings[host.lowercased()] {
            return mapped
        }

        return domain
    }

    /// Normalize a URL for deduplication.
    /// Strips tracking params, normalizes scheme/host, sorts query params.
    static func normalizeURL(_ urlString: String) -> String? {
        guard var components = URLComponents(string: urlString) else { return nil }

        // Normalize scheme
        components.scheme = "https"

        // Normalize host
        if let host = components.host {
            var normalized = host.lowercased()
            if normalized.hasPrefix("www.") {
                normalized = String(normalized.dropFirst(4))
            }
            components.host = normalized
        }

        // Remove tracking params
        // Note: ref, ref_, source, src intentionally excluded — they are often
        // affiliate/referral params and should be preserved for code detection.
        let trackingParams: Set<String> = [
            "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
            "fbclid", "gclid", "gclsrc", "mc_cid", "mc_eid",
            "_ga", "_gl", "yclid", "twclid"
        ]

        if let queryItems = components.queryItems {
            let filtered = queryItems.filter { !trackingParams.contains($0.name.lowercased()) }
            components.queryItems = filtered.isEmpty ? nil : filtered.sorted { $0.name < $1.name }
        }

        // Remove fragment
        components.fragment = nil

        // Remove trailing slash from path
        if components.path.hasSuffix("/") && components.path.count > 1 {
            components.path = String(components.path.dropLast())
        }

        return components.string
    }

    /// SHA256 hash of normalized URL for deduplication.
    static func hashURL(_ urlString: String) -> String? {
        guard let normalized = normalizeURL(urlString) else { return nil }
        let data = Data(normalized.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Detect affiliate/referral codes in URL parameters.
    /// Returns the highest-confidence match. Delegates to CodeDetector.
    static func detectAffiliateCode(in urlString: String) -> (code: String, type: CodeType)? {
        let results = CodeDetector.detect(in: urlString)
        guard let best = results.first else { return nil }
        return (best.code, best.type)
    }

    /// Detect all affiliate/referral/coupon codes in a URL.
    /// Returns results sorted by confidence descending.
    static func detectAffiliateCodes(in urlString: String) -> [DetectedCode] {
        return CodeDetector.detect(in: urlString)
    }
}
