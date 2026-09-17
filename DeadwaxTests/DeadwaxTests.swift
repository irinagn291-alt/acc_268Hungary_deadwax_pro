import XCTest
@testable import Deadwax

/// Family invariant: One external catalog. Stay in one domain. Rate + local notes. Scan only if the domain has a code.
@MainActor
final class DeadwaxTests: XCTestCase {
    func testFamilyInvariant_oneExternalCatalog_rateAndLocalNotes_scanWhenDomainHasCode() async throws {
        let invariant = "One external catalog. Stay in one domain. Rate + local notes. Scan only if the domain has a code."
        XCTAssertTrue(invariant.contains("One external catalog"))
        XCTAssertTrue(invariant.contains("Stay in one domain"))
        XCTAssertTrue(invariant.contains("Rate + local notes"))
        XCTAssertTrue(invariant.contains("Scan only if the domain has a code"))

        let request = CatalogClient.searchRequest(query: "coltrane", page: 1)
        XCTAssertEqual(request.url?.host, CatalogClient.searchHost)
        XCTAssertFalse(request.url?.absoluteString.contains("openfoodfacts") ?? true)
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)

        let cover = CatalogClient.frontURL(mbid: "f90e2c0f-8a4b-4d2e-9c1a-7b6d5e4c3b2a")
        XCTAssertEqual(cover.host, CatalogClient.coverHost)

        let store = WallStore(vault: MemoryVault(), client: CatalogClient(transport: FailingTransport()))
        await store.installDemoCrate()

        for pressing in store.document.pressings {
            XCTAssertFalse(pressing.title.isEmpty)
            XCTAssertFalse(pressing.artist.isEmpty)
        }

        let mint = try XCTUnwrap(store.mintSleeves.first)
        do {
            try await store.gradeSleeve(mint.id, pips: 4)
            XCTFail("Mint must not take a grade")
        } catch WallFault.stillMint {
        }

        do {
            try await store.inscribeNote(mint.id, note: "keep this off taste")
            XCTFail("Mint must not take a local note")
        } catch WallFault.stillMint {
        }

        XCTAssertFalse(store.tasteByGenre.contains { fold in fold.bucket == mint.genre && store.mintSleeves.contains { $0.genre == mint.genre && store.document.grades[$0.id] != nil } })
        XCTAssertFalse(store.tasteByGenre.contains { $0.bucket == mint.title })

        let grooved = try XCTUnwrap(store.groovedSleeves.first)
        try await store.gradeSleeve(grooved.id, pips: 4)
        try await store.inscribeNote(grooved.id, note: "Heard copy, local only.")
        await store.flush()
        XCTAssertEqual(store.document.grades[grooved.id], 4)
        XCTAssertEqual(store.document.notes[grooved.id], "Heard copy, local only.")
        XCTAssertTrue(store.tasteByGenre.contains { $0.groovedCount > 0 })

