import Foundation

/// Role: One side of a platter. The deadwax read is stored per side, never as a play count.
enum PlatterSide: String, Codable, CaseIterable, Sendable, Equatable, Hashable, Comparable {
    case a
    case b
    case c
    case d

    var title: String { rawValue.uppercased() }

    static func < (lhs: PlatterSide, rhs: PlatterSide) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Role: The inscription in the quiet ring of one side. Folds only on a Grooved sleeve.
struct RunoutEtching: Codable, Sendable, Equatable, Hashable {
    var side: PlatterSide
    var inscription: String
}

/// Role: Grooved copies that share a mastering mark read from the deadwax. Mint never enters.
struct RunoutFold: Sendable, Equatable, Identifiable {
    var signature: String
    var copyCount: Int

    var id: String { signature }
}

/// Role: Normalize and toggle the short marks collectors actually see in the runout.
enum RunoutScript {
    static let limit = 80

    static func normalized(_ raw: String) -> String {
        let collapsed = raw
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return String(collapsed.prefix(limit))
    }

    static func tokens(_ inscription: String) -> [String] {
        inscription
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    /// Short codes match a whole token so STERLING is not read as RL.
    static func contains(_ inscription: String, plant: String) -> Bool {
        let clean = normalized(inscription)
        if plant.count <= 3 {
            return tokens(clean).contains(plant.uppercased())
        }
        return clean.lowercased().contains(plant.lowercased())
    }

    /// Tapping a mark etches it in uppercase. Tapping the same suffix again lifts it off.
    static func stamped(_ current: String, with plant: String) -> String {
        let mark = plant.uppercased()
        let clean = normalized(current)
        if clean.isEmpty { return normalized(mark) }
        if contains(clean, plant: plant) {
            if clean.uppercased() == mark { return "" }
            let suffix = " " + mark
            if clean.uppercased().hasSuffix(suffix) {
                return normalized(String(clean.dropLast(suffix.count)))
            }
            return clean
        }
        return normalized(clean + " " + mark)
    }
}

/// Role: Fold Grooved runouts into mastering marks. An unread sleeve stays out of the fold.
enum RunoutMath {
    static let handMatrix = "Hand matrix"
    static let plants = ["Sterling", "Porky", "Strawberry", "RL", "Capitol", "Abbey Road", "Pallas", "RTI", "QRP"]

    /// First matching mark wins. Named plants are checked before short codes.
    static func signature(of inscription: String) -> String {
        let clean = RunoutScript.normalized(inscription)
        let blob = clean.lowercased()
        let named = ["Abbey Road", "Strawberry", "Sterling", "Capitol", "Pallas", "Porky"]
        for plant in named where blob.contains(plant.lowercased()) {
            return plant
        }
        let codes = RunoutScript.tokens(clean)
        for plant in ["RTI", "QRP", "RL"] where codes.contains(plant) {
            return plant
        }
        return handMatrix
    }

    static func reading(of inscription: String) -> String {
        let clean = RunoutScript.normalized(inscription)
        guard !clean.isEmpty else { return "" }
        let name = signature(of: clean)
        if name == handMatrix {
            return "Reads as a hand matrix."
        }
        return "Reads as \(name)."
    }

    static func summary(of rows: [RunoutEtching]) -> String {
        rows
            .sorted { $0.side < $1.side }
            .map { "\($0.side.title) · \($0.inscription)" }
            .joined(separator: "  ")
    }

    static func folds(pressings: [Pressing], runouts: [UUID: [RunoutEtching]]) -> [RunoutFold] {
        var counts: [String: Int] = [:]
        for pressing in pressings where pressing.groove == .grooved {
            let signatures = Set(
                (runouts[pressing.id] ?? [])
                    .map(\.inscription)
                    .map(RunoutScript.normalized)
                    .filter { !$0.isEmpty }
                    .map(signature(of:))
            )
            for name in signatures {
                counts[name, default: 0] += 1
            }
        }
        return counts.keys.sorted().map { name in
            RunoutFold(signature: name, copyCount: counts[name] ?? 0)
        }
    }
}
