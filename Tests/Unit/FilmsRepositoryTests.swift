import XCTest
@testable import Filmila

final class FilmsRepositoryTests: XCTestCase {
    func testFilterApprovedOnlyReturnsApprovedStatus() {
        let approved = Film(
            id: 1,
            title: "Ok",
            price: 0,
            status: .approved,
            viewCount: 0,
            createdAt: Date()
        )
        let pending = Film(
            id: 2,
            title: "Hold",
            price: 0,
            status: .pending,
            viewCount: 0,
            createdAt: Date()
        )
        let rejected = Film(
            id: 3,
            title: "No",
            price: 0,
            status: .rejected,
            viewCount: 0,
            createdAt: Date()
        )
        let mixed = [approved, pending, rejected]
        let filtered = FilmsApprovedCatalogPolicy.filterApprovedOnly(mixed)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, 1)
        XCTAssertTrue(filtered.allSatisfy { $0.status == .approved })
    }
}
