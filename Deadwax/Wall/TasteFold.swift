import Foundation

/// Role: Folded Grooved grades by genre or label. Mint never enters this surface.
struct TasteFold: Sendable, Equatable, Identifiable {
    var bucket: String
    var meanPips: Double
    var groovedCount: Int
    var markCount: Int

    var id: String { bucket }
}

enum TasteMath {
    static func folds(
        pressings: [Pressing],
        grades: [UUID: Int],
        marks: [GrooveMark],
        key: (Pressing) -> String
    ) -> [TasteFold] {
        let grooved = pressings.filter { pressing in
            pressing.groove == .grooved && grades[pressing.id] != nil
        }
        var groups: [String: [Pressing]] = [:]
        for pressing in grooved {
            let bucket = key(pressing).trimmingCharacters(in: .whitespacesAndNewlines)
            let name = bucket.isEmpty ? "Unknown" : bucket
            groups[name, default: []].append(pressing)
        }
        return groups.keys.sorted().map { name in
            let rows = groups[name] ?? []
            let pips = rows.compactMap { grades[$0.id] }
            let sum = pips.reduce(0, +)
            let mean = pips.isEmpty ? 0 : Double(sum) / Double(pips.count)
            let ids = Set(rows.map(\.id))
            let markCount = marks.filter { ids.contains($0.pressingId) }.count
            return TasteFold(
                bucket: name,
                meanPips: mean,
                groovedCount: rows.count,
                markCount: markCount
            )
        }
    }
}
