import Foundation

extension String {
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    var withHTTPS: String {
        if hasPrefix("http://") || hasPrefix("https://") {
            return self
        }
        return "https://\(self)"
    }
}
