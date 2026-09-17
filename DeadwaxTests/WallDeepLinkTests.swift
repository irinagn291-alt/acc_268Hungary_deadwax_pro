import XCTest
@testable import Deadwax

final class WallDeepLinkTests: XCTestCase {
    func testDeepLinkMapsDiscoverPressingHeardTaste() throws {
        XCTAssertEqual(
            WallDeepLink.parse(try XCTUnwrap(URL(string: "deadwax://discover"))),
            .segment(.discover, nil)
        )
        XCTAssertEqual(
            WallDeepLink.parse(try XCTUnwrap(URL(string: "deadwax://heard"))),
            .segment(.heard, nil)
        )
        XCTAssertEqual(
            WallDeepLink.parse(try XCTUnwrap(URL(string: "deadwax://taste"))),
            .segment(.taste, nil)
        )
        XCTAssertEqual(
            WallDeepLink.parse(try XCTUnwrap(URL(string: "deadwax://crate"))),
            .segment(.crate, nil)
        )
        let id = DemoIDs.kindOfBlue
        let pressing = try XCTUnwrap(URL(string: "deadwax://pressing/\(id.uuidString)"))
        XCTAssertEqual(WallDeepLink.parse(pressing), .segment(.discover, id))
        XCTAssertNil(WallDeepLink.parse(try XCTUnwrap(URL(string: "https://deadwax-wall.pro"))))
    }

    func testPendingRoundTripEncodesPressing() {
        let id = DemoIDs.homogenic
        let encoded = WallDeepLink.encode(.segment(.discover, id))
        XCTAssertEqual(WallDeepLink.decode(encoded), .segment(.discover, id))
        XCTAssertEqual(WallDeepLink.decode("heard"), .segment(.heard, nil))
    }
}
