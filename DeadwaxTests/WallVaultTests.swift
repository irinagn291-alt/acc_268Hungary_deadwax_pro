import XCTest
@testable import Deadwax

@MainActor
final class WallVaultTests: XCTestCase {
    func testPersistenceRoundTripWriteReload() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let suite = "dwx.tests.\(UUID().uuidString)"
        let vault = WallVault(source: .suite(suite), folder: folder)
        let store = WallStore(vault: vault, client: CatalogClient(transport: FailingTransport()))
        await store.restore()
        XCTAssertTrue(store.document.pressings.isEmpty)

        let hit = CatalogHit(
            musicBrainzId: "cccccccc-dddd-eeee-ffff-000000000000",
            artist: "J Dilla",
            title: "Donuts",
            label: "Stones Throw",
            genre: "Hip-hop",
            catalogCode: "STH2126",
            barcode: "0659457212612",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "cccccccc-dddd-eeee-ffff-000000000000").absoluteString
        )
        let pressing = await store.sleeve(hit)
        _ = try await store.dropNeedle(pressing.id)
        try await store.gradeSleeve(pressing.id, pips: 5)
        try await store.inscribeNote(pressing.id, note: "Local note on a Grooved copy.")
        await store.flush()

        let reloaded = WallStore(vault: vault, client: CatalogClient(transport: FailingTransport()))
        await reloaded.restore()
        XCTAssertEqual(reloaded.document.pressings.count, 1)
        XCTAssertEqual(reloaded.document.pressings.first?.groove, .grooved)
        XCTAssertEqual(reloaded.plays(for: pressing.id), 1)
        XCTAssertEqual(reloaded.document.grades[pressing.id], 5)
        XCTAssertEqual(reloaded.document.notes[pressing.id], "Local note on a Grooved copy.")
        XCTAssertEqual(reloaded.document.schemaVersion, 1)
        XCTAssertEqual(reloaded.document.shelf.first?.title, "Donuts")

        await store.resetAllData()
        let cleared = WallStore(vault: vault, client: CatalogClient(transport: FailingTransport()))
        await cleared.restore()
        XCTAssertTrue(cleared.document.pressings.isEmpty)

        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: folder)
    }

    func testCorruptPrimaryFallsBackToBackupThenEmpty() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let suite = "dwx.tests.\(UUID().uuidString)"
        let vault = WallVault(source: .suite(suite), folder: folder)
        let store = WallStore(vault: vault, client: CatalogClient(transport: FailingTransport()))
        await store.installDemoCrate()
        await store.flush()

        let box = try XCTUnwrap(UserDefaults(suiteName: suite))
        if let good = box.data(forKey: WallVault.documentKey) {
            box.set(good, forKey: WallVault.backupKey)
        }
        box.set(Data("not-a-wall".utf8), forKey: WallVault.documentKey)

        let recovered = WallStore(vault: vault, client: CatalogClient(transport: FailingTransport()))
        await recovered.restore()
        XCTAssertTrue(recovered.recoveredFromBackup)
        XCTAssertGreaterThan(recovered.document.pressings.count, 1)
        XCTAssertTrue(recovered.dropIsEnabled)

        box.set(Data("still-bad".utf8), forKey: WallVault.documentKey)
        box.set(Data("also-bad".utf8), forKey: WallVault.backupKey)
        try? FileManager.default.removeItem(at: folder.appendingPathComponent("wall.json"))
        try? FileManager.default.removeItem(at: folder.appendingPathComponent("wall.json.backup"))

        let empty = WallStore(vault: vault, client: CatalogClient(transport: FailingTransport()))
        await empty.restore()
        XCTAssertTrue(empty.startedEmpty)
        XCTAssertTrue(empty.document.pressings.isEmpty)

        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: folder)
    }

    func testUnsupportedSchemaDoesNotCrash() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let suite = "dwx.tests.\(UUID().uuidString)"
        let box = try XCTUnwrap(UserDefaults(suiteName: suite))
        box.set(Data("{\"schemaVersion\":99}".utf8), forKey: WallVault.documentKey)
        let vault = WallVault(source: .suite(suite), folder: folder)
        let store = WallStore(vault: vault, client: CatalogClient(transport: FailingTransport()))
        await store.restore()
        XCTAssertTrue(store.startedEmpty)
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: folder)
    }
}
