import XCTest
@testable import Filmila

final class AuthServiceTests: XCTestCase {
    func testInvalidRoleThrowsViewerRoleRequired() {
        XCTAssertThrowsError(try AuthViewerRoleValidator.requireAllowedProfileRole("ADMIN")) { error in
            XCTAssertEqual(error as? AuthServiceError, .viewerRoleRequired)
        }
    }

    func testWhitespacePaddedViewerRoleAccepted() throws {
        XCTAssertNoThrow(try AuthViewerRoleValidator.requireAllowedProfileRole("  viewer  "))
    }

    func testFilmmakerRoleAccepted() throws {
        XCTAssertNoThrow(try AuthViewerRoleValidator.requireAllowedProfileRole("FILMMAKER"))
        XCTAssertNoThrow(try AuthViewerRoleValidator.requireAllowedProfileRole("  filmmaker  "))
    }
}
