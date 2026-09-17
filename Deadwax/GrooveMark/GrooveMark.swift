import Foundation

/// Role: One Drop of the needle. Plays is the GrooveMark count, never a stored integer.
struct GrooveMark: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: UUID
    let pressingId: UUID
    let dayKey: Int

    init(id: UUID = UUID(), pressingId: UUID, dayKey: Int) {
        self.id = id
        self.pressingId = pressingId
        self.dayKey = dayKey
    }
}
