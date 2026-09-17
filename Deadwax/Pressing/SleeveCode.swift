import Foundation

/// Role: Turns a camera payload, typed field, or pasted URL into catalog-code candidates. Vinyl barcodes and catno only.
enum SleeveCode {
    static func digitRuns(in raw: String) -> [String] {
        let pieces = raw.split { !$0.isNumber }
        return pieces.map(String.init).filter { (8 ... 14).contains($0.count) }
    }

    static func normalize(_ digits: String) -> String {
        if digits.count == 12 {
            return "0" + digits
        }
        return digits
    }

    static func candidates(from raw: String) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for run in digitRuns(in: raw) {
            let padded = normalize(run)
            for item in [run, padded] where seen.insert(item).inserted {
                ordered.append(item)
            }
        }
        return ordered
    }

    static func lucene(for raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let codes = candidates(from: trimmed)
        if codes.isEmpty {
            return "catno:\"\(trimmed)\""
        }
        var parts: [String] = []
        for code in codes {
            parts.append("barcode:\"\(code)\"")
            parts.append("catno:\"\(code)\"")
        }
        return parts.joined(separator: " OR ")
    }
}
