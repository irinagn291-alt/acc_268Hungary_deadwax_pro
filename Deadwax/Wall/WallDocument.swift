import Foundation

enum WallSchemaFault: Error, Sendable, Equatable {
    case unsupported(Int)
}

/// Role: Codable wall projection. schemaVersion starts at 1. Plays are derived, never stored.
struct WallDocument: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var pressings: [Pressing]
    var marks: [GrooveMark]
    var grades: [UUID: Int]
    var notes: [UUID: String]
    var shelf: [CatalogHit]
    var onboardingComplete: Bool

    static let currentSchema = 1

    static var empty: WallDocument {
        WallDocument(
            schemaVersion: currentSchema,
            pressings: [],
            marks: [],
            grades: [:],
            notes: [:],
            shelf: [],
            onboardingComplete: false
        )
    }

    init(
        schemaVersion: Int = currentSchema,
        pressings: [Pressing],
        marks: [GrooveMark],
        grades: [UUID: Int],
        notes: [UUID: String],
        shelf: [CatalogHit],
        onboardingComplete: Bool
    ) {
        self.schemaVersion = schemaVersion
        self.pressings = pressings
        self.marks = marks
        self.grades = grades
        self.notes = notes
        self.shelf = shelf
        self.onboardingComplete = onboardingComplete
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        let version = try box.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = 1
            pressings = try box.decodeIfPresent([Pressing].self, forKey: .pressings) ?? []
            marks = try box.decodeIfPresent([GrooveMark].self, forKey: .marks) ?? []
            grades = try box.decodeIfPresent([UUID: Int].self, forKey: .grades) ?? [:]
            notes = try box.decodeIfPresent([UUID: String].self, forKey: .notes) ?? [:]
            shelf = try box.decodeIfPresent([CatalogHit].self, forKey: .shelf) ?? []
            onboardingComplete = try box.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? false
        default:
            throw WallSchemaFault.unsupported(version)
        }
    }

    mutating func repairGrooves() {
        var counts: [UUID: Int] = [:]
        for mark in marks {
            counts[mark.pressingId, default: 0] += 1
        }
        for index in pressings.indices {
            pressings[index].alignGroove(playCount: counts[pressings[index].id] ?? 0)
        }
        let groovedIds = Set(pressings.filter { $0.groove == .grooved }.map(\.id))
        grades = grades.filter { groovedIds.contains($0.key) }
        notes = notes.filter { groovedIds.contains($0.key) }
    }

    func plays(for pressingId: UUID) -> Int {
        marks.filter { $0.pressingId == pressingId }.count
    }

    func mintSleeves() -> [Pressing] {
        pressings.filter { $0.groove == .mint }
    }

    func groovedSleeves() -> [Pressing] {
        pressings.filter { $0.groove == .grooved }
    }

    func heardWalk() -> [Pressing] {
        marks.compactMap { mark in
            pressings.first { $0.id == mark.pressingId && $0.groove == .grooved }
        }
    }

    func tasteByGenre() -> [TasteFold] {
        TasteMath.folds(pressings: pressings, grades: grades, marks: marks, key: \.genre)
    }

    func tasteByLabel() -> [TasteFold] {
        TasteMath.folds(pressings: pressings, grades: grades, marks: marks, key: \.label)
    }

    var dropIsEnabled: Bool {
        !pressings.isEmpty
    }

    static func demoCrate() -> WallDocument {
        let one = Pressing(
            id: DemoIDs.kindOfBlue,
            musicBrainzId: "f90e2c0f-8a4b-4d2e-9c1a-7b6d5e4c3b2a",
            artist: "Miles Davis",
            title: "Kind of Blue",
            label: "Columbia",
            genre: "Jazz",
            catalogCode: "CS 8163",
            barcode: "0074646352621",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "f90e2c0f-8a4b-4d2e-9c1a-7b6d5e4c3b2a").absoluteString,
            groove: .grooved
        )
        let two = Pressing(
            id: DemoIDs.unknownPleasures,
            musicBrainzId: "a1b2c3d4-e5f6-4718-9a0b-1c2d3e4f5a6b",
            artist: "Joy Division",
            title: "Unknown Pleasures",
            label: "Factory",
            genre: "Post-punk",
            catalogCode: "FACT 10",
            barcode: "0825646183926",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "a1b2c3d4-e5f6-4718-9a0b-1c2d3e4f5a6b").absoluteString,
            groove: .grooved
        )
        let three = Pressing(
            id: DemoIDs.blueTrain,
            musicBrainzId: "b2c3d4e5-f6a7-4829-0b1c-2d3e4f5a6b7c",
            artist: "John Coltrane",
            title: "Blue Train",
            label: "Blue Note",
            genre: "Jazz",
            catalogCode: "BLP 1577",
            barcode: "0724353206424",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "b2c3d4e5-f6a7-4829-0b1c-2d3e4f5a6b7c").absoluteString,
            groove: .mint
        )
        let four = Pressing(
            id: DemoIDs.homogenic,
            musicBrainzId: "c3d4e5f6-a7b8-4930-1c2d-3e4f5a6b7c8d",
            artist: "Bjork",
            title: "Homogenic",
            label: "One Little Indian",
            genre: "Electronic",
            catalogCode: "TPLP71",
            barcode: "5016958031015",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "c3d4e5f6-a7b8-4930-1c2d-3e4f5a6b7c8d").absoluteString,
            groove: .grooved
        )
        let five = Pressing(
            id: DemoIDs.dummy,
            musicBrainzId: "d4e5f6a7-b8c9-4a41-2d3e-4f5a6b7c8d9e",
            artist: "Portishead",
            title: "Dummy",
            label: "Go Beat",
            genre: "Trip-hop",
            catalogCode: "828 522-1",
            barcode: "0042282852214",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "d4e5f6a7-b8c9-4a41-2d3e-4f5a6b7c8d9e").absoluteString,
            groove: .mint
        )
        let six = Pressing(
            id: DemoIDs.goldRush,
            musicBrainzId: "e5f6a7b8-c9d0-4b52-3e4f-5a6b7c8d9e0f",
            artist: "Neil Young",
            title: "After the Gold Rush",
            label: "Reprise",
            genre: "Folk",
            catalogCode: "RS 6383",
            barcode: "0093624978893",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "e5f6a7b8-c9d0-4b52-3e4f-5a6b7c8d9e0f").absoluteString,
            groove: .grooved
        )
        let pressings = [one, two, three, four, five, six]
        let marks = [
            GrooveMark(id: DemoIDs.mark1, pressingId: one.id, dayKey: 20260910),
            GrooveMark(id: DemoIDs.mark2, pressingId: one.id, dayKey: 20260912),
            GrooveMark(id: DemoIDs.mark3, pressingId: two.id, dayKey: 20260913),
            GrooveMark(id: DemoIDs.mark4, pressingId: four.id, dayKey: 20260914),
            GrooveMark(id: DemoIDs.mark5, pressingId: six.id, dayKey: 20260915),
            GrooveMark(id: DemoIDs.mark6, pressingId: one.id, dayKey: 20260916),
        ]
        var document = WallDocument(
            schemaVersion: currentSchema,
            pressings: pressings,
            marks: marks,
            grades: [
                one.id: 5,
                two.id: 4,
                four.id: 5,
                six.id: 3,
            ],
            notes: [
                one.id: "The Columbia stereo still opens the room.",
                two.id: "Factory sleeve, first needle drop this month.",
            ],
            shelf: pressings.map { pressing in
                CatalogHit(
                    musicBrainzId: pressing.musicBrainzId,
                    artist: pressing.artist,
                    title: pressing.title,
                    label: pressing.label,
                    genre: pressing.genre,
                    catalogCode: pressing.catalogCode,
                    barcode: pressing.barcode,
                    sleeveFrontURL: pressing.sleeveFrontURL
                )
            },
            onboardingComplete: true
        )
        document.repairGrooves()
        return document
    }
}

enum DemoIDs {
    /// Fixed UUIDs for the Simulator crate. These literals always parse.
    static let kindOfBlue = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let unknownPleasures = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let blueTrain = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let homogenic = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let dummy = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let goldRush = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    static let mark1 = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!
    static let mark2 = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2")!
    static let mark3 = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3")!
    static let mark4 = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4")!
    static let mark5 = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5")!
    static let mark6 = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6")!
}
