import Foundation

// MARK: - URLResolver

/// Resolves shortened/redirected URLs to their final destination.
/// Uses HEAD requests with manual redirect following.
enum URLResolver {

    // MARK: - Known Shorteners

    private static let shortenerDomains: Set<String> = [
        "amzn.to", "bit.ly", "tinyurl.com", "t.co", "ow.ly",
        "is.gd", "buff.ly", "ltk.com", "liketoknow.it", "shopltk.com",
        "shrsl.com", "clkbank.com", "amzn.com",
    ]

    /// Returns true if this URL is from a known shortener/redirect service.
    static func isKnownShortener(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host(percentEncoded: false)?.lowercased() else {
            return false
        }

        // Check exact domain match and www-prefixed match
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return shortenerDomains.contains(domain)
    }

    /// Resolve a potentially shortened/redirected URL to its final destination.
    /// Returns the original URL if resolution fails or times out.
    static func resolve(_ urlString: String) async -> String {
        guard let startURL = URL(string: urlString) else { return urlString }

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        config.httpShouldSetCookies = false

        // Create session with delegate that prevents auto-redirect
        let delegate = NoRedirectDelegate()
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        var currentURL = startURL
        let maxHops = 5

        for _ in 0..<maxHops {
            // Try HEAD first
            var request = URLRequest(url: currentURL)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 8
            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15",
                forHTTPHeaderField: "User-Agent"
            )

            do {
                let (_, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    return currentURL.absoluteString
                }

                // Check for redirect status
                if (300...399).contains(httpResponse.statusCode),
                   let location = httpResponse.value(forHTTPHeaderField: "Location"),
                   let nextURL = URL(string: location, relativeTo: currentURL) {
                    currentURL = nextURL.absoluteURL
                    continue
                }

                // HEAD gave no redirect — try GET as fallback
                if httpResponse.statusCode == 405 || httpResponse.statusCode == 200 {
                    var getRequest = request
                    getRequest.httpMethod = "GET"
                    let (_, getResponse) = try await session.data(for: getRequest)

                    if let getHTTP = getResponse as? HTTPURLResponse,
                       (300...399).contains(getHTTP.statusCode),
                       let location = getHTTP.value(forHTTPHeaderField: "Location"),
                       let nextURL = URL(string: location, relativeTo: currentURL) {
                        currentURL = nextURL.absoluteURL
                        continue
                    }
                }

                // No more redirects
                return currentURL.absoluteString

            } catch {
                // Timeout or network error — return what we have
                return currentURL.absoluteString
            }
        }

        return currentURL.absoluteString
    }
}

// MARK: - NoRedirectDelegate

/// URLSession delegate that prevents automatic redirect following,
/// allowing us to inspect each hop manually.
private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Return nil to prevent automatic redirect — we handle it manually
        completionHandler(nil)
    }
}
