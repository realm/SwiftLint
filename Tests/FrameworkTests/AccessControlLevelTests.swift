import SwiftLintCore
import XCTest

final class AccessControlLevelTests: SwiftLintTestCase {
    func testDescription() {
        XCTAssertEqual(AccessControlLevel.private.description, "private")
        XCTAssertEqual(AccessControlLevel.fileprivate.description, "fileprivate")
        XCTAssertEqual(AccessControlLevel.internal.description, "internal")
        XCTAssertEqual(AccessControlLevel.package.description, "package")
        XCTAssertEqual(AccessControlLevel.public.description, "public")
        XCTAssertEqual(AccessControlLevel.open.description, "open")
    }

    func testPriority() {
        XCTAssertLessThan(AccessControlLevel.private, .fileprivate)
        XCTAssertLessThan(AccessControlLevel.fileprivate, .internal)
        XCTAssertLessThan(AccessControlLevel.internal, .package)
        XCTAssertLessThan(AccessControlLevel.package, .public)
        XCTAssertLessThan(AccessControlLevel.public, .open)
    }
}
