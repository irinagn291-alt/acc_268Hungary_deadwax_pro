import Foundation

/// Role: A 1-to-5 grade that folds only on a Grooved sleeve. Taste never reads Mint.
struct Grade: Codable, Sendable, Equatable, Hashable {
    let pips: Int

    init?(pips: Int) {
        guard (1 ... 5).contains(pips) else { return nil }
        self.pips = pips
    }
}

/// Whole numbers for plays, grades, and day keys. Display type is SF Pro via Font.system.
enum PhonographFigures {
    static func whole(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
