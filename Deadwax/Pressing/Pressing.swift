import Foundation

/// Role: A catalogued vinyl copy on the wall. Search or scan writes Mint and never a GrooveMark.
struct Pressing: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: UUID
    var musicBrainzId: String
    var artist: String
    var title: String
    var label: String
    var genre: String
    var catalogCode: String
    var barcode: String
    var sleeveFrontURL: String
    var groove: Groove

    init(
        id: UUID = UUID(),
        musicBrainzId: String,
        artist: String,
        title: String,
        label: String,
        genre: String,
        catalogCode: String,
        barcode: String,
        sleeveFrontURL: String,
        groove: Groove = .mint
    ) {
        self.id = id
        self.musicBrainzId = musicBrainzId
        self.artist = artist
        self.title = title
        self.label = label
        self.genre = genre
        self.catalogCode = catalogCode
        self.barcode = barcode
        self.sleeveFrontURL = sleeveFrontURL
        self.groove = groove
    }

    init(hit: CatalogHit, groove: Groove = .mint) {
        self.init(
            musicBrainzId: hit.musicBrainzId,
            artist: hit.artist,
            title: hit.title,
            label: hit.label,
            genre: hit.genre,
            catalogCode: hit.catalogCode,
            barcode: hit.barcode,
            sleeveFrontURL: hit.sleeveFrontURL,
            groove: groove
        )
    }

    mutating func alignGroove(playCount: Int) {
        groove = playCount == 0 ? .mint : .grooved
    }
}

/// Role: A resolved MusicBrainz row cached on the local shelf so failed search still sleeves.
struct CatalogHit: Identifiable, Codable, Sendable, Equatable, Hashable {
    var musicBrainzId: String
    var artist: String
    var title: String
    var label: String
    var genre: String
    var catalogCode: String
    var barcode: String
    var sleeveFrontURL: String

    var id: String { musicBrainzId }
}

enum CatalogShelf {
    static func matching(_ query: String, in rows: [CatalogHit]) -> [CatalogHit] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        return rows.filter { row in
            row.title.lowercased().contains(needle)
                || row.artist.lowercased().contains(needle)
                || row.label.lowercased().contains(needle)
                || row.catalogCode.lowercased().contains(needle)
                || row.barcode.contains(needle)
                || row.genre.lowercased().contains(needle)
        }
    }
}