        let fromQR = SleeveCode.candidates(from: "https://deadwax-wall.pro/code/007464635262")
        XCTAssertTrue(fromQR.contains("007464635262"))
        XCTAssertTrue(fromQR.contains("0007464635262") || fromQR.contains("007464635262"))
    }

    func testPrimaryVerbDrop_emptyPopulatedInvalid() async throws {
        let store = WallStore(vault: MemoryVault(), client: CatalogClient(transport: FailingTransport()))
        await store.restore()
        XCTAssertFalse(store.dropIsEnabled)

        do {
            _ = try await store.dropNeedle(UUID())
            XCTFail("empty wall has no sleeve")
        } catch WallFault.unknownPressing {
        }

        let hit = CatalogHit(
            musicBrainzId: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            artist: "Alice Coltrane",
            title: "Journey in Satchidananda",
            label: "Impulse",
            genre: "Jazz",
            catalogCode: "AS-9203",
            barcode: "0011105092032",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee").absoluteString
        )
        let pressing = await store.sleeve(hit)
        XCTAssertTrue(store.dropIsEnabled)
        XCTAssertEqual(pressing.groove, .mint)
        XCTAssertEqual(store.plays(for: pressing.id), 0)

        let grooved = try await store.dropNeedle(pressing.id)
        XCTAssertEqual(grooved.groove, .grooved)
        XCTAssertEqual(store.plays(for: pressing.id), 1)

        do {
            _ = try await store.dropNeedle(UUID())
            XCTFail("unknown id")
        } catch WallFault.unknownPressing {
        }
    }

    func testTwistDropThenGroove_gradeAndTasteFoldOnlyGrooved() async throws {
        let store = WallStore(vault: MemoryVault(), client: CatalogClient(transport: FailingTransport()))
        let hit = CatalogHit(
            musicBrainzId: "bbbbbbbb-cccc-dddd-eeee-ffffffffffff",
            artist: "A Tribe Called Quest",
            title: "The Low End Theory",
            label: "Jive",
            genre: "Hip-hop",
            catalogCode: "1418-1-J",
            barcode: "0012414141815",
            sleeveFrontURL: CatalogClient.frontURL(mbid: "bbbbbbbb-cccc-dddd-eeee-ffffffffffff").absoluteString
        )
        let pressing = await store.sleeve(hit)
        XCTAssertEqual(pressing.groove, .mint, "search or scan writes Mint")
        XCTAssertTrue(store.document.marks.isEmpty, "Mint never writes a GrooveMark")
        XCTAssertTrue(store.tasteByGenre.isEmpty, "an unplayed sleeve never enters taste")

        _ = try await store.dropNeedle(pressing.id)
        XCTAssertEqual(store.document.pressings.first?.groove, .grooved)
        XCTAssertEqual(store.plays(for: pressing.id), store.document.marks.count)

        try await store.gradeSleeve(pressing.id, pips: 5)
        XCTAssertEqual(store.tasteByGenre.first?.bucket, "Hip-hop")
        XCTAssertEqual(store.tasteByLabel.first?.bucket, "Jive")

        _ = try await store.dropNeedle(pressing.id)
        XCTAssertEqual(store.plays(for: pressing.id), 2)

        try await store.peelLastMark(pressing.id)
        XCTAssertEqual(store.plays(for: pressing.id), 1)
        XCTAssertEqual(store.document.pressings.first?.groove, .grooved)

        try await store.peelLastMark(pressing.id)
        XCTAssertEqual(store.plays(for: pressing.id), 0)
        XCTAssertEqual(store.document.pressings.first?.groove, .mint)
        XCTAssertNil(store.document.grades[pressing.id])
        XCTAssertTrue(store.tasteByGenre.isEmpty)
    }

    func testArchitectureGrooveADT_playsAreMarkCount() async throws {
        let store = WallStore(vault: MemoryVault(), client: CatalogClient(transport: FailingTransport()))
        await store.installDemoCrate()
        for pressing in store.document.pressings {
            XCTAssertEqual(store.plays(for: pressing.id), store.document.marks.filter { $0.pressingId == pressing.id }.count)
            if store.plays(for: pressing.id) == 0 {
                XCTAssertEqual(pressing.groove, .mint)
            } else {
                XCTAssertEqual(pressing.groove, .grooved)
            }
        }
        XCTAssertGreaterThan(store.heardWalk.count, 1)
        XCTAssertTrue(store.mintSleeves.contains { $0.groove == .mint })
        XCTAssertTrue(store.groovedSleeves.contains { $0.groove == .grooved })
        XCTAssertTrue(store.dropIsEnabled)
        XCTAssertTrue(store.document.onboardingComplete)
    }

    func testReviewLaneParsesTodayLogGoalsAsThreeDifferentSegments() {
        let today = ReviewLane.parse(["-ReviewScreen", "today"])
        let log = ReviewLane.parse(["-ReviewScreen", "log"])
        let goals = ReviewLane.parse(["-ReviewScreen", "goals"])
        XCTAssertEqual(today, .today)
        XCTAssertEqual(log, .log)
        XCTAssertEqual(goals, .goals)
        XCTAssertEqual(today?.destination, .segment(.discover))
        XCTAssertEqual(log?.destination, .segment(.heard))
        XCTAssertEqual(goals?.destination, .segment(.taste))
        XCTAssertNotEqual(today, log)
        XCTAssertNotEqual(log, goals)
        XCTAssertNotEqual(today, goals)
        XCTAssertNotEqual(today?.destination, log?.destination)
        XCTAssertNotEqual(log?.destination, goals?.destination)
        XCTAssertNotEqual(today?.destination, goals?.destination)
        XCTAssertNil(ReviewLane.parse(["-SomethingElse", "today"]))
        XCTAssertNil(ReviewLane.parse(["-ReviewScreen"]))
        XCTAssertEqual(
            ReviewLane.parse(ProcessInfo.processInfo.arguments),
            ReviewLane.parse()
        )
        XCTAssertTrue(ReviewLane.isReviewLaunch(arguments: ["-ReviewScreen", "today"]))
    }

    func testReviewLaneExtraCoverSlugsOpenNamedScreens() {
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "discover"])?.destination, .segment(.discover))
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "crate"])?.destination, .segment(.crate))
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "seen"])?.destination, .segment(.heard))
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "profile"])?.destination, .segment(.taste))
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "scan"])?.destination, .scan)
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "settings"])?.destination, .settings)
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "home"])?.destination, .segment(.discover))
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "heard"])?.destination, .segment(.heard))
        XCTAssertEqual(ReviewLane.parse(["-ReviewScreen", "taste"])?.destination, .segment(.taste))
        XCTAssertNotEqual(
            ReviewLane.parse(["-ReviewScreen", "crate"])?.destination,
            ReviewLane.parse(["-ReviewScreen", "today"])?.destination
        )
        XCTAssertNotEqual(
            ReviewLane.parse(["-ReviewScreen", "scan"])?.destination,
            ReviewLane.parse(["-ReviewScreen", "today"])?.destination
        )
        XCTAssertNotEqual(
            ReviewLane.parse(["-ReviewScreen", "settings"])?.destination,
            ReviewLane.parse(["-ReviewScreen", "today"])?.destination
        )
        XCTAssertNotEqual(
            ReviewLane.parse(["-ReviewScreen", "scan"])?.destination,
            ReviewLane.parse(["-ReviewScreen", "log"])?.destination
        )
        XCTAssertNotEqual(
            ReviewLane.parse(["-ReviewScreen", "settings"])?.destination,
            ReviewLane.parse(["-ReviewScreen", "goals"])?.destination
        )
        XCTAssertNil(ReviewLane.parse(["-ReviewScreen", "unknown"]))
    }

    func testReviewLaneConsumesOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            ReviewLane.consume(
                arguments: ["-ReviewScreen", "log"],
                onboarded: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = ReviewLane.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboarded: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            ReviewLane.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboarded: true,
                consumed: &consumed
            )
        )
    }

    func testReviewLaneApplySwitchesLiveNavigation() {
        let store = WallStore(
            vault: MemoryVault(document: .demoCrate(), planted: true),
            client: CatalogClient(transport: FailingTransport())
        )
        let chrome = WallChrome(store: store)
        chrome.apply(.today)
        XCTAssertEqual(chrome.segment, .discover)
        XCTAssertFalse(chrome.showingScan)
        XCTAssertFalse(chrome.showingSettings)

        chrome.apply(.log)
        XCTAssertEqual(chrome.segment, .heard)
        XCTAssertFalse(chrome.showingScan)

        chrome.apply(.goals)
        XCTAssertEqual(chrome.segment, .taste)

        chrome.apply(.crate)
        XCTAssertEqual(chrome.segment, .crate)

        chrome.apply(.scan)
        XCTAssertEqual(chrome.segment, .discover)
        XCTAssertTrue(chrome.showingScan)
        XCTAssertFalse(chrome.showingSettings)

        chrome.apply(.settings)
        XCTAssertTrue(chrome.showingSettings)
        XCTAssertFalse(chrome.showingScan)
    }

    func testGradeRejectsInvalidPips() async throws {
        let store = WallStore(vault: MemoryVault(), client: CatalogClient(transport: FailingTransport()))
        await store.installDemoCrate()
        let grooved = try XCTUnwrap(store.groovedSleeves.first)
        do {
            try await store.gradeSleeve(grooved.id, pips: 0)
            XCTFail("0 is not a grade")
        } catch WallFault.badGrade {
        }
        do {
            try await store.gradeSleeve(grooved.id, pips: 6)
            XCTFail("6 is not a grade")
        } catch WallFault.badGrade {
        }
        XCTAssertNil(Grade(pips: 0))
        XCTAssertEqual(Grade(pips: 3)?.pips, 3)
    }

    func testPlayTileMathSixBottomRowIsUneven() {
        let phone = PlayTileMath.frames(count: 6, in: CGSize(width: 390, height: 420))
        XCTAssertEqual(phone.count, 6)
        let phoneBottom = Array(phone.suffix(3))
        let phoneWidths = Set(phoneBottom.map { Int(($0.width * 10).rounded()) })
        let phoneHeights = Set(phoneBottom.map { Int(($0.height * 10).rounded()) })
        XCTAssertGreaterThan(phoneWidths.count, 1, "phone bottom must not be three equal tiles")
        XCTAssertGreaterThan(phoneHeights.count, 1, "phone bottom must mix tile heights")

        let pad = PlayTileMath.frames(count: 6, in: CGSize(width: 1024, height: 680))
        XCTAssertEqual(pad.count, 6)
        let padBottom = Array(pad.suffix(3))
        let padWidths = Set(padBottom.map { Int(($0.width * 10).rounded()) })
        XCTAssertGreaterThan(padWidths.count, 1, "iPad bottom must not be three equal tiles")
    }

    func testTasteGenreBoardUsesUnevenPlayTiles() {
        let frames = PlayTileMath.frames(count: 4, in: CGSize(width: 980, height: 320))
        XCTAssertEqual(frames.count, 4)
        let peerRow = [frames[1], frames[2]]
        let peerWidths = Set(peerRow.map { Int(($0.width * 10).rounded()) })
        XCTAssertEqual(peerWidths.count, 1)
        let peerHeights = Set(peerRow.map { Int(($0.height * 10).rounded()) })
        XCTAssertGreaterThan(peerHeights.count, 1, "Folk/Jazz stack must not be equal-weight")
        XCTAssertGreaterThan(frames[0].width, frames[1].width)
        XCTAssertGreaterThan(frames[3].width, frames[1].width)
    }

    func testDayKeyUsesStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        XCTAssertEqual(WallDay.key(date, calendar: calendar), 20240101)
        XCTAssertEqual(PhonographFigures.whole(3).isEmpty, false)
    }
}

struct FailingTransport: CatalogTransporting {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.notConnectedToInternet)
    }
}
