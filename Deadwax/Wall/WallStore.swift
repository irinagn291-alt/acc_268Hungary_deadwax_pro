import Foundation

enum WallFault: Error, Sendable, Equatable {
    case unknownPressing
    case stillMint
    case badGrade
    case nothingToPeel
}

/// Role: In-memory fold over Pressings. Views call dropNeedle, gradeSleeve, and peelLastMark and never mutate Groove.
@MainActor
final class WallStore {
    private let vault: any WallProjecting
    private let client: CatalogClient
    private let calendar: Calendar
    private var persistTask: Task<Void, Never>?
    private var seekTask: Task<[CatalogHit], Error>?

    private(set) var document: WallDocument
    private(set) var recoveredFromBackup: Bool
    private(set) var startedEmpty: Bool

    init(
        vault: any WallProjecting,
        client: CatalogClient,
        calendar: Calendar = .current
    ) {
        self.vault = vault
        self.client = client
        self.calendar = calendar
        self.document = .empty
        self.recoveredFromBackup = false
        self.startedEmpty = true
    }

    func restore() async {
        let load = await vault.load()
        document = load.document
        recoveredFromBackup = load.recoveredFromBackup
        startedEmpty = load.startedEmpty
        document.repairGrooves()
    }

    func flush() async {
        persistTask?.cancel()
        persistTask = nil
        await vault.save(document)
    }

    func resetAllData() async {
        document = .empty
        await vault.wipe()
        await vault.save(document)
    }

    func markOnboardingComplete() async {
        document.onboardingComplete = true
        await flush()
    }

    func plantSimulatorSeedIfNeeded() async {
        #if targetEnvironment(simulator)
        if await vault.demoPlanted() { return }
        document = .demoCrate()
        await vault.markDemoPlanted()
        await flush()
        #endif
    }

    func installDemoCrate() async {
        document = .demoCrate()
        await flush()
    }

    @discardableResult
    func sleeve(_ hit: CatalogHit) async -> Pressing {
        remember(hit)
        if let existing = document.pressings.first(where: { $0.musicBrainzId == hit.musicBrainzId }) {
            await flush()
            return existing
        }
        let pressing = Pressing(hit: hit, groove: .mint)
        document.pressings.append(pressing)
        await flush()
        return pressing
    }

    @discardableResult
    func dropNeedle(_ id: UUID) async throws -> Pressing {
        guard let index = document.pressings.firstIndex(where: { $0.id == id }) else {
            throw WallFault.unknownPressing
        }
        let mark = GrooveMark(pressingId: id, dayKey: WallDay.key(calendar: calendar))
        document.marks.append(mark)
        document.pressings[index].groove = .grooved
        await flush()
        return document.pressings[index]
    }

    func peelLastMark(_ id: UUID) async throws {
        guard document.pressings.contains(where: { $0.id == id }) else {
            throw WallFault.unknownPressing
        }
        guard let markIndex = document.marks.lastIndex(where: { $0.pressingId == id }) else {
            throw WallFault.nothingToPeel
        }
        document.marks.remove(at: markIndex)
        if document.plays(for: id) == 0 {
            if let index = document.pressings.firstIndex(where: { $0.id == id }) {
                document.pressings[index].groove = .mint
            }
            document.grades[id] = nil
            document.notes[id] = nil
        }
        await flush()
    }

    func gradeSleeve(_ id: UUID, pips: Int) async throws {
        guard let pressing = document.pressings.first(where: { $0.id == id }) else {
            throw WallFault.unknownPressing
        }
        guard pressing.groove == .grooved else {
            throw WallFault.stillMint
        }
        guard let grade = Grade(pips: pips) else {
            throw WallFault.badGrade
        }
        document.grades[id] = grade.pips
        await flush()
    }

    func inscribeNote(_ id: UUID, note: String) async throws {
        guard let pressing = document.pressings.first(where: { $0.id == id }) else {
            throw WallFault.unknownPressing
        }
        guard pressing.groove == .grooved else {
            throw WallFault.stillMint
        }
        document.notes[id] = note
        schedulePersist()
    }

    func seek(_ query: String, page: Int = 1) async throws -> [CatalogHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }
        seekTask?.cancel()
        let shelf = document.shelf
        let client = self.client
        let task = Task<[CatalogHit], Error> {
            do {
                return try await client.search(query: trimmed, page: page)
            } catch is CancellationError {
                throw CatalogFault.cancelled
            } catch let fault as CatalogFault {
                let local = CatalogShelf.matching(trimmed, in: shelf)
                if local.isEmpty { throw fault }
                return local
            } catch {
                let local = CatalogShelf.matching(trimmed, in: shelf)
                if local.isEmpty { throw CatalogFault.transport }
                return local
            }
        }
        seekTask = task
        do {
            let hits = try await task.value
            remember(hits)
            schedulePersist()
            return hits
        } catch is CancellationError {
            throw CatalogFault.cancelled
        }
    }

    func lookupCode(_ raw: String) async throws -> CatalogHit {
        do {
            let hit = try await client.lookup(code: raw)
            remember(hit)
            await flush()
            return hit
        } catch {
            if let local = shelfHit(for: raw) {
                return local
            }
            throw error
        }
    }

    var dropIsEnabled: Bool { document.dropIsEnabled }
    var mintSleeves: [Pressing] { document.mintSleeves() }
    var groovedSleeves: [Pressing] { document.groovedSleeves() }
    var heardWalk: [Pressing] { document.heardWalk() }
    var tasteByGenre: [TasteFold] { document.tasteByGenre() }
    var tasteByLabel: [TasteFold] { document.tasteByLabel() }

    func plays(for id: UUID) -> Int {
        document.plays(for: id)
    }

    private func remember(_ hit: CatalogHit) {
        remember([hit])
    }

    private func remember(_ hits: [CatalogHit]) {
        for hit in hits {
            if let index = document.shelf.firstIndex(where: { $0.musicBrainzId == hit.musicBrainzId }) {
                document.shelf[index] = hit
            } else {
                document.shelf.append(hit)
            }
        }
    }

    private func shelfHit(for raw: String) -> CatalogHit? {
        let codes = Set(SleeveCode.candidates(from: raw))
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return document.shelf.first { row in
            codes.contains(row.barcode) || row.catalogCode.lowercased() == trimmed || row.barcode == raw
        }
    }

    private func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.flush()
        }
    }
}
