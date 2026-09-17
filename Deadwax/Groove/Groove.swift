import Foundation

/// Role: Mint | Grooved ADT on a Pressing. Search and scan write Mint. Drop flips to Grooved. Plays are never stored here.
enum Groove: String, Codable, Sendable, Equatable, Hashable {
    case mint
    case grooved
}
