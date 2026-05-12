import XCTest
@testable import Filmila

final class AuthServiceTests: XCTestCase {
    func testInvalidRoleThrowsViewerRoleRequired() {
        XCTAssertThrowsError(try AuthViewerRoleValidator.requireViewerRole("ADMIN")) { error in
            XCTAssertEqual(error as? AuthServiceError, .viewerRoleRequired)
        }
    }

    func testWhitespacePaddedViewerRoleAccepted() throws {
        XCTAssertNoThrow(try AuthViewerRoleValidator.requireViewerRole("  viewer  "))
    }
}
