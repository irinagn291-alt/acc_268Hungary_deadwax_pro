import XCTest
@testable import Deadwax

final class CatalogClientTests: XCTestCase {
    func testCgiSearchPlMapsOntoMusicBrainzLimitOffset() throws {
        let page2 = CatalogClient.searchRequest(query: "blue train", page: 2, pageSize: 24)
        let url = try XCTUnwrap(page2.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let keyed = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        XCTAssertEqual(url.host, "musicbrainz.org")
        XCTAssertEqual(url.path, "/ws/2/release")
        XCTAssertEqual(keyed["fmt"], "json")
        XCTAssertEqual(keyed["query"], "blue train")
        XCTAssertEqual(keyed["limit"], "24")
        XCTAssertEqual(keyed["offset"], "24")
        XCTAssertNil(keyed["search_terms"])
        XCTAssertFalse(url.absoluteString.contains("openfoodfacts"))
        XCTAssertEqual(page2.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        XCTAssertEqual(page2.timeoutInterval, 15)
    }

    func testDTOMapsHyphenKeysThenDomainHit() async throws {
        let transport = StubTransport { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
            let url = try XCTUnwrap(request.url)
            return (CatalogFixtures.releaseJSON, CatalogFixtures.response(url, 200))
        }
        let client = CatalogClient(transport: transport)
        let hits = try await client.search(query: "kind of blue", page: 1)
        let hit = try XCTUnwrap(hits.first)
        XCTAssertEqual(hit.musicBrainzId, "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
        XCTAssertEqual(hit.artist, "Miles Davis")
        XCTAssertEqual(hit.title, "Kind of Blue")
        XCTAssertEqual(hit.label, "Columbia")
        XCTAssertEqual(hit.catalogCode, "CS 8163")
        XCTAssertEqual(hit.barcode, "0074646352621")
        XCTAssertEqual(hit.genre, "jazz")
        XCTAssertTrue(hit.sleeveFrontURL.contains("coverartarchive.org/release/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/front-250"))
    }

    func testLookupMissingIsDistinctAndNotRetriedOn404() async throws {
        let log = RequestLog()
        let transport = StubTransport { request in
            await log.append(request.url)
            let url = try XCTUnwrap(request.url)
            return (Data("{}".utf8), CatalogFixtures.response(url, 404))
        }
        let client = CatalogClient(transport: transport)
        do {
            _ = try await client.lookup(code: "0000000000000")
            XCTFail("missing")
        } catch CatalogFault.missing {
        }
        let count = await log.count
        XCTAssertEqual(count, 1)
    }

    func testTransientTransportRetriesOnce() async throws {
        let log = RequestLog()
        let transport = StubTransport { request in
            let n = await log.append(request.url)
            let url = try XCTUnwrap(request.url)
            if n == 1 {
                throw URLError(.timedOut)
            }
            return (CatalogFixtures.releaseJSON, CatalogFixtures.response(url, 200))
        }
        let client = CatalogClient(transport: transport)
        let hits = try await client.search(query: "coltrane", page: 1)
        XCTAssertEqual(hits.count, 1)
        let count = await log.count
        XCTAssertEqual(count, 2)
    }

    func testMalformedJSONIsHandled() async throws {
        let transport = StubTransport { request in
            let url = try XCTUnwrap(request.url)
            return (Data("not-json".utf8), CatalogFixtures.response(url, 200))
        }
        let client = CatalogClient(transport: transport)
        do {
            _ = try await client.search(query: "coltrane", page: 1)
            XCTFail("malformed")
        } catch CatalogFault.malformed {
        }
    }

    func testEmptyQueryDoesNotHitNetwork() async throws {
        let log = RequestLog()
        let transport = StubTransport { _ in
            await log.append(nil)
            throw URLError(.badURL)
        }
        let client = CatalogClient(transport: transport)
        let hits = try await client.search(query: "   ", page: 1)
        XCTAssertTrue(hits.isEmpty)
        let count = await log.count
        XCTAssertEqual(count, 0)
    }

    @MainActor
    func testSeekFallsBackToLocalShelf() async throws {
        let store = WallStore(vault: MemoryVault(), client: CatalogClient(transport: FailingTransport()))
        await store.installDemoCrate()
        let hits = try await store.seek("Coltrane")
        XCTAssertEqual(hits.first?.title, "Blue Train")
    }

    func testSleeveCodeExtractsRunsPadsUPCA() {
        XCTAssertEqual(SleeveCode.digitRuns(in: "abc12345678xyz"), ["12345678"])
        XCTAssertEqual(SleeveCode.normalize("123456789012"), "0123456789012")
        let fromURL = SleeveCode.candidates(from: "https://example.com/01/1234567890123")
        XCTAssertTrue(fromURL.contains("1234567890123"))
        let lucene = SleeveCode.lucene(for: "SHVL 804")
        XCTAssertEqual(lucene, "catno:\"SHVL 804\"")
        XCTAssertNil(SleeveCode.lucene(for: "  "))
    }
}

enum CatalogFixtures {
    static let releaseJSON = Data(
        """
        {"count":1,"offset":0,"releases":[{"id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","title":"Kind of Blue","barcode":"0074646352621","artist-credit":[{"name":"Miles Davis","artist":{"id":"x","name":"Miles Davis"}}],"label-info":[{"catalog-number":"CS 8163","label":{"name":"Columbia"}}],"release-group":{"primary-type":"Album"},"tags":[{"count":12,"name":"jazz"}]}]}
        """.utf8
    )

    static func response(_ url: URL, _ code: Int) -> URLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
    }
}

struct StubTransport: CatalogTransporting {
    let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}

actor RequestLog {
    private var urls: [URL?] = []

    @discardableResult
    func append(_ url: URL?) -> Int {
        urls.append(url)
        return urls.count
    }

    var count: Int { urls.count }
}
