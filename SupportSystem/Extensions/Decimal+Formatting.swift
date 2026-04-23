import Foundation

extension Decimal {
    func currencyFormatted(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: self as NSDecimalNumber) ?? "$\(self)"
    }

    func currencyFormatted(code: String?) -> String {
        currencyFormatted(code: code ?? "USD")
    }
}
